# Clipboard and Notes Drawers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a bottom-left Clipboard History drawer (via `cliphist` and `wl-copy`) and a left sidebar Notes & Snippets drawer (persisting Markdown files to `~/Documents/Obsidian/Drawer/`) with hover peeking, input-focus pinning, mutual exclusivity, and Wayland region masking.

**Architecture:** Two isolated drawer modules (`modules/clipboard` and `modules/notes`) managed by `ScreenState.qml` and `Panels.qml`. `Interactions.qml` handles edge hover detection and active focus pinning, while `Regions.qml` handles Wayland input region subtraction for reliable click interaction and desktop pass-through.

**Tech Stack:** QML (QtQuick, Quickshell, Caelestia QML components), `cliphist`, `wl-clipboard` (`wl-copy`), local file I/O.

**Spec:** `docs/superpowers/specs/2026-10-17-clipboard-and-notes-drawers-design.md`

## Global Constraints
- `~/Documents/Obsidian/Drawer` is the designated directory for notes and snippets.
- `cliphist list` and `cliphist decode | wl-copy` are used for clipboard operations.
- All drawer containers adhere to Caelestia design tokens (`Tokens.rounding.large`, `Colours.tPalette.m3surfaceContainer`, `Anim.DefaultEffects`).
- Custom user additions in `~/.config/quickshell/caelestia` (e.g. `AgentTab.qml`, `agent/`) must never be modified or overwritten during file synchronization.
- Syntax must pass `/usr/lib/qt6/bin/qmllint --import disable`.

## Review Focus
- Empty clipboard: `cliphist list` produces empty or error output -> display polite empty state without QML crash.
- Obsidian directory missing: `~/Documents/Obsidian/Drawer` does not exist on start -> auto-created via `mkdir -p` before reading/writing.
- Binary clipboard data: `cliphist` item contains binary image tag `[[ binary data ... ]]` -> display readable label and prevent text corruption.
- Debounced note auto-save: typing rapidly should not overwhelm disk writes or cause file locks -> debounce save by 500ms.
- Input focus pinning: moving mouse away while searching clipboard or editing note should not close the drawer.

---

### Task 1: Add Drawer State Properties to ScreenState

**Files:**
- Modify: `components/ScreenState.qml:7-15`

**Interfaces:**
- Produces: `ScreenState.clipboard: bool`, `ScreenState.notes: bool`

- [ ] **Step 1: Check existing ScreenState properties**

Read `components/ScreenState.qml` and confirm drawer visibilities list.

- [ ] **Step 2: Add `clipboard` and `notes` properties**

Add `property bool clipboard: false` and `property bool notes: false` under `// Drawer visibilities`.

- [ ] **Step 3: Verify syntax**

Run: `/usr/lib/qt6/bin/qmllint --import disable components/ScreenState.qml`
Expected: PASS with no syntax errors.

- [ ] **Step 4: Commit**

```bash
git add components/ScreenState.qml
git commit -m "feat(state): add clipboard and notes visibility properties to ScreenState"
```

---

### Task 2: Implement Clipboard History Drawer Module

**Files:**
- Create: `modules/clipboard/Wrapper.qml`
- Create: `modules/clipboard/Content.qml`

**Interfaces:**
- Consumes: `ScreenState.clipboard`, `cliphist list`, `cliphist decode`, `wl-copy`
- Produces: `modules/clipboard/Wrapper.qml` with `property real offsetScale`, `readonly property bool isFocused`

- [ ] **Step 1: Create `modules/clipboard/Content.qml`**

Implement clipboard content card:
- Header with title "Clipboard", clear button (`cliphist wipe`), and count indicator.
- `SearchBar` / search input filtering items dynamically.
- `ListView` displaying clipboard entries from `cliphist list` via `Process`.
- Row click copies decoded item to clipboard (`cliphist decode | wl-copy`) and closes drawer (`screenState.clipboard = false`).
- Row delete button removes item (`cliphist delete`).
- Track `readonly property bool isInputFocused: searchBar.activeFocus`.

- [ ] **Step 2: Create `modules/clipboard/Wrapper.qml`**

Implement sliding drawer wrapper:
- Anchors: `anchors.left: parent.left`, `anchors.bottom: parent.bottom`.
- Slide offset: `anchors.bottomMargin: (-implicitHeight - 5) * offsetScale`.
- `offsetScale`: `screenState.clipboard ? 0 : 1` with `Anim { type: Anim.DefaultSpatial }`.
- Dimensions: `implicitWidth: 380`, `implicitHeight: Math.min(520, parent.height * 0.6)`.
- Expose `readonly property bool isFocused: (content.item as Content)?.isInputFocused ?? false`.

- [ ] **Step 3: Verify syntax**

Run: `/usr/lib/qt6/bin/qmllint --import disable modules/clipboard/Content.qml modules/clipboard/Wrapper.qml`
Expected: PASS with no syntax errors.

- [ ] **Step 4: Commit**

```bash
git add modules/clipboard/Content.qml modules/clipboard/Wrapper.qml
git commit -m "feat(clipboard): create bottom-left clipboard history drawer module"
```

---

### Task 3: Implement Notes & Snippets Drawer Module

**Files:**
- Create: `modules/notes/Wrapper.qml`
- Create: `modules/notes/Content.qml`

**Interfaces:**
- Consumes: `ScreenState.notes`, `~/Documents/Obsidian/Drawer/*.md`
- Produces: `modules/notes/Wrapper.qml` with `property real offsetScale`, `readonly property bool isFocused`

- [ ] **Step 1: Create `modules/notes/Content.qml`**

