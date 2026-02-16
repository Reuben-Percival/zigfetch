# zigfetch Config Wiki

This page documents `zigfetch` runtime config and behavior.

## 1. Config Path

Resolution order:

1. `ZIGFETCH_CONFIG`
2. `~/.config/zigfetch/config.conf`

If `ZIGFETCH_CONFIG` is not set and the default file is missing, `zigfetch` auto-creates it.

Manual setup:

```sh
zigfetch --init-config
zigfetch --init-config --force
```

## 2. File Format

- One setting per line: `key=value`
- Leading/trailing whitespace is ignored
- Comments start with `#` or `;`
- Empty lines are ignored

Config is applied top-to-bottom.

Important ordering rule:

- `preset=...` resets all fields to that preset baseline
- Later keys override preset values

## 3. High-Impact Keys

### `preset`

Values: `clean`, `minimal`, `fancy`, `plain`

### `color`

Values: `auto`, `on`, `off`

### `style`

Values: `rounded`, `ascii`, `none`

### `icon`

Values: `auto`, `off`, `path`, `force`

- `auto`: render icon when terminal supports it; otherwise fallback behavior
- `off`: disable icon rendering and icon path output
- `path`: show icon path only
- `force`: attempt icon rendering even in limited terminal detection cases

### `modules`

Comma-separated ordered list.

Supported modules:

- `os`
- `arch`
- `kernel`
- `uptime`
- `cpu`
- `cpu_cores`
- `cpu_threads`
- `gpu`
- `memory`
- `packages`
- `shell`
- `terminal`
- `session`
- `desktop`
- `wm`

Example:

```ini
modules=os,kernel,uptime,cpu,memory,gpu
```

## 4. Additional Keys

### `compact`

Values: `true`, `false`

### `show_icon_note`

Values: `true`, `false`

### `chafa_size`

Format: `WIDTHxHEIGHT` (example `34x16`)

Backward-compatible forms also accepted:

- `chafa_width`
- `chafa_height`

## 5. Module Editing Operations

### Replace

```ini
modules=os,uptime,memory
```

### Add

```ini
modules+=packages,wm
```

### Remove

```ini
modules-=desktop,wm
```

## 6. Preset Baselines

### `clean`

- style: `none`
- color: `auto`
- icon: `auto`
- show_icon_note: `false`
- compact: `false`
- modules: full list

### `minimal`

- style: `none`
- color: `off`
- icon: `off`
- show_icon_note: `false`
- compact: `true`
- modules: reduced list

### `fancy`

- style: `rounded`
- color: `on`
- icon: `auto`
- show_icon_note: `true`
- compact: `false`
- chafa_size: `40x18`
- modules: full list

### `plain`

- style: `ascii`
- color: `off`
- icon: `path`
- show_icon_note: `false`
- compact: `false`
- modules: full list

## 7. Environment Variables

### `ZIGFETCH_CONFIG`

```sh
ZIGFETCH_CONFIG=/path/to/config.conf zigfetch
```

### `ZIGFETCH_NO_ICON=1`

Disables icon rendering.

### `ZIGFETCH_FORCE_ICON=1`

Forces icon render attempts (unless icon mode is explicitly `off` or `path`).

## 8. Config Doctor

```sh
zigfetch --doctor-config
```

Doctor reports:

- syntax errors
- unknown keys
- invalid values
- effective resolved summary

## 9. Backward-Compatible Keys

- `border` -> `style`
- `show_icon` -> `icon`
- `force_icon` -> `icon=force`
- `show_icon_path` -> `icon=path` or `icon=off`

## 10. Default Generated Config

```ini
preset=clean
color=auto
style=none
icon=auto
compact=false
show_icon_note=false
chafa_size=34x16
modules=os,arch,kernel,uptime,cpu,cpu_cores,cpu_threads,gpu,memory,packages,shell,terminal,session,desktop,wm
```
