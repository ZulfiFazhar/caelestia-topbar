# Caelestia Topbar and Left Dashboard Transformation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform Caelestia Shell layout from vertical left-bar + top-dashboard to horizontal top-bar + left-dashboard drawer.

**Architecture:** Rotate Bar and BarWrapper into a horizontal `RowLayout` anchored to the top of the screen; re-anchor Dashboard to slide out from the left screen edge; update layer-shell exclusions, gesture/hover interaction logic, input region masks, and blob background offsets to match the new coordinates.

**Tech Stack:** QML (QtQuick / QtQuick.Layouts / Quickshell), Wayland layer-shell protocol, C++ (Caelestia plugin tokens/config).

**Spec:** `docs/superpowers/specs/2026-10-16-topbar-and-left-dashboard-design.md`

## Global Constraints

- Retain exact styling, border radius, tokens, and visual effects of Caelestia Shell.
- Do not break existing features: system tray, active window title popouts, workspaces, volume/brightness wheel scrolling.
- QML code must compile/load without syntax errors under `quickshell`.

## Review Focus

1. **Popouts Placement**: Tray and status menus must open directly below the topbar entry, clamped within screen boundaries.
2. **Wheel Scrolling on Topbar**: Volume, brightness, and workspace switching via mouse wheel must map correctly on the top horizontal bar.
3. **Left Dashboard Gesture**: Hovering or dragging from the left screen edge must cleanly reveal the dashboard and close when dragging left or clicking outside.
4. **Window Exclusion Zone**: Hyprland windows must clear the topbar space at the top of the monitor without overlap.
5. **Fullscreen Behavior**: Entering fullscreen must collapse the topbar and hide any open drawers/popouts.

---

### Task 1: Bar & BarWrapper Horizontal Orientation

**Files:**
- Modify: `modules/bar/Bar.qml`
- Modify: `modules/bar/BarWrapper.qml`

**Interfaces:**
- Consumes: `Tokens.sizes.bar.innerWidth`, `Tokens.padding`, `Config.bar`
- Produces: `BarWrapper` with horizontal anchors (`top`, `left`, `right`), `implicitHeight`, and `exclusiveZone`

- [ ] **Step 1: Check existing BarWrapper syntax and layout dependencies**
Run: `qmllint modules/bar/Bar.qml modules/bar/BarWrapper.qml`

- [ ] **Step 2: Update `modules/bar/Bar.qml` to `RowLayout`**
Convert `ColumnLayout` to `RowLayout`. Set `spacing: Tokens.spacing.medium`.
In `Repeater` delegate for `spacer`, change `Layout.fillHeight: true` to `Layout.fillWidth: true`.
Update `checkPopout(x)` to find child using `childAt(x, height / 2)` and set `popouts.currentCenter` to `icon.mapToItem(root, icon.implicitWidth / 2, 0).x`.
Update `handleWheel` to route wheel events across the horizontal bar.

- [ ] **Step 3: Update `modules/bar/BarWrapper.qml` for top placement**
Change dimension from width-based to height-based:
- `readonly property int contentHeight: Tokens.sizes.bar.innerWidth + padding * 2`
- `readonly property int exclusiveZone: !disabled && (Config.bar.persistent || screenState.bar) ? contentHeight : Config.border.thickness`
- `implicitHeight: fullscreen ? 0 : Config.border.thickness`
- `anchors.top: parent.top`, `anchors.left: parent.left`, `anchors.right: parent.right`
- State `visible` sets `root.implicitHeight: root.contentHeight`.
- Loader anchors: `anchors.left: parent.left`, `anchors.right: parent.right`, `anchors.top: parent.top`, with `height: root.contentHeight`.

- [ ] **Step 4: Verify QML syntax of Bar components**
Run: `qmllint modules/bar/Bar.qml modules/bar/BarWrapper.qml`
Expected: PASS (or no new structural errors)

- [ ] **Step 5: Commit changes**
```bash
git add modules/bar/Bar.qml modules/bar/BarWrapper.qml
git commit -m "feat(bar): convert Bar and BarWrapper to horizontal topbar"
```

---

### Task 2: Popouts Alignment for Topbar

**Files:**
- Modify: `modules/bar/popouts/ClipWrapper.qml`
- Modify: `modules/bar/popouts/Wrapper.qml`

**Interfaces:**
- Consumes: `popouts.currentCenter` (X-coordinate from Task 1)
- Produces: Popouts positioned below the topbar and centered on the clicked icon

- [ ] **Step 1: Inspect `ClipWrapper.qml` coordinates**
Read `modules/bar/popouts/ClipWrapper.qml` positioning logic.

- [ ] **Step 2: Update `ClipWrapper.qml` positioning**
Align X to `currentCenter`:
- `x: {`
  `if (content.isDetached) return (parent.width - content.nonAnimWidth) / 2;`
  `const off = content.currentCenter - content.nonAnimWidth / 2;`
  `return Math.max(0, Math.min(off, parent.width - content.nonAnimWidth));`
  `}`
