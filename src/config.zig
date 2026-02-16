const std = @import("std");

pub const BorderStyle = enum {
    rounded,
    ascii,
    none,
};

pub const ColorMode = enum {
    auto,
    on,
    off,
};

pub const IconMode = enum {
    auto,
    off,
    path,
    force,
};

pub const Preset = enum {
    clean,
    minimal,
    fancy,
    plain,
};

pub const Module = enum {
    os,
    arch,
    kernel,
    uptime,
    cpu,
    cpu_cores,
    cpu_threads,
    gpu,
    memory,
    packages,
    shell,
    terminal,
    session,
    desktop,
    wm,
};

pub const Config = struct {
    preset: Preset,
    color_mode: ColorMode,
    border: BorderStyle,
    icon_mode: IconMode,
    show_icon_note: bool,
    compact: bool,
    chafa_width: u8,
    chafa_height: u8,
    modules: [16]Module,
    module_count: usize,
};

const all_modules = [_]Module{
    .os, .arch, .kernel, .uptime, .cpu, .cpu_cores, .cpu_threads, .gpu, .memory, .packages, .shell, .terminal, .session, .desktop, .wm,
};

const minimal_modules = [_]Module{
    .os, .kernel, .uptime, .memory, .shell, .terminal,
};

const default_config_contents =
    \\# zigfetch configuration
    \\# Generated automatically on first run.
    \\#
    \\# High-impact keys:
    \\# preset = clean|minimal|fancy|plain
    \\# color  = auto|on|off
    \\# style  = rounded|ascii|none
    \\# icon   = auto|off|path|force
    \\# modules = comma-separated module names
    \\#
    \\preset=clean
    \\color=auto
    \\style=none
    \\icon=auto
    \\compact=false
    \\show_icon_note=false
    \\chafa_size=34x16
    \\modules=os,arch,kernel,uptime,cpu,cpu_cores,cpu_threads,gpu,memory,packages,shell,terminal,session,desktop,wm
    \\
;

pub fn applyPreset(cfg: *Config, preset: Preset) void {
    cfg.* = .{
        .preset = preset,
        .color_mode = .auto,
        .border = .rounded,
        .icon_mode = .auto,
        .show_icon_note = true,
        .compact = false,
        .chafa_width = 34,
        .chafa_height = 16,
        .modules = undefined,
        .module_count = 0,
    };

    switch (preset) {
        .clean => {
            setModules(cfg, &all_modules);
            cfg.border = .none;
            cfg.show_icon_note = false;
        },
        .minimal => {
            setModules(cfg, &minimal_modules);
            cfg.border = .none;
            cfg.icon_mode = .off;
            cfg.compact = true;
            cfg.color_mode = .off;
            cfg.show_icon_note = false;
        },
        .fancy => {
            setModules(cfg, &all_modules);
            cfg.border = .rounded;
            cfg.color_mode = .on;
            cfg.icon_mode = .auto;
            cfg.compact = false;
            cfg.show_icon_note = true;
            cfg.chafa_width = 40;
            cfg.chafa_height = 18;
        },
        .plain => {
            setModules(cfg, &all_modules);
            cfg.border = .ascii;
            cfg.color_mode = .off;
            cfg.icon_mode = .path;
            cfg.show_icon_note = false;
        },
    }
}

pub fn defaults() Config {
    var cfg: Config = undefined;
    applyPreset(&cfg, .clean);
    return cfg;
}

fn setModules(cfg: *Config, list: []const Module) void {
    cfg.module_count = @min(list.len, cfg.modules.len);
    for (list[0..cfg.module_count], 0..) |m, i| cfg.modules[i] = m;
}

fn parseBool(v: []const u8) ?bool {
    if (std.ascii.eqlIgnoreCase(v, "true") or std.mem.eql(u8, v, "1") or std.ascii.eqlIgnoreCase(v, "yes")) return true;
    if (std.ascii.eqlIgnoreCase(v, "false") or std.mem.eql(u8, v, "0") or std.ascii.eqlIgnoreCase(v, "no")) return false;
    return null;
}

fn parseU8(v: []const u8) ?u8 {
    return std.fmt.parseUnsigned(u8, v, 10) catch null;
}

fn parseBorder(v: []const u8) ?BorderStyle {
    if (std.ascii.eqlIgnoreCase(v, "rounded")) return .rounded;
    if (std.ascii.eqlIgnoreCase(v, "ascii")) return .ascii;
    if (std.ascii.eqlIgnoreCase(v, "none")) return .none;
    return null;
}

