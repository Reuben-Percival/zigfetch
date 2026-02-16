# zigfetch Config Wiki

This wiki is entirely about configuring `zigfetch`.

## 1) Runtime Config Model

`zigfetch` config is runtime-loaded.

- Edit config file
- Run `zigfetch` again
- No rebuild needed

## 2) Config File Path

Resolution order:

1. `ZIGFETCH_CONFIG` (if set)
2. `~/.config/zigfetch/config.conf`

First-run behavior:

- If using default path and file is missing, `zigfetch` auto-generates it.

You can also generate manually:

```sh
zigfetch --init-config
```

Overwrite existing with defaults:

```sh
zigfetch --init-config --force
```

## 3) Format Rules

- One setting per line: `key=value`
- Whitespace around key/value is allowed
- Comments start with `#` or `;`
- Empty lines are ignored

Example:

```ini
preset=clean
color=auto
style=none
icon=auto
```

Evaluation order note:

- Config is processed top-to-bottom.
- `preset=...` resets baseline values first.
- Keys below `preset` override that preset.
- `modules`, `modules+`, and `modules-` are applied in file order.

## 4) High-Impact Keys (Recommended)

### `preset`
Values: `clean`, `minimal`, `fancy`, `plain`

Purpose: sets a strong baseline quickly.

### `color`
Values: `auto`, `on`, `off`

Purpose: controls ANSI colors.

### `style`
Values: `rounded`, `ascii`, `none`

Purpose: frame style.

### `icon`
Values: `auto`, `off`, `path`, `force`

Purpose:
- `auto`: try rendering icon, fallback to path line
- `off`: disable icon behavior
- `path`: always show icon path, skip renderer
- `force`: force renderer attempts even in limited terminals

### `modules`
Comma-separated ordered module list.

Available modules:

- `os`
- `arch`
- `kernel`
- `uptime`
- `cpu`
- `memory`
- `packages`
- `shell`
- `terminal`
- `session`
- `desktop`
- `wm`

Example:

```ini
modules=os,kernel,uptime,memory,shell,terminal
```

## 5) Advanced Keys

### `compact`
Values: `true`, `false`

Reduces spacing and extra decoration.

### `show_icon_note`
Values: `true`, `false`

Show/hide hint text when icon is not rendered.

### `chafa_size`
Format: `WIDTHxHEIGHT` (e.g. `34x16`)

Sets icon render size for `chafa`.

Backward-compatible alternatives still accepted:

- `chafa_width`
- `chafa_height`

## 6) Module Editing Operations

You can adjust module list incrementally.

### Add modules

```ini
modules+=packages,wm
```

### Remove modules

```ini
modules-=desktop,wm
```

### Replace modules

```ini
modules=os,uptime,memory
```

## 7) Preset Definitions

### `clean`
- style: `none`
- color: `auto`
- icon: `auto`
- note: off
- modules: full list

### `minimal`
- style: `none`
- color: `off`
- icon: `off`
- compact: on
- modules: reduced set

### `fancy`
- style: `rounded`
- color: `on`
- icon: `auto`
- note: on
- larger icon size
- modules: full list

### `plain`
- style: `ascii`
- color: `off`
- icon: `path`
- note: off
- modules: full list

## 8) Environment Variables

### `ZIGFETCH_CONFIG`
Use custom config file path.

```sh
ZIGFETCH_CONFIG=/path/to/config.conf zigfetch
```

### `ZIGFETCH_NO_ICON=1`
Hard disable icon rendering.

### `ZIGFETCH_FORCE_ICON=1`
Hard force icon render attempts.

Priority notes:

- `ZIGFETCH_NO_ICON=1` disables icon rendering regardless of config.
- `ZIGFETCH_FORCE_ICON=1` forces attempts regardless of terminal heuristics.

## 9) Config Doctor

Check config validity:

```sh
zigfetch --doctor-config
```

Doctor reports:

- unknown keys
- invalid values
- syntax issues
- effective resolved settings summary

Tip:

- Run `zigfetch --doctor-config` after major edits to confirm your intended preset/style/icon/modules state.

## 10) Practical Recipes

### Fastfetch-like clean look

```ini
preset=clean
color=auto
style=none
icon=auto
show_icon_note=false
```

### Script/CI safe output

```ini
preset=minimal
color=off
style=none
icon=off
compact=true
```

### Fancy local terminal

```ini
preset=fancy
style=rounded
icon=force
chafa_size=40x18
```

### Minimal but keep icon path visible

```ini
preset=minimal
icon=path
compact=true
```

## 11) Migration from Old Keys

Old keys are still supported for compatibility:

- `border` -> use `style`
- `show_icon` -> use `icon`
- `force_icon` -> use `icon=force`
- `show_icon_path` -> use `icon=path`/`icon=off`
- `chafa_width` + `chafa_height` -> prefer `chafa_size`

## 12) Default Generated Config

```ini
preset=clean
color=auto
style=rounded
icon=auto
compact=false
show_icon_note=true
chafa_size=34x16
modules=os,arch,kernel,uptime,cpu,memory,packages,shell,terminal,session,desktop,wm
```
