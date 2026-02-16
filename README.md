# zigfetch

Fastfetch-style system info in Zig with runtime config and distro icon support.

## Build and Run

```sh
zig build
./zig-out/bin/zigfetch
```

## Install

```sh
./install.sh
```

## Runtime Config

Config path resolution:

1. `ZIGFETCH_CONFIG` (if set)
2. `~/.config/zigfetch/config.conf`

Create config if missing:

```sh
zigfetch --init-config
```

Overwrite with fresh defaults:

```sh
zigfetch --init-config --force
```

Validate config:

```sh
zigfetch --doctor-config
```

## Default Generated Config

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

## Key Config Options

- `preset`: `clean | minimal | fancy | plain`
- `color`: `auto | on | off`
- `style`: `rounded | ascii | none`
- `icon`: `auto | off | path | force`
- `chafa_size`: `WIDTHxHEIGHT`
- `modules`: ordered, comma-separated module names

Supported modules:

- `os`, `arch`, `kernel`, `uptime`, `cpu`, `cpu_cores`, `cpu_threads`, `gpu`, `memory`, `packages`, `shell`, `terminal`, `session`, `desktop`, `wm`

Incremental module edits:

```ini
modules+=packages,wm
modules-=desktop
```

## Environment Overrides

```sh
ZIGFETCH_CONFIG=/path/to/config.conf zigfetch
ZIGFETCH_NO_ICON=1 zigfetch
ZIGFETCH_FORCE_ICON=1 zigfetch
```

## Full Reference

See `WIKI.md` for full config behavior and preset definitions.
