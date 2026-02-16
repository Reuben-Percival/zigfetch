# zigfetch Config Wiki

This document is the canonical reference for runtime configuration.

## 1. Config Path

Resolution order:

1. `ZIGFETCH_CONFIG`
2. `~/.config/zigfetch/config.conf`

If `ZIGFETCH_CONFIG` is not set and the default config is missing, zigfetch auto-creates it.

Commands:

```sh
zigfetch --init-config
zigfetch --init-config --force
zigfetch --doctor-config
```

## 2. File Rules

- One setting per line: `key=value`
- Leading/trailing whitespace is ignored
- Comments start with `#` or `;`
- Empty lines are ignored

Evaluation is top-to-bottom.

Important behavior:

- `preset=...` resets the config baseline
- Keys below that line override preset values
- `modules`, `modules+`, `modules-`, and `module.<name>=...` apply in file order

## 3. Keys

### `preset`

Values: `clean`, `minimal`, `fancy`, `plain`

### `color`

Values: `auto`, `on`, `off`

### `color_scheme` (alias: `scheme`)

Values: `natural`, `ocean`, `sunset`, `mono`

### `style`

Values: `rounded`, `ascii`, `none`

### `icon`

Values: `auto`, `off`, `path`, `force`

- `auto`: try renderer based on terminal support
- `off`: disable icon rendering and icon path output
- `path`: only print icon path
- `force`: force icon rendering attempts

### `compact`

Values: `true`, `false`

### `show_icon_note`

Values: `true`, `false`

### `chafa_size`

Format: `WIDTHxHEIGHT` (example: `34x16`)

Also accepted:

- `chafa_width`
- `chafa_height`

## 4. Module Configuration

### Replace full order

```ini
modules=os,arch,kernel,uptime,cpu,gpu,memory,shell,terminal
```

### Incremental edits

```ini
modules+=battery,cpu_temp,audio
modules-=desktop,wm
```

### Per-module booleans

```ini
module.cpu_temp=true
module.battery=true
module.audio=true
module.host_model=false
```

## 5. Supported Modules

- `os`
- `arch`
- `kernel`
- `uptime`
- `host_model`
- `bios`
- `motherboard`
- `cpu`
- `cpu_cores`
- `cpu_threads`
- `cpu_freq`
- `cpu_temp`
- `gpu`
- `gpu_driver`
- `resolution`
- `memory`
- `swap`
- `disk`
- `battery`
- `load`
- `processes`
- `network`
- `audio`
- `packages`
- `shell`
- `terminal`
- `session`
- `desktop`
- `wm`

## 6. Preset Baselines

### `clean`

- `style=none`
- `color=auto`
- `color_scheme=natural`
- `icon=auto`
- `compact=false`
- `show_icon_note=false`
- `chafa_size=34x16`
- modules: full internal set, then default template toggles optional modules off

### `minimal`

- `style=none`
- `color=off`
- `color_scheme=natural`
- `icon=off`
- `compact=true`
- `show_icon_note=false`
- reduced module set: `os,kernel,uptime,memory,shell,terminal`

### `fancy`

- `style=rounded`
- `color=on`
- `color_scheme=sunset`
- `icon=auto`
- `compact=false`
- `show_icon_note=true`
- `chafa_size=40x18`

### `plain`

- `style=ascii`
- `color=off`
- `color_scheme=mono`
- `icon=path`
- `compact=false`
- `show_icon_note=false`

## 7. Audio Module

Audio detection order:

1. `wpctl inspect @DEFAULT_AUDIO_SINK@` (`node.description`, `node.nick`, `node.name`)
2. `pactl info` (`Default Sink:`)
3. `pactl get-default-sink`

If none are available, output is `unknown`.

## 8. Environment Variables

```sh
ZIGFETCH_CONFIG=/path/to/config.conf zigfetch
ZIGFETCH_NO_ICON=1 zigfetch
ZIGFETCH_FORCE_ICON=1 zigfetch
```

## 9. Backward-Compatible Keys

- `border` -> `style`
- `show_icon` -> `icon`
- `force_icon` -> `icon=force`
- `show_icon_path` -> `icon=path` or `icon=off`