fn parseColorMode(v: []const u8) ?ColorMode {
    if (std.ascii.eqlIgnoreCase(v, "auto")) return .auto;
    if (std.ascii.eqlIgnoreCase(v, "on")) return .on;
    if (std.ascii.eqlIgnoreCase(v, "off")) return .off;
    if (parseBool(v)) |b| return if (b) .on else .off; // backwards compatibility
    return null;
}

fn parseIconMode(v: []const u8) ?IconMode {
    if (std.ascii.eqlIgnoreCase(v, "auto")) return .auto;
    if (std.ascii.eqlIgnoreCase(v, "off")) return .off;
    if (std.ascii.eqlIgnoreCase(v, "path")) return .path;
    if (std.ascii.eqlIgnoreCase(v, "force")) return .force;
    return null;
}

fn parsePreset(v: []const u8) ?Preset {
    if (std.ascii.eqlIgnoreCase(v, "clean")) return .clean;
    if (std.ascii.eqlIgnoreCase(v, "minimal")) return .minimal;
    if (std.ascii.eqlIgnoreCase(v, "fancy")) return .fancy;
    if (std.ascii.eqlIgnoreCase(v, "plain")) return .plain;
    return null;
}

fn parseModule(v: []const u8) ?Module {
    if (std.ascii.eqlIgnoreCase(v, "os")) return .os;
    if (std.ascii.eqlIgnoreCase(v, "arch")) return .arch;
    if (std.ascii.eqlIgnoreCase(v, "kernel")) return .kernel;
    if (std.ascii.eqlIgnoreCase(v, "uptime")) return .uptime;
    if (std.ascii.eqlIgnoreCase(v, "cpu")) return .cpu;
    if (std.ascii.eqlIgnoreCase(v, "cpu_cores")) return .cpu_cores;
    if (std.ascii.eqlIgnoreCase(v, "cpu_threads")) return .cpu_threads;
    if (std.ascii.eqlIgnoreCase(v, "gpu")) return .gpu;
    if (std.ascii.eqlIgnoreCase(v, "memory")) return .memory;
    if (std.ascii.eqlIgnoreCase(v, "packages")) return .packages;
    if (std.ascii.eqlIgnoreCase(v, "shell")) return .shell;
    if (std.ascii.eqlIgnoreCase(v, "terminal")) return .terminal;
    if (std.ascii.eqlIgnoreCase(v, "session")) return .session;
    if (std.ascii.eqlIgnoreCase(v, "desktop")) return .desktop;
    if (std.ascii.eqlIgnoreCase(v, "wm")) return .wm;
    return null;
}

fn hasModule(cfg: *const Config, m: Module) bool {
    for (cfg.modules[0..cfg.module_count]) |x| if (x == m) return true;
    return false;
}

fn addModule(cfg: *Config, m: Module) bool {
    if (hasModule(cfg, m)) return true;
    if (cfg.module_count >= cfg.modules.len) return false;
    cfg.modules[cfg.module_count] = m;
    cfg.module_count += 1;
    return true;
}

fn removeModule(cfg: *Config, m: Module) void {
    var i: usize = 0;
    while (i < cfg.module_count) : (i += 1) {
        if (cfg.modules[i] != m) continue;
        var j = i;
        while (j + 1 < cfg.module_count) : (j += 1) cfg.modules[j] = cfg.modules[j + 1];
        cfg.module_count -= 1;
        return;
    }
}

fn setModulesFromString(cfg: *Config, value: []const u8, mode: enum { replace, add, remove }) bool {
    var tmp: [16]Module = undefined;
    var count: usize = 0;
    var it = std.mem.splitScalar(u8, value, ',');
    while (it.next()) |raw| {
        const token = std.mem.trim(u8, raw, " \t\r");
        if (token.len == 0) continue;
        const m = parseModule(token) orelse return false;
        if (count >= tmp.len) return false;
        tmp[count] = m;
        count += 1;
    }
    switch (mode) {
        .replace => {
            cfg.module_count = 0;
            for (tmp[0..count]) |m| if (!addModule(cfg, m)) return false;
        },
        .add => {
            for (tmp[0..count]) |m| if (!addModule(cfg, m)) return false;
        },
        .remove => {
            for (tmp[0..count]) |m| removeModule(cfg, m);
        },
    }
    return true;
}

fn parseSize(value: []const u8, cfg: *Config) bool {
    const x = std.mem.indexOfScalar(u8, value, 'x') orelse return false;
    const w = parseU8(std.mem.trim(u8, value[0..x], " \t\r")) orelse return false;
    const h = parseU8(std.mem.trim(u8, value[x + 1 ..], " \t\r")) orelse return false;
    cfg.chafa_width = w;
    cfg.chafa_height = h;
    return true;
}

