# macOS nvim-style Window Manager — Idea Review (Chat Transcript)

Date: 2026-07-11

---

## User

i'm working on a seperate project idea to this. which is basically taking the nvim tabs, buffers, windows and bringing that to macos. so every window you open is like a buffer in nvim you can compose multiple into split windows etc. these are global, so you can another tab where you re-use the same window in some other combination. currently i'm thinking that this could be implemented by having an ipx / posix socket that connects to a launch daemon (or agent) for the app, and the app itself just exposes a cli for usage, there are global keybinds as well. for the windows i'm thinking we use the skylight api to know everything about the monitor setup and when a window is opened/closed (there are some problems with native tabs, [since skylight seems them as windows] but i've come up with a hueristic for that, that kinda works), use the ax api for determining if things are moved by mouse and forbidding that maybe (or reacting & updating properly). we don't use native spaces since thats a whole kettle of fish thats super difficult on macos, but instead just the one space. And so we have an internal event stream so the daemon can react to the app events as well as system events, without blocking. I'm still trying to figure out multi monitor, do we have the ability to have tabs that compose against monitors so you can change to a tab and have all displays change or is each display a seperate tab and you do it that way. Please review this idea, point out any flaws in the architecture and idea.

## Claude

This is a solid instinct for a project — the "windows are global buffers, layouts are cheap views over them" model is genuinely the thing missing from macOS tiling WMs (yabai, AeroSpace, Amethyst all treat windows as owned by a workspace). But there are a few places where the nvim analogy collides with macOS reality, and a couple of architectural details that are wrong or will bite. Here's the review.

### The conceptual flaw: a macOS window can only exist in one place

In nvim, the buffer/window split works because a buffer is *data* and a window is a *view* — you can show the same buffer in two splits simultaneously, even in the same tab. A macOS window is not data; it's a single surface owned by another process. So:

- **Within a tab**: you can never show the same window in two splits. Fine, just disallow it.
- **Across tabs**: reuse works only because one tab is visible at a time. But it creates a nvim-like edge case you must design for: closing/killing a window that's referenced by three tabs (nvim answer: the slot collapses or shows the next buffer — you need an equivalent).
- **The killer edge case**: if a window lives in tab 2 and the user Cmd-Tabs to that app, macOS will raise and focus that window *on your one space*, violating your current tab's layout. You can't prevent this. The right move is to embrace it like nvim's `switchbuf`: watch `NSWorkspace` activation / AX focus events, and when a "hidden" window gains focus, auto-switch to (or summon it into) the tab that owns it. If you don't handle this, the model falls apart the first time the user clicks a Dock icon or a notification.

### Tab switching without Spaces: know what you're signing up for

You're right to avoid Spaces (managing them requires private `SLSSpace*` calls that need SIP partially disabled, à la yabai's scripting addition). But then "switching tabs" means making windows invisible without Spaces, and macOS gives you no clean primitive:

- You can't move a window fully off-screen — the WindowServer clamps windows to remain partially on-screen. AeroSpace's workaround is moving inactive-workspace windows to the very corner so a few pixels peek out. It works, but accept the costs up front: Mission Control and Cmd-Tab show *everything* from all tabs, screenshots/screen-sharing show corner clutter, and Stage Manager fights you outright.
- Minimizing via AX is animated and slow; `AXHidden` (hiding the whole app) is wrong granularity when an app has windows in multiple tabs.

This is the single biggest UX compromise in the whole design, and it's forced by the SIP decision, so make that decision explicitly and early: **SIP-friendly (AeroSpace path)** — corner-stash hack, AX-only writes, works for everyone; or **SIP-disabled (yabai path)** — real window warping and per-space control, tiny audience. Everything downstream (tab mechanics, animations, multi-monitor) depends on this choice. I'd go SIP-friendly; requiring SIP off kills adoption.

### Architecture corrections

- **LaunchAgent, not LaunchDaemon — this one's non-negotiable.** A LaunchDaemon runs outside the user's GUI session and cannot connect to the WindowServer or use AX. It must be a LaunchAgent in the Aqua session. You had "(or agent)" in parentheses; it's the only option.
- **Put all logic in the agent; the CLI is a dumb socket client.** Your phrasing ("the app itself just exposes a CLI") is ambiguous — TCC permissions (Accessibility) attach to the process doing the AX calls, so you want exactly one long-lived, code-signed binary holding those grants. Sign with a stable identity or you'll re-grant Accessibility on every rebuild.
- **Unix socket + CLI** is the proven yabai/AeroSpace shape. Version the protocol from day one; make queries (`list-windows`, `query tab 3`) first-class so scripting works — that's half the value of this model.
- **Global keybinds**: prefer Carbon `RegisterEventHotKey` (no permissions, no tap-timeout issues) over a CGEventTap unless you need modal keymaps/leader keys. If you do use an event tap, handle `kCGEventTapDisabledByTimeout` — the system silently disables slow taps, and every tap-based hotkey tool has been bitten by this.