Align Y below topbar:
- `y: content.isDetached ? (parent.height - content.nonAnimHeight) / 2 : 0`
Update `offsetScale` and animation direction for vertical expansion below topbar.

- [ ] **Step 3: Verify syntax**
Run: `qmllint modules/bar/popouts/ClipWrapper.qml modules/bar/popouts/Wrapper.qml`
Expected: PASS

- [ ] **Step 4: Commit changes**
```bash
git add modules/bar/popouts/ClipWrapper.qml modules/bar/popouts/Wrapper.qml
git commit -m "feat(popouts): align popouts horizontally below topbar entries"
```

---

### Task 3: Left Dashboard Drawer Relocation

**Files:**
- Modify: `modules/dashboard/Wrapper.qml`
- Modify: `modules/drawers/Panels.qml`

**Interfaces:**
- Consumes: `screenState.dashboard`, `Config.dashboard`
- Produces: Dashboard sliding in from left edge

- [ ] **Step 1: Update `modules/dashboard/Wrapper.qml` for left sliding**
Change `anchors.topMargin` to `anchors.leftMargin`:
- `anchors.leftMargin: (-implicitWidth - 5) * offsetScale`
- Remove vertical margin offsets.
- Anchor content inside loader to `anchors.left: parent.left`, `anchors.top: parent.top`, `anchors.bottom: parent.bottom`.

- [ ] **Step 2: Update `modules/drawers/Panels.qml` Dashboard layout**
In `Panels.qml`:
- Change `Dashboard.Wrapper` anchors from `anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top` to:
  `anchors.left: parent.left`
  `anchors.verticalCenter: parent.verticalCenter`
- Update `Panels.qml` margins:
  Change `anchors.leftMargin: bar.implicitWidth` to `anchors.topMargin: bar.implicitHeight`.

- [ ] **Step 3: Verify syntax**
Run: `qmllint modules/dashboard/Wrapper.qml modules/drawers/Panels.qml`
Expected: PASS

- [ ] **Step 4: Commit changes**
```bash
git add modules/dashboard/Wrapper.qml modules/drawers/Panels.qml
git commit -m "feat(dashboard): re-anchor dashboard as left sliding drawer"
```

---

### Task 4: Drawers Exclusion Zone & Gesture Interactions

**Files:**
- Modify: `modules/drawers/Exclusions.qml`
- Modify: `modules/drawers/Interactions.qml`
- Modify: `modules/drawers/Regions.qml`
- Modify: `modules/drawers/ContentWindow.qml`

**Interfaces:**
- Consumes: `bar.exclusiveZone`, `panels.dashboard`, mouse events
- Produces: Correct Wayland layer-shell exclusion, hover/drag trigger on left edge for dashboard and top edge for topbar

- [ ] **Step 1: Update `modules/drawers/Exclusions.qml`**
Switch exclusion:
- Bar exclusion: `anchors.top: true` with `exclusiveZone: root.bar.exclusiveZone`.
- Left edge: Standard border exclusion `anchors.left: true`.

- [ ] **Step 2: Update `modules/drawers/Interactions.qml`**
- Adjust `withinPanelWidth` and `withinPanelHeight` for topbar offset `bar.implicitHeight`.
- Wire `inLeftPanel(panels.dashboard, x, y)` and horizontal drag `dragX > Config.dashboard.dragThreshold` to toggle `screenState.dashboard`.
- Wire top edge hover / wheel `event.y < bar.implicitHeight` to `bar.handleWheel`.

- [ ] **Step 3: Update `modules/drawers/Regions.qml` and `ContentWindow.qml`**
- In `Regions.qml`: inner transparent window region offsets by `y: bar.clampedHeight` rather than `x: bar.clampedWidth`.
- In `ContentWindow.qml`: update `PanelBg` coordinates to `x: panel.x + root.borderThickness` and `y: panel.y + bar.implicitHeight`.

- [ ] **Step 4: Verify syntax across modules/drawers**
Run: `qmllint modules/drawers/*.qml`
Expected: PASS

- [ ] **Step 5: Commit changes**
```bash
git add modules/drawers/Exclusions.qml modules/drawers/Interactions.qml modules/drawers/Regions.qml modules/drawers/ContentWindow.qml
git commit -m "feat(drawers): update layer-shell exclusions and interaction handlers for topbar and left dashboard"
```

---

### Task 5: End-to-End Integration & Shell Verification

**Files:**
- Verify: Full shell in `/home/zulfi/Projects/caelestia-wayland`

- [ ] **Step 1: Run comprehensive QML syntax check**
Run: `find modules components -name "*.qml" -exec qmllint {} + 2>&1 | grep -i "error:" || echo "No syntax errors found"`
Expected: No syntax errors found

- [ ] **Step 2: Test run Quickshell with modified config**
Run test instance:
`quickshell -p /home/zulfi/Projects/caelestia-wayland/shell.qml --dry-run || true`

- [ ] **Step 3: Commit final integration touches if any**
```bash
git commit --allow-empty -m "chore: verify topbar and left dashboard integration"
```
