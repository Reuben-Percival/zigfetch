# zigfetch Wiki

## Runtime Behavior

`zigfetch` loads config at startup every run.
You do **not** need to rebuild after changing config.

## Config Resolution Order

1. If `ZIGFETCH_CONFIG` is set, that file is loaded.
2. Otherwise default config is loaded from:
   - `~/.config/zigfetch/config.conf`
3. Missing file means defaults are used.

## Config Keys

- `color=true|false`
  - Enables ANSI colors when output is a TTY.
- `border=rounded|ascii|none`
  - Frame style around the module list.
- `compact=true|false`
  - Tightens spacing and hides extra separators/color bar.
- `show_icon=true|false`
  - Enables icon renderer attempts.
- `force_icon=true|false`
  - Forces icon attempts even in limited terminal contexts.
- `show_icon_path=true|false`
  - Shows discovered icon path when icon is not rendered inline.
- `show_icon_note=true|false`
  - Shows renderer install hint when icon isn’t rendered.
- `chafa_width=1..255`
  - Width used for `chafa --size`.
- `chafa_height=1..255`
  - Height used for `chafa --size`.

## Example Presets

### 1) Fastfetch-like clean

```ini
color=true
border=none
compact=false
show_icon=true
show_icon_path=false
show_icon_note=false
```

### 2) Minimal logs/CI

```ini
color=false
border=ascii
compact=true
show_icon=false
show_icon_path=false
show_icon_note=false
```

### 3) Styled dashboard

```ini
color=true
border=rounded
compact=false
show_icon=true
show_icon_path=true
show_icon_note=true
chafa_width=40
chafa_height=18
```

## Environment Variables

- `ZIGFETCH_CONFIG=/path/to/config.conf`
  - Use an alternate config file.
- `ZIGFETCH_NO_ICON=1`
  - Disable icon rendering.
- `ZIGFETCH_FORCE_ICON=1`
  - Force icon rendering attempts.

## Troubleshooting

### Icon is not showing

1. Ensure a renderer is installed (`chafa` recommended).
2. Check the printed icon path exists.
3. Try force mode:

```sh
ZIGFETCH_FORCE_ICON=1 zigfetch
```

### Config changes not applying

1. Confirm correct file path:

```sh
echo "$ZIGFETCH_CONFIG"
```

2. Run with explicit path:

```sh
ZIGFETCH_CONFIG=~/.config/zigfetch/config.conf zigfetch
```

3. Check syntax: `key=value`, one per line.
