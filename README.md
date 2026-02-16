# zigfetch

A neat, fastfetch-inspired system info tool in Zig with real distro icon support and runtime config.

## Highlights

- Fastfetch-style layout with aligned modules
- Real distro icon discovery from system icon files
- Inline icon rendering with `chafa`, `wezterm imgcat`, or kitty image tools
- Runtime config file loading (no rebuild required)
- Optional frame styles, colors, compact mode, and icon behavior controls

## Build & Run

```sh
zig build
./zig-out/bin/zigfetch
```

## Install

```sh
./install.sh
```

Custom prefix:

```sh
PREFIX=$HOME/.local ./install.sh
```

## Runtime Config (No Rebuild)

Config file:

```txt
~/.config/zigfetch/config.conf
```

Example:

```ini
color=true
border=rounded
compact=false
show_icon=true
force_icon=false
show_icon_path=true
show_icon_note=true
chafa_width=34
chafa_height=16
```

After editing config, just run `zigfetch` again.

## Config Path Override

Use a different config file at runtime:

```sh
ZIGFETCH_CONFIG=/path/to/config.conf zigfetch
```

## Icon Overrides

- Disable icon rendering:

```sh
ZIGFETCH_NO_ICON=1 zigfetch
```

- Force icon rendering attempts:

```sh
ZIGFETCH_FORCE_ICON=1 zigfetch
```

## More Docs

See `WIKI.md` for full key reference, presets, and troubleshooting.
