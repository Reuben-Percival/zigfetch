# zigfetch

A simple `fetch`-style system info CLI written in Zig.

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
