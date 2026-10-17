# Specification: Bottom-Left Clipboard History and Left Sidebar Notes Drawers

## 1. Overview
Add two independent productivity drawers to Caelestia Shell:
1. **Clipboard History Drawer (`modules/clipboard/`)**:
   - Location: Bottom-left screen corner (`anchors.left: parent.left`, `anchors.bottom: parent.bottom`).
   - Trigger: Hover at bottom-left corner (`x < 250`, `y > win.height - 5`) or keyboard shortcut.
   - Purpose: Fast search and click-to-copy from system clipboard history managed by `cliphist`.
2. **Notes & Snippets Sidebar Drawer (`modules/notes/`)**:
   - Location: Left screen edge (`anchors.left: parent.left`, `anchors.verticalCenter: parent.verticalCenter`).
   - Trigger: Hover along left screen edge (`x < 5`) or keyboard shortcut.
   - Purpose: Instant scratchpad and snippet manager persisting directly to `~/Documents/Obsidian/Drawer/*.md` with debounced auto-save.

## 2. Component Architecture

### 2.1 State Management (`components/ScreenState.qml`)
- Add drawer visibility properties:
  - `property bool clipboard: false`
  - `property bool notes: false`

### 2.2 Clipboard Drawer (`modules/clipboard/`)
- **`Wrapper.qml`**:
  - Anchors: `anchors.left: parent.left`, `anchors.bottom: parent.bottom`.
  - Dimensions: `implicitWidth: 380`, `implicitHeight: Math.min(520, parent.height * 0.6)`.
  - Margin slide animation: `anchors.bottomMargin: (-implicitHeight - 5) * offsetScale`.
  - Offset scale: `property real offsetScale: screenState.clipboard ? 0 : 1` with smooth animation curve.
  - Exposes `readonly property bool isFocused: (content.item as Content)?.isInputFocused ?? false`.
- **`Content.qml`**:
  - Container: `StyledRect` card with surface color (`m3surfaceContainer`) and rounded corners (`Tokens.rounding.large`).
  - Header:
    - Search field: `SearchBar` / `StyledTextField` with clear button.
    - Title: "Clipboard".
    - Action button: Clear / wipe all history (`cliphist wipe`).
  - List View:
    - Filtered list based on search query.
    - Each row displays: decoded text preview, clip ID, copy action, and individual delete action.
    - Keyboard navigation: Up/Down arrow selection, Enter to copy & close, Escape to close.
  - Actions:
    - On item clicked: Execute `echo '<id>' | cliphist decode | wl-copy` and set `screenState.clipboard = false`.
    - On delete clicked: Execute `echo '<id>' | cliphist delete` and remove item from list model.

### 2.3 Notes & Snippets Sidebar (`modules/notes/`)
- **`Wrapper.qml`**:
  - Anchors: `anchors.left: parent.left`, `anchors.verticalCenter: parent.verticalCenter`.
  - Dimensions: `implicitWidth: 440`, `implicitHeight: Math.min(parent.height - 40, 760)`.
  - Margin slide animation: `anchors.leftMargin: (-implicitWidth - 5) * offsetScale`.
  - Offset scale: `property real offsetScale: screenState.notes ? 0 : 1` with smooth animation curve.
  - Exposes `readonly property bool isFocused: (content.item as Content)?.isInputFocused ?? false`.
- **`Content.qml`**:
  - Container: `StyledRect` card with surface color (`m3surfaceContainer`) and rounded corners (`Tokens.rounding.large`).
  - Vault directory: `~/Documents/Obsidian/Drawer`.
  - Header:
    - Note selector / title picker: Dropdown or list row showing `.md` files.
    - Action: "New Note" (`+`) creating `Untitled-YYYYMMDD-HHMMSS.md` or prompting title.
    - Action: "Copy Snippet" copying entire note content to clipboard via `wl-copy`.
    - Action: "Delete Note" removing active `.md` file.
  - Editor Area:
    - Multi-line `StyledTextArea` with monospace or body font.
    - Auto-save timer: 500ms debounce triggering file write to the active `.md` file.
    - Focus tracker to pin drawer open while user is editing.

### 2.4 Drawers Container (`modules/drawers/Panels.qml`)
- Instantiate `Clipboard.Wrapper` anchored at bottom-left.
- Instantiate `Notes.Wrapper` anchored at left center.
- Expose aliases `readonly property alias clipboard: clipboard` and `readonly property alias notes: notes`.

### 2.5 Interaction & Gesture Handling (`modules/drawers/Interactions.qml`)
- **Hover Detection**:
  - `inBottomLeftPanel(panel, x, y)`: Returns true when cursor is within bottom-left corner (`x < 250` and `y > win.height - 10`).
  - `inLeftEdgePanel(panel, x, y)`: Returns true when cursor touches left edge (`x < 5` and within vertical range).
- **Pinning on Active Focus**:
  - While `panels.clipboard.isFocused` is true, avoid auto-closing clipboard drawer on cursor exit.
  - While `panels.notes.isFocused` is true, avoid auto-closing notes drawer on cursor exit.
- **Mutual Exclusivity**:
  - Opening `clipboard` forces `notes`, `dashboard`, `launcher` to close.
  - Opening `notes` forces `clipboard`, `dashboard`, `launcher` to close.
  - Opening `dashboard` or `launcher` forces `clipboard` and `notes` to close.
- **Escape / Outside Click**:
  - Clicking on backdrop or pressing Escape dismisses active drawer.

### 2.6 Wayland Input Region Masking (`modules/drawers/Regions.qml`)
- Define `R` component instance for clipboard:
  - `panel: root.panels.clipboard`
  - `x: 0`
  - `y: root.win.height - height`
  - `height: panel.height * (1 - panel.offsetScale) + root.borderThickness`
  - `width: panel.width * (1 - panel.offsetScale) + root.borderThickness`
- Define `R` component instance for notes:
  - `panel: root.panels.notes`
  - `x: 0`
  - `y: panel.y`
  - `width: panel.width * (1 - panel.offsetScale) + root.borderThickness`
  - `height: panel.height`

## 3. Verification & Acceptance Criteria
1. **Directory Initialized**: `~/Documents/Obsidian/Drawer/` is automatically created on startup if absent.
2. **Clipboard History**:
   - Hovering at bottom-left corner slides up clipboard drawer.
   - History items from `cliphist list` populate the list view.
   - Searching filters entries instantly.
   - Clicking an item copies it to system clipboard via `wl-copy` and dismisses the drawer.
3. **Notes / Snippets**:
   - Hovering at left edge slides out the notes drawer.
   - Notes are read from and written to `~/Documents/Obsidian/Drawer/*.md`.
   - Editing note persists content automatically within 500ms debounce.
   - "Copy Snippet" copies content directly to system clipboard.
4. **Input Mask & Pass-Through**:
   - Clicks inside open clipboard and notes drawers register immediately (text editing, button clicks, scrolling).
   - Area outside open drawers passes through seamlessly to underlying desktop windows.
5. **No Regressions**:
   - Bottom-center dashboard, bottom-center launcher, topbar, and right sidebar continue functioning without gesture conflicts.