Implement notes & snippets sidebar content:
- Vault initialization: check and create `~/Documents/Obsidian/Drawer` on load.
- File listing: list `*.md` files in `~/Documents/Obsidian/Drawer`.
- Note selector header: list of note pills / tabs, "New Note" (`+`) button, "Delete Note" button.
- "Copy Snippet" button: reads current note text and executes `wl-copy`.
- Multi-line `TextArea` / `StyledTextArea` for editing active note.
- Debounced auto-save timer (500ms): writes updated buffer to the active file.
- Track `readonly property bool isInputFocused: editor.activeFocus`.

- [ ] **Step 2: Create `modules/notes/Wrapper.qml`**

Implement sliding sidebar wrapper:
- Anchors: `anchors.left: parent.left`, `anchors.verticalCenter: parent.verticalCenter`.
- Slide offset: `anchors.leftMargin: (-implicitWidth - 5) * offsetScale`.
- `offsetScale`: `screenState.notes ? 0 : 1` with `Anim { type: Anim.DefaultSpatial }`.
- Dimensions: `implicitWidth: 440`, `implicitHeight: Math.min(parent.height - 40, 760)`.
- Expose `readonly property bool isFocused: (content.item as Content)?.isInputFocused ?? false`.

- [ ] **Step 3: Verify syntax**

Run: `/usr/lib/qt6/bin/qmllint --import disable modules/notes/Content.qml modules/notes/Wrapper.qml`
Expected: PASS with no syntax errors.

- [ ] **Step 4: Commit**

```bash
git add modules/notes/Content.qml modules/notes/Wrapper.qml
git commit -m "feat(notes): create left sidebar notes and snippets drawer module"
```

---

### Task 4: Integrate Drawers into Panels, Interactions, and Regions

**Files:**
- Modify: `modules/drawers/Panels.qml`
- Modify: `modules/drawers/Interactions.qml`
- Modify: `modules/drawers/Regions.qml`

**Interfaces:**
- Consumes: `Clipboard.Wrapper`, `Notes.Wrapper`, `ScreenState`
- Produces: Interactive hover detection, input masking, and mutual exclusivity for both drawers

- [ ] **Step 1: Update `Panels.qml`**

- Import `qs.modules.clipboard as Clipboard` and `qs.modules.notes as Notes`.
- Instantiate `Clipboard.Wrapper { id: clipboard; screenState: root.screenState }`.
- Instantiate `Notes.Wrapper { id: notes; screenState: root.screenState }`.
- Expose aliases: `readonly property alias clipboard: clipboard`, `readonly property alias notes: notes`.

- [ ] **Step 2: Update `Interactions.qml`**

- Add helper functions `inBottomLeftPanel(panel, x, y)` and `inLeftEdgePanel(panel, x, y)`.
- Hover triggers:
  - Bottom-left hover (`x < 250 && y > win.height - 5`) reveals `screenState.clipboard`.
  - Left edge hover (`x < 5 && y > 100 && y < win.height - 100`) reveals `screenState.notes`.
- Hover departure:
  - Close `clipboard` only if `!panels.clipboard.isFocused`.
  - Close `notes` only if `!panels.notes.isFocused`.
- Mutual exclusivity:
  - Opening `clipboard` closes `notes`, `dashboard`, `launcher`.
  - Opening `notes` closes `clipboard`, `dashboard`, `launcher`.
  - Opening `dashboard` closes `clipboard`, `notes`.

- [ ] **Step 3: Update `Regions.qml`**

- Add input region subtraction `R` for `clipboard`:
  - `panel: root.panels.clipboard`
  - `x: 0`
  - `y: root.win.height - height`
  - `height: panel.height * (1 - root.panels.clipboard.offsetScale) + root.borderThickness`
  - `width: panel.width * (1 - root.panels.clipboard.offsetScale) + root.borderThickness`
- Add input region subtraction `R` for `notes`:
  - `panel: root.panels.notes`
  - `x: 0`
  - `y: panel.y + root.bar.implicitHeight`
  - `width: panel.width * (1 - root.panels.notes.offsetScale) + root.borderThickness`
  - `height: panel.height`

- [ ] **Step 4: Verify syntax**

Run: `/usr/lib/qt6/bin/qmllint --import disable modules/drawers/Panels.qml modules/drawers/Interactions.qml modules/drawers/Regions.qml`
Expected: PASS with no syntax errors.

- [ ] **Step 5: Commit**

```bash
git add modules/drawers/Panels.qml modules/drawers/Interactions.qml modules/drawers/Regions.qml
git commit -m "feat(drawers): wire clipboard and notes into panels, interactions, and regions"
```

---

### Task 5: Live Sync, Testing, and Verification

**Files:**
- Sync to: `~/.config/quickshell/caelestia/`

- [ ] **Step 1: Sync changed files while preserving custom files**

Copy modified files to `~/.config/quickshell/caelestia/`, ensuring `AgentTab.qml` and `agent/` remain intact.

- [ ] **Step 2: Restart shell**

Execute `/home/zulfi/switch-to-caelestia.sh` and verify clean launch in logs.

- [ ] **Step 3: Test Clipboard Drawer**

- Move mouse to bottom-left corner: verify drawer slides up smoothly.
- Test search filtering with query.
- Click an entry: verify it copies to clipboard and closes drawer.
- Verify pinning while search bar is focused.

- [ ] **Step 4: Test Notes Drawer**

- Move mouse to left edge: verify notes sidebar slides out.
- Create new note, type text, confirm auto-save creates `.md` in `~/Documents/Obsidian/Drawer/`.
- Click "Copy Snippet" and verify clipboard content (`wl-paste`).
- Verify pinning while editor is focused.
