# zigfetch

A fastfetch-inspired system info tool written in Zig, with a simpler high-impact config model.

## Quick Start

```sh
zig build
./zig-out/bin/zigfetch
```

## Install

```sh
./install.sh
```

## Config (Runtime, No Rebuild)

`zigfetch` loads config every run.

Default path:

```txt
~/.config/zigfetch/config.conf
```

Auto-generate config:

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

## Core Config Keys

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

Module editing shortcuts:

```ini
modules+=packages,wm
modules-=desktop
```

## Useful Overrides

```sh
ZIGFETCH_CONFIG=/path/to/config.conf zigfetch
ZIGFETCH_NO_ICON=1 zigfetch
ZIGFETCH_FORCE_ICON=1 zigfetch
```

## Help

```sh
zigfetch --help
```

## Full Docs

See `WIKI.md` for complete configuration reference, presets, and troubleshooting.