fn applyKV(cfg: *Config, key: []const u8, value: []const u8) enum { ok, unknown, invalid } {
    if (std.mem.eql(u8, key, "preset")) {
        const p = parsePreset(value) orelse return .invalid;
        applyPreset(cfg, p);
        return .ok;
    } else if (std.mem.eql(u8, key, "color")) {
        cfg.color_mode = parseColorMode(value) orelse return .invalid;
        return .ok;
    } else if (std.mem.eql(u8, key, "style") or std.mem.eql(u8, key, "border")) {
        cfg.border = parseBorder(value) orelse return .invalid;
        return .ok;
    } else if (std.mem.eql(u8, key, "icon")) {
        cfg.icon_mode = parseIconMode(value) orelse return .invalid;
        return .ok;
    } else if (std.mem.eql(u8, key, "show_icon_note")) {
        cfg.show_icon_note = parseBool(value) orelse return .invalid;
        return .ok;
    } else if (std.mem.eql(u8, key, "compact")) {
        cfg.compact = parseBool(value) orelse return .invalid;
        return .ok;
    } else if (std.mem.eql(u8, key, "chafa_size")) {
        return if (parseSize(value, cfg)) .ok else .invalid;
    } else if (std.mem.eql(u8, key, "chafa_width")) {
        cfg.chafa_width = parseU8(value) orelse return .invalid;
        return .ok;
    } else if (std.mem.eql(u8, key, "chafa_height")) {
        cfg.chafa_height = parseU8(value) orelse return .invalid;
        return .ok;
    } else if (std.mem.eql(u8, key, "modules")) {
        return if (setModulesFromString(cfg, value, .replace)) .ok else .invalid;
    } else if (std.mem.eql(u8, key, "modules+")) {
        return if (setModulesFromString(cfg, value, .add)) .ok else .invalid;
    } else if (std.mem.eql(u8, key, "modules-")) {
        return if (setModulesFromString(cfg, value, .remove)) .ok else .invalid;
    }

    // Backwards compatibility keys.
    if (std.mem.eql(u8, key, "show_icon")) {
        const b = parseBool(value) orelse return .invalid;
        cfg.icon_mode = if (b) .auto else .off;
        return .ok;
    } else if (std.mem.eql(u8, key, "force_icon")) {
        const b = parseBool(value) orelse return .invalid;
        if (b) cfg.icon_mode = .force;
        return .ok;
    } else if (std.mem.eql(u8, key, "show_icon_path")) {
        const b = parseBool(value) orelse return .invalid;
        if (b) {
            if (cfg.icon_mode == .off) cfg.icon_mode = .path;
        } else {
            if (cfg.icon_mode == .path) cfg.icon_mode = .off;
        }
        return .ok;
    }
    return .unknown;
}

fn loadFromPath(allocator: std.mem.Allocator, cfg: *Config, path: []const u8) void {
    const file = std.fs.openFileAbsolute(path, .{}) catch return;
    defer file.close();
    const data = file.readToEndAlloc(allocator, 128 * 1024) catch return;
    defer allocator.free(data);

    var line_no: usize = 0;
    var lines = std.mem.splitScalar(u8, data, '\n');
    while (lines.next()) |raw_line| {
        line_no += 1;
        const line = std.mem.trim(u8, raw_line, " \t\r");
        if (line.len == 0) continue;
        if (line[0] == '#' or line[0] == ';') continue;
        const eq = std.mem.indexOfScalar(u8, line, '=') orelse continue;
        const key = std.mem.trim(u8, line[0..eq], " \t\r");
        const value = std.mem.trim(u8, line[eq + 1 ..], " \t\r");
        if (key.len == 0 or value.len == 0) continue;
        _ = applyKV(cfg, key, value);
    }
}

