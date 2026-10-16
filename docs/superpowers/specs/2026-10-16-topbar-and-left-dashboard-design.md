# Specification: Caelestia Topbar and Left Dashboard Transformation

## 1. Overview
Transform Caelestia Shell's layout:
- Relocate the status bar from the **left edge** (`ColumnLayout`) to the **top edge** (`RowLayout`), retaining identical styling, tokens, and components.
- Relocate the dashboard drawer from the **top edge** to the **left edge**, retaining full sliding drawer behavior, hover/drag triggers, and blob deformation effects.

## 2. Component Changes

### 2.1 Bar & BarWrapper (`modules/bar/`)
- **`Bar.qml`**:
  - Convert root container from `ColumnLayout` to `RowLayout`.
  - Spacers change from `Layout.fillHeight: true` to `Layout.fillWidth: true` to preserve the three-zone distribution: left (logo/workspaces), center (activeWindow), and right (tray/clock/status/power).
  - Update `checkPopout(x)` to find children along the horizontal axis (`childAt(x, height / 2)`), binding `popouts.currentCenter` to horizontal center.
  - Update `handleWheel` to navigate workspaces or adjust volume/brightness using horizontal mouse/trackpad events.
- **`BarWrapper.qml`**:
  - Anchors: `anchors.top: parent.top`, `anchors.left: parent.left`, `anchors.right: parent.right`.
  - Dimension: Switch from `implicitWidth` to `implicitHeight` for the bar height (`Tokens.sizes.bar.innerWidth + padding * 2`).
  - State animation: Animate `implicitHeight` between `0` / `Config.border.thickness` and `contentHeight`.
  - Zone: `exclusiveZone` provides top clearance for windows.

### 2.2 Bar Popouts (`modules/bar/popouts/`)
- **`ClipWrapper.qml` & `Wrapper.qml`**:
  - Horizontal placement: Anchored to `currentCenter` (X axis) aligned beneath the topbar entry.
  - Vertical placement: Drops down immediately below the topbar (`y: bar.implicitHeight + borderThickness`).
  - Clamp X coordinates within screen bounds (`0` to `screen.width - width`).

### 2.3 Dashboard (`modules/dashboard/` & `modules/drawers/Panels.qml`)
- **`Panels.qml`**:
  - Re-anchor `Dashboard.Wrapper`:
    - `anchors.left: parent.left`
    - `anchors.verticalCenter: parent.verticalCenter` (or top/bottom constrained).
  - Top margin accounts for the topbar's `implicitHeight`.
- **`modules/dashboard/Wrapper.qml`**:
  - Change slide animation from vertical (`anchors.topMargin`) to horizontal (`anchors.leftMargin: (-implicitWidth - 5) * offsetScale`).
  - Maintain opacity transition (`1 - offsetScale`) and ease curve.

### 2.4 Drawers & Interaction System (`modules/drawers/`)
- **`Exclusions.qml`**:
  - Move bar exclusion zone from `anchors.left: true` to `anchors.top: true` with `exclusiveZone: root.bar.exclusiveZone`.
- **`Interactions.qml`**:
  - `inLeftPanel(panels.dashboard, x, y)`: Detects cursor in the left dashboard trigger zone.
  - Hover detection: Hovering near the left edge (`x < threshold`) triggers `screenState.dashboard = true`.
  - Drag gesture: Horizontal drag (`dragX > threshold`) from left screen edge reveals dashboard; dragging left (`dragX < -threshold`) closes it.
  - Wheel and top hover: Wheel on topbar (`y < bar.implicitHeight`) routes to `bar.handleWheel`.
- **`Regions.qml`**:
  - Transpose input cutout bounds:
    - Inner transparent zone starts at `y: bar.clampedHeight` rather than `x: bar.clampedWidth`.
    - Dashboard exclusion region starts at `x: 0`, width scaled by `(1 - offsetScale)`.
- **`ContentWindow.qml`**:
  - Update `PanelBg` coordinate mapping:
    - `x: panel.x + root.borderThickness`
    - `y: panel.y + bar.implicitHeight`
  - Ensure blob deformation matrix on `dashBg` matches the horizontal slide vector.

## 3. Verification & Acceptance Criteria
1. **Compilation / Syntax**: QML files validate without syntax errors.
2. **Topbar Display**: Bar sits horizontally along the top edge, showing logo, workspaces, clock, and status icons in their intended layout.
3. **Popouts**: Tray menus, volume/brightness popouts, and active window tooltip pop open directly below their topbar icon.
4. **Dashboard Drawer**: Opening dashboard (via hover on left edge, left swipe, or key shortcut) slides smoothly from the left screen edge.
5. **No Regressions**: Fullscreen detection correctly hides bar; launcher at the bottom and quick settings sidebar at the right continue operating as normal.
