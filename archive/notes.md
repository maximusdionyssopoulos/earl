---

## User (via /fork)

i was interested in putting this as apart of a another macos app that would bring the nvim cmd window, ability to run cmds, and plugin system to macos. so this would be a plugin and then you could have things like fuzzy finding files and apps, so similar to raycast and tuna (macos app). i guess this could also be similar to emacs (i was thinking of making the config lang a lisp). My concerns are that i'd either have to expose all macos apis to the lisp so you could build interesting plugins, somehow allow native code (C/ obj-c) so the plugin could have the system apis it needs. Another concern was what the app would actually be used for as it seems very small (i guess thats my imagination as the app is the infra and plugins are whatever you want), because emacs/nvim atleast have the editor core and the customisability just extends that.

## Claude (fork result)

### Your second concern is the real one, and the fix is to invert the layering

Emacs isn't great because it's "customizable" — it's great because it has a universal substrate (the text buffer) that every plugin reads and writes, which is why plugins compose instead of being a bag of disconnected commands. A cmd window + Lisp + plugin system with no substrate is Raycast with a Lisp, and Raycast already exists with a huge catalog.

But you already have a substrate — it's the other half of your idea. Don't make the WM a plugin of the shell; **make the WM's global window/buffer registry the shell's core.** "Everything is a buffer" becomes "everything is a window": real app windows and app-drawn virtual surfaces (fuzzy-finder pickers, dashboards, the cmd window itself) all live in one registry, all addressable, all composable into splits and tabs. A fuzzy finder then isn't a floating palette bolted on — it's a picker over registry objects whose result focuses/summons/splits. That's the answer to "what is this app for": nvim's core is text buffers, yours is window surfaces. The desktop is the document.

This also answers "seems small" from the market side: the launcher space is saturated (Raycast, Alfred, LaunchBar), but nobody has the global-buffer WM. The WM is the differentiated wedge and the killer app; the plugin platform is the growth path that emerges from it. Platforms shipped before their first killer app die of emptiness.

### API exposure is a solved problem — don't expose all of macOS

Hammerspoon is your closest prior art and a decade of proof: Lua config with curated capability modules (`hs.window`, `hs.hotkey`, `hs.application`, `hs.fs`, `hs.http`…). A curated stdlib of ~10 modules covers 95% of plugins, and half of them (windows, apps, displays, events) you're building for the WM anyway. For the rest, three tiers:

1. **In-process Lisp** for config and most plugins. On the Lisp choice: Fennel-on-LuaJIT (lisp syntax, Hammerspoon-adjacent mindshare, easy C interop), Janet (tiny, built for embedding, good FFI), or Steel if the host is Rust. Writing your own Lisp will cost you a year — resist.
2. **Native modules via a narrow, stable C ABI** — the Emacs 25 dynamic-modules model. Plugins needing Metal or AVFoundation ship a .dylib against your small header; you never promise the whole OS surface. One macOS gotcha to decide early: loading third-party dylibs into a notarized hardened-runtime app requires the `disable-library-validation` entitlement, so native plugins constrain your code-signing story from day one.
3. **Out-of-process plugins in any language, for free** — your daemon already has a socket and event stream, so Neovim's RPC model falls out of the existing architecture. Crash-isolated, no signing issues; only too slow for tight UI loops.

### Sequencing

Build the WM with the Lisp as its *config language* from day one (like `init.lua`), with commands and the cmd window as the interface to it. The plugin system grows out of the config language once real users want to share config — the exact nvim/Hammerspoon evolutionary path — rather than being speculative infrastructure built first.

One warning: this is two hard projects, and the WM alone (AX edge cases, native tabs, multi-monitor) is a year of nights and weekends. The substrate framing is what lets you ship the WM standalone while still building the big idea the whole time.