fn doctorFromPath(allocator: std.mem.Allocator, out: anytype, path: []const u8, cfg: *Config) !void {
    const file = std.fs.openFileAbsolute(path, .{}) catch {
        try out.print("Config file not found.\n", .{});
        return;
    };
    defer file.close();
    const data = file.readToEndAlloc(allocator, 128 * 1024) catch {
        try out.print("Failed to read config.\n", .{});
        return;
    };
    defer allocator.free(data);

    var issues: usize = 0;
    var line_no: usize = 0;
    var lines = std.mem.splitScalar(u8, data, '\n');
    while (lines.next()) |raw_line| {
        line_no += 1;
        const line = std.mem.trim(u8, raw_line, " \t\r");
        if (line.len == 0) continue;
        if (line[0] == '#' or line[0] == ';') continue;
        const eq = std.mem.indexOfScalar(u8, line, '=') orelse {
            issues += 1;
            try out.print("line {d}: invalid syntax (missing '=')\n", .{line_no});
            continue;
        };
        const key = std.mem.trim(u8, line[0..eq], " \t\r");
        const value = std.mem.trim(u8, line[eq + 1 ..], " \t\r");
        if (key.len == 0 or value.len == 0) {
            issues += 1;
            try out.print("line {d}: empty key/value\n", .{line_no});
            continue;
        }
        const result = applyKV(cfg, key, value);
        switch (result) {
            .ok => {},
            .unknown => {
                issues += 1;
                try out.print("line {d}: unknown key '{s}'\n", .{ line_no, key });
            },
            .invalid => {
                issues += 1;
                try out.print("line {d}: invalid value for '{s}'\n", .{ line_no, key });
            },
        }
    }
    try out.print("Doctor issues: {d}\n", .{issues});
}

fn makeDirPath(path: []const u8) void {
    if (path.len == 0) return;
    if (std.fs.path.isAbsolute(path)) {
        std.fs.makeDirAbsolute(path) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => {},
        };
    } else {
        std.fs.cwd().makePath(path) catch {};
    }
}

fn ensureParentDir(path: []const u8) void {
    const parent = std.fs.path.dirname(path) orelse return;
    if (std.fs.path.isAbsolute(parent)) {
        // Best-effort for common "~/.config/zigfetch" path depth.
        var it = std.mem.splitScalar(u8, parent, '/');
        var acc: [std.fs.max_path_bytes]u8 = undefined;
        var len: usize = 0;
        if (parent.len > 0 and parent[0] == '/') {
            acc[0] = '/';
            len = 1;
        }
        while (it.next()) |part| {
            if (part.len == 0) continue;
            if (len > 1 and acc[len - 1] != '/') {
                acc[len] = '/';
                len += 1;
            }
            if (len + part.len >= acc.len) break;
            @memcpy(acc[len .. len + part.len], part);
            len += part.len;
            makeDirPath(acc[0..len]);
        }
    } else {
        std.fs.cwd().makePath(parent) catch {};
    }
}

pub fn resolveConfigPath(allocator: std.mem.Allocator) ?[]u8 {
    if (std.posix.getenv("ZIGFETCH_CONFIG")) |custom_path| return allocator.dupe(u8, custom_path) catch null;
    const home = std.posix.getenv("HOME") orelse return null;
    return std.fmt.allocPrint(allocator, "{s}/.config/zigfetch/config.conf", .{home}) catch null;
}

fn ensureDefaultConfigFile(path: []const u8) void {
    ensureParentDir(path);
    const file = std.fs.createFileAbsolute(path, .{ .exclusive = true }) catch |err| switch (err) {
        error.PathAlreadyExists => return,
        else => return,
    };
    defer file.close();
    file.writeAll(default_config_contents) catch {};
}

pub fn initConfigFile(allocator: std.mem.Allocator, force: bool) ?[]u8 {
    const path = resolveConfigPath(allocator) orelse return null;
    ensureParentDir(path);
    const file = std.fs.createFileAbsolute(path, .{ .truncate = force, .exclusive = !force }) catch |err| switch (err) {
        error.PathAlreadyExists => return path,
        else => return null,
    };
    defer file.close();
    file.writeAll(default_config_contents) catch {};
    return path;
}

pub fn doctorConfig(allocator: std.mem.Allocator, out: anytype) !void {
    const path = resolveConfigPath(allocator) orelse {
        try out.print("No config path could be resolved.\n", .{});
        return;
    };
    defer allocator.free(path);
    try out.print("Config path: {s}\n", .{path});

    var cfg = defaults();
    try doctorFromPath(allocator, out, path, &cfg);

    try out.print("Doctor finished. Effective preset={s}, style={s}, icon={s}, modules={d}\n", .{
        @tagName(cfg.preset),
        @tagName(cfg.border),
        @tagName(cfg.icon_mode),
        cfg.module_count,
    });
}

pub fn load(allocator: std.mem.Allocator) Config {
    var cfg = defaults();
    const path = resolveConfigPath(allocator) orelse return cfg;
    defer allocator.free(path);

    if (std.posix.getenv("ZIGFETCH_CONFIG") == null) ensureDefaultConfigFile(path);
    loadFromPath(allocator, &cfg, path);
    return cfg;
}
