# zigfetch

A modular `fetch`-style system info CLI written in Zig.

It can render your distro's real icon (from system icon files) when image-capable terminal tools are available.

## Build

```sh
zig build
```

Binary path after build:

```sh
./zig-out/bin/zigfetch
```

## Run

```sh
zig build run
```

If one of these is installed, `zigfetch` will render the distro icon inline:
- `chafa`
- `wezterm imgcat`
- `kitty` / `kitten icat`

## Install

Default prefix (`/usr/local`):

```sh
./install.sh
```

Custom prefix:

```sh
PREFIX=$HOME/.local ./install.sh
```

## Uninstall

Default prefix (`/usr/local`):

```sh
./uninstall.sh
```

Custom prefix:

```sh
PREFIX=$HOME/.local ./uninstall.sh
```

## Notes

- Icon lookup is based on `/etc/os-release` (`LOGO`, `ID`, `ID_LIKE`) and searches:
  - `/usr/share/icons`
  - `/usr/share/pixmaps`
  - `/usr/share/branding`
  - `/usr/share/distribution-logos`
- Extra info shown includes:
  - architecture
  - shell
  - terminal
  - desktop session
- If no renderer is available, `zigfetch` prints the real icon file path it found.
