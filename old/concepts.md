# Earl
Earl is a window manager for macOS built in Odin.

Earl has three concepts: sessions, layers and layouts.


## Layers
There are two types of layers: split and slot. (There may be more in the future)

Every time you open a window/app it creates a new space where the window belongs to called a layer. You can compose layers to create a split layer.

### Slot
The simplest layer type is a slot. A slot is a full screen window.

### Split
A split is a tree based organisation of windows typical to what you would find in a tiling window manager. You can split windows horizontally or vertically. A split tree consists of node indicating what type of split they are and the left, and right leaves. A leaf is always a window (represented by a WindowID). A window can only appear once per split

## Layout
A layout is a collection of Layers with a layer per active screen. A window can only appear once per layout.

Updating a layer used in a layout updates that layout.

This enables workflows that allow the definition of layouts as combinations of layers, i.e.
  - browser and terminal together for debugging, 
  - terminal itself for zero distraction work, with the browser on a second monitor,
  - any other combinations that help your workflow.

## Sessions
Sessions are most similar to tmux sessions. The idea here is a session is a collection of layers and layouts. This can be used for organisation.

>Opening a window in a session that is not active will switch spaces.


# TODO
- [x] create split
- [x] update split
- [ ] implement window lifecycle callback: onOpened, onClosed, onResized
- [ ] implement hotkeys
- [x] launch init session manager and put every window on a layer
- [ ] go to layout - via keyboard
- [ ] test updating splits
- [ ] fork split
- [ ] change split node type
- [ ] create layout
- [ ] update layout
- [ ] fork layout
- [ ] save active screen as a layout
- [ ] implement buffer to easily swap back and forth between recently used layers
- [ ] traverse a split using a keyboard
- [ ] KDL implementation as the config language
- [ ] Allow layouts to be defined in config
- [ ] allow resizing split children
- [ ] CLI
