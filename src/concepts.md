# Earl

## Concepts

1. Dynamic virtual workspaces (i.e a window can be present in one or more workspaces at a time.)
2. Tree based tiling window manager

### Workspaces

Workspaces are implemented using a tree based concepts where the leaves of the tree are the windows of OSX. These are not unique to workspaces. 
This enables workflows that allow the definition of workspaces as combinations of windows and workflows, i.e.
  - browser and terminal together for debugging, 
  - terminal itself for zero distraction work, with the browser on a second monitor,
  - any other combinations that help your workflow.

Workspaces nodes dictate the way they 'render', this allows for different to combine together for the classic tiling window manager feel (Vertical, Horizontal etc). 
Accordion nodes are nodes in which there can be multiple windows managed in an accordion you can navigate through. Accordion nodes can only have window leaves as its children

Workspaces can be manually tiled or dynamically tiled.
Manual Tiling:
- workspaces can be opt in for tiling. 
- all windows are then 'floating' and Earl doesn't care about their position within the workspace
- this is represented as a single root node in the tree with type "float"
- this is not limited to just the root node and can be used in combination with other node types - together this can mean portions of the screen are tiled in a certain manner and others are tiled freely - "floating".


Dynamic Tiling:
- TBD


### Commands


## Config Driven:
- dotfile compatible
- set hotkeys for workspaces
- 


## Implementation Details

1. Tile Package
  a. AX  package
   i. CF-Extensions package
   
2. Workspace package
  a. Tree
  b. Workspace-Controller


### Workspace
 - move_node_to_workspace
 - copy_node_to_workspace
 - set_active_workspace

### Tile
- tile_window
 -- tiles window in a direction, 

- set_node_type
- swap_nodes

- focus_window

- cycle_children_focus

- set_tiling_mode
