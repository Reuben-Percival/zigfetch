const std = @import("std");

pub const BorderStyle = enum {
    rounded,
    ascii,
    none,
};

pub const Config = struct {
    color: bool = true,
    border: BorderStyle = .rounded,
    show_icon: bool = true,
    force_icon: bool = false,
    show_icon_path: bool = true,
    show_icon_note: bool = true,
    compact: bool = false,
    chafa_width: u8 = 34,
    chafa_height: u8 = 16,
};

fn parseBool(v: []const u8) ?bool {
    if (std.ascii.eqlIgnoreCase(v, "true") or std.mem.eql(u8, v, "1") or std.ascii.eqlIgnoreCase(v, "yes")) return true;
    if (std.ascii.eqlIgnoreCase(v, "false") or std.mem.eql(u8, v, "0") or std.ascii.eqlIgnoreCase(v, "no")) return false;
    return null;
}

fn parseBorder(v: []const u8) ?BorderStyle {
    if (std.ascii.eqlIgnoreCase(v, "rounded")) return .rounded;
    if (std.ascii.eqlIgnoreCase(v, "ascii")) return .ascii;
    if (std.ascii.eqlIgnoreCase(v, "none")) return .none;
    return null;
}

fn parseU8(v: []const u8) ?u8 {
    return std.fmt.parseUnsigned(u8, v, 10) catch null;
}

fn applyKV(cfg: *Config, key: []const u8, value: []const u8) void {
    if (std.mem.eql(u8, key, "color")) {
        if (parseBool(value)) |b| cfg.color = b;
    } else if (std.mem.eql(u8, key, "border")) {
        if (parseBorder(value)) |b| cfg.border = b;
    } else if (std.mem.eql(u8, key, "show_icon")) {
        if (parseBool(value)) |b| cfg.show_icon = b;
    } else if (std.mem.eql(u8, key, "force_icon")) {
        if (parseBool(value)) |b| cfg.force_icon = b;
    } else if (std.mem.eql(u8, key, "show_icon_path")) {
        if (parseBool(value)) |b| cfg.show_icon_path = b;
    } else if (std.mem.eql(u8, key, "show_icon_note")) {
        if (parseBool(value)) |b| cfg.show_icon_note = b;
    } else if (std.mem.eql(u8, key, "compact")) {
        if (parseBool(value)) |b| cfg.compact = b;
    } else if (std.mem.eql(u8, key, "chafa_width")) {
        if (parseU8(value)) |n| cfg.chafa_width = n;
    } else if (std.mem.eql(u8, key, "chafa_height")) {
        if (parseU8(value)) |n| cfg.chafa_height = n;
    }
}

fn loadFromPath(allocator: std.mem.Allocator, cfg: *Config, path: []const u8) void {
    const file = std.fs.openFileAbsolute(path, .{}) catch return;
    defer file.close();
    const data = file.readToEndAlloc(allocator, 128 * 1024) catch return;
    defer allocator.free(data);

    var lines = std.mem.splitScalar(u8, data, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, " \t\r");
        if (line.len == 0) continue;
        if (line[0] == '#' or line[0] == ';') continue;
        const eq = std.mem.indexOfScalar(u8, line, '=') orelse continue;
        const key = std.mem.trim(u8, line[0..eq], " \t\r");
        const value = std.mem.trim(u8, line[eq + 1 ..], " \t\r");
        if (key.len == 0 or value.len == 0) continue;
        applyKV(cfg, key, value);
    }
}

pub fn load(allocator: std.mem.Allocator) Config {
    var cfg = Config{};
    if (std.posix.getenv("ZIGFETCH_CONFIG")) |custom_path| {
        loadFromPath(allocator, &cfg, custom_path);
        return cfg;
    }
    const home = std.posix.getenv("HOME") orelse return cfg;
    const default_path = std.fmt.allocPrint(allocator, "{s}/.config/zigfetch/config.conf", .{home}) catch return cfg;
    defer allocator.free(default_path);
    loadFromPath(allocator, &cfg, default_path);
    return cfg;
}