### The AX layer: latency, hangs, and feedback loops

Three things people always underestimate:

1. **AX calls are synchronous IPC into the target app.** A beachballing app blocks your call — and if you're making AX calls on the same thread that processes your event stream, one hung app freezes the whole WM. Set `AXUIElementSetMessagingTimeout` per app, and serialize AX work per-app on worker queues, never on the event loop. Your "internal event stream so the daemon doesn't block" is the right instinct; this is the specific place it matters.
2. **Your own writes echo back as events.** Every `AXPosition`/`AXSize` set fires moved/resized notifications identical to user-initiated ones. Without tagging self-inflicted changes (expected-frame matching or a generation counter), you'll build feedback loops that re-tile forever.
3. **Don't forbid mouse drags — react and re-tile.** You cannot cancel a drag via AX; "forbidding" means snapping the window back afterward, which reads as jank/fighting the user. Every successful tiling WM went with: drag ends → figure out which slot it landed on → swap/insert and re-tile. Also note `kAXWindowMoved` generally fires at drag *end*; to react mid-drag you need to correlate with global mouse events.

Also plan a window-rules/exclusion system from week one, not as a v2 feature: sheets, palettes, dialogs, PiP windows, apps with min-size or grid-increment constraints (Terminal), and native fullscreen (which creates its own Space, conflicting with your single-space decision) all need to be classified as "unmanaged." Every tiling WM ends up here; the ones that ship without it feel broken immediately.

### State model: you don't own the truth

Unlike nvim, where the editor owns its buffers, your daemon's model is a *cache* of state another process mutates freely — apps open windows on their own schedule, restore sessions at launch, close windows without asking. Design for reconciliation, not command-and-control: on every event (and on daemon restart), diff observed reality against the model and adopt/evict. Two specifics:

- On restart, adopt existing windows into a default tab (like nvim inheriting args as buffers) rather than requiring a clean slate.
- `CGWindowID` is only stable for the window's lifetime. If you want layouts to persist across app relaunches, you need heuristic re-matching (bundle ID + title + frame), and it will be fuzzy. Decide whether persistence is in scope; it's a big cost.

On SkyLight generally: read-only use (window list, display config, connection notifications) is the sane part, but it's private API with no stability guarantee — yabai breaks on most major macOS releases. Isolate it behind one module with per-OS-version shims, and have a CGWindowList-polling fallback. Your native-tabs heuristic belongs in that same quarantine zone; expect to re-derive it each macOS release.

### Multi-monitor: steal XMonad's answer, not i3's

This is where the nvim analogy simply runs out — nvim has no concept of multiple viewports into the session, which is why the question feels hard. The two options you listed have a known synthesis, and it fits your global-buffer philosophy perfectly:

**Tabs are global objects; each monitor is a viewport showing one tab** (this is XMonad/AeroSpace semantics, vs. i3 where a workspace is owned by a monitor). So:

- `focus tab 3` on monitor A shows tab 3 there; if tab 3 was showing on monitor B, they swap (or it moves — pick one, XMonad supports both as "greedy" vs non-greedy view).
- Per-monitor independent switching falls out for free — each display changes tabs on its own.
- Your "all displays change at once" use case becomes a thin layer on top: named *tab groups/profiles* ("work" = tab 1 on left, tab 4 on right) that set all viewports in one command. You get both behaviors without committing the model to either.

A tab spanning two physical monitors as one layout tree sounds appealing but I'd avoid it: mixed DPI, monitor hot-plug, and the gap/misalignment between displays make cross-display splits messy, and tab-per-viewport plus profiles covers the real use case.

Multi-monitor traps to note regardless: `CGDirectDisplayID` is not stable across reconnects (key monitors by display UUID); CoreGraphics uses top-left-origin global coordinates while Cocoa uses bottom-left with a flipped Y — mixing them is the classic off-by-one-screen bug; and hot-plug events arrive as a storm of reconfiguration callbacks you should debounce before re-tiling.

### Verdict

The architecture is fundamentally sound — it's the AeroSpace shape (LaunchAgent, AX writes, SkyLight reads, socket CLI, SIP-friendly) with a genuinely better data model on top. The three things I'd resolve before writing much code: (1) the Cmd-Tab/focus-steal story, because it defines whether tabs feel robust or leaky; (2) the SIP decision, because it locks in the tab-switching mechanism; (3) the reconciliation-based state model, because retrofitting it onto a command-and-control design is painful. The multi-monitor question I'd consider answered: global tabs, monitor-as-viewport, profiles for synchronized switching.

