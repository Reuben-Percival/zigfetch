# zigfetch

A fast, configurable system info tool written in Zig.

`zigfetch` focuses on clean terminal output, runtime configuration (no rebuilds), distro icon support, and modular Linux system details.

## Quick Start

```sh
zig build
./zig-out/bin/zigfetch
```

## Install

```sh
./install.sh
```

## Configuration

Config path resolution:

1. `ZIGFETCH_CONFIG` (if set)
2. `~/.config/zigfetch/config.conf`

Useful commands:

```sh
zigfetch --init-config
zigfetch --init-config --force
zigfetch --doctor-config
```

## Core Keys

- `preset`: `clean | minimal | fancy | plain`
- `color`: `auto | on | off`
- `color_scheme` (alias `scheme`): `natural | ocean | sunset | mono`
- `style`: `rounded | ascii | none`
- `icon`: `auto | off | path | force`
- `compact`: `true | false`
- `show_icon_note`: `true | false`
- `chafa_size`: `WIDTHxHEIGHT`

## Module Controls

You can control modules with:

1. Ordered list (`modules=...`)
2. Incremental edits (`modules+=...`, `modules-=...`)
3. Per-module booleans (`module.<name>=true|false`)

Example:

```ini
modules=os,arch,kernel,uptime,cpu,gpu,memory,shell,terminal
modules+=battery,cpu_temp,audio
module.bios=false
module.cpu_temp=true
```

## Supported Modules

- `os`, `arch`, `kernel`, `uptime`
- `host_model`, `bios`, `motherboard`
- `cpu`, `cpu_cores`, `cpu_threads`, `cpu_freq`, `cpu_temp`
- `gpu`, `gpu_driver`, `resolution`
- `memory`, `swap`, `disk`, `battery`
- `load`, `processes`, `network`, `audio`
- `packages`, `shell`, `terminal`, `session`, `desktop`, `wm`

## Environment Variables

```sh
ZIGFETCH_CONFIG=/path/to/config.conf zigfetch
ZIGFETCH_NO_ICON=1 zigfetch
ZIGFETCH_FORCE_ICON=1 zigfetch
```

## Notes

- Config is applied top-to-bottom.
- `preset=...` resets the baseline first.
- Keys below `preset` override preset values.

For full details, see `WIKI.md`.
