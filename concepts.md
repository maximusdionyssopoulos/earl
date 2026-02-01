# Earl

Earl is a session manager built to bring tmux like workflows to the entire macOS. 

You can create sessions, to organise selections of spaces. A space is a layout of one or multiple windows*, within a session a window can appear in multiple spaces but never twice in the same space. A window can even appear across sessions if you'd like. 

Every time you open a window/app it creates a new space where the window belongs to called a layer. You can then copy that layer to another space to create a split viewed space.

Opening a window in a space that is not active will switch spaces.

### Workspaces

Workspaces are implemented using a tree based concepts where the leaves of the tree are the windows of OSX. These are not unique to workspaces. 
This enables workflows that allow the definition of workspaces as combinations of windows and workflows, i.e.
  - browser and terminal together for debugging, 
  - terminal itself for zero distraction work, with the browser on a second monitor,
  - any other combinations that help your workflow.

### Commands


## Config Driven:
- dotfile compatible
- set hotkeys for workspaces (hotkeys: https://github.com/asmvik/skhd)

Maybe:
- Accordion nodes are nodes in which there can be multiple windows managed in an accordion you can navigate through. Accordion nodes can only have window leaves as its children

