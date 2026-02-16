const std = @import("std");
const builtin = @import("builtin");
const os_release = @import("os_release.zig");

pub const Snapshot = struct {
    user: []u8,
    host: []u8,
    os_name: []u8,
    arch: []u8,
    kernel: []u8,
    uptime: []u8,
    host_model: []u8,
    bios: []u8,
    motherboard: []u8,
    cpu: []u8,
    cpu_cores: []u8,
    cpu_threads: []u8,
    cpu_freq: []u8,
    cpu_temp: []u8,
    gpu: []u8,
    gpu_driver: []u8,
    resolution: []u8,
    memory: []u8,
    swap: []u8,
    disk: []u8,
    battery: []u8,
    load: []u8,
    processes: []u8,
    network: []u8,
    audio: []u8,
    packages: []u8,
    shell: []u8,
    terminal: []u8,
    desktop: []u8,
    session: []u8,
    wm: []u8,
    distro_id: []u8,
    distro_logo: ?[]u8,
    distro_id_like: ?[]u8,

    pub fn deinit(self: *Snapshot, allocator: std.mem.Allocator) void {
        allocator.free(self.user);
        allocator.free(self.host);
        allocator.free(self.os_name);
        allocator.free(self.arch);
        allocator.free(self.kernel);
        allocator.free(self.uptime);
        allocator.free(self.host_model);
        allocator.free(self.bios);
        allocator.free(self.motherboard);
        allocator.free(self.cpu);
        allocator.free(self.cpu_cores);
        allocator.free(self.cpu_threads);
        allocator.free(self.cpu_freq);
        allocator.free(self.cpu_temp);
        allocator.free(self.gpu);
        allocator.free(self.gpu_driver);
        allocator.free(self.resolution);
        allocator.free(self.memory);
        allocator.free(self.swap);
        allocator.free(self.disk);
        allocator.free(self.battery);
        allocator.free(self.load);
        allocator.free(self.processes);
        allocator.free(self.network);
        allocator.free(self.audio);
        allocator.free(self.packages);
        allocator.free(self.shell);
        allocator.free(self.terminal);
        allocator.free(self.desktop);
        allocator.free(self.session);
        allocator.free(self.wm);
        allocator.free(self.distro_id);
        if (self.distro_logo) |v| allocator.free(v);
        if (self.distro_id_like) |v| allocator.free(v);
    }
};

fn readFileAlloc(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const file = try std.fs.openFileAbsolute(path, .{});
    defer file.close();
    return file.readToEndAlloc(allocator, 64 * 1024);
}

fn firstLineOrFallback(text: []const u8, fallback: []const u8) []const u8 {
    var it = std.mem.splitScalar(u8, text, '\n');
    const first = it.next() orelse return fallback;
    const trimmed = std.mem.trim(u8, first, " \t\r");
    if (trimmed.len == 0) return fallback;
    return trimmed;
}

fn readHostname(allocator: std.mem.Allocator) ![]u8 {
    const data = try readFileAlloc(allocator, "/proc/sys/kernel/hostname");
    defer allocator.free(data);
    return allocator.dupe(u8, firstLineOrFallback(data, "unknown"));
}

fn readKernel(allocator: std.mem.Allocator) ![]u8 {
    const data = try readFileAlloc(allocator, "/proc/sys/kernel/osrelease");
    defer allocator.free(data);
    return allocator.dupe(u8, firstLineOrFallback(data, "unknown"));
}

fn readUptime(allocator: std.mem.Allocator) ![]u8 {
    const text = try readFileAlloc(allocator, "/proc/uptime");
    defer allocator.free(text);
    const line = firstLineOrFallback(text, "0");
    const space = std.mem.indexOfScalar(u8, line, ' ') orelse line.len;
    const first = line[0..space];

    const dot = std.mem.indexOfScalar(u8, first, '.') orelse first.len;
    const integer_part = first[0..dot];

    const total_seconds = std.fmt.parseUnsigned(u64, integer_part, 10) catch 0;
    const days = total_seconds / 86400;
    const hours = (total_seconds % 86400) / 3600;
    const mins = (total_seconds % 3600) / 60;
    return std.fmt.allocPrint(allocator, "{d}d {d}h {d}m", .{ days, hours, mins });
}

fn readMemInfo(allocator: std.mem.Allocator) ![]u8 {
    const text = try readFileAlloc(allocator, "/proc/meminfo");
    defer allocator.free(text);

    var total_kb: u64 = 0;
    var avail_kb: u64 = 0;
    var lines = std.mem.splitScalar(u8, text, '\n');

    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "MemTotal:")) {
            var tok = std.mem.tokenizeAny(u8, line, " \t");
            _ = tok.next();
            if (tok.next()) |n| total_kb = std.fmt.parseUnsigned(u64, n, 10) catch 0;
        } else if (std.mem.startsWith(u8, line, "MemAvailable:")) {
            var tok2 = std.mem.tokenizeAny(u8, line, " \t");
            _ = tok2.next();
            if (tok2.next()) |n2| avail_kb = std.fmt.parseUnsigned(u64, n2, 10) catch 0;
        }
    }

    const used_kb: u64 = if (total_kb > avail_kb) total_kb - avail_kb else 0;
    return std.fmt.allocPrint(allocator, "{d} MiB / {d} MiB", .{ used_kb / 1024, total_kb / 1024 });
}

fn readCpuModel(allocator: std.mem.Allocator) ![]u8 {
    const text = try readFileAlloc(allocator, "/proc/cpuinfo");
    defer allocator.free(text);
    var lines = std.mem.splitScalar(u8, text, '\n');

    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, "model name")) continue;
        const colon = std.mem.indexOfScalar(u8, line, ':') orelse continue;
        const value = std.mem.trim(u8, line[colon + 1 ..], " \t\r");
        if (value.len > 0) return allocator.dupe(u8, value);
    }

    return allocator.dupe(u8, "unknown");
}

const CpuTopology = struct { cores: []u8, threads: []u8 };

fn readCpuTopology(allocator: std.mem.Allocator) !CpuTopology {
    const text = try readFileAlloc(allocator, "/proc/cpuinfo");
    defer allocator.free(text);
    var lines = std.mem.splitScalar(u8, text, '\n');
    var threads: u32 = 0;
    var cores_per_socket: u32 = 0;
    var sockets_seen: [64]bool = [_]bool{false} ** 64;
    var sockets: u32 = 0;

    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "processor")) {
            threads += 1;
            continue;
        }
        if (std.mem.startsWith(u8, line, "cpu cores")) {
            const colon = std.mem.indexOfScalar(u8, line, ':') orelse continue;
            const v = std.mem.trim(u8, line[colon + 1 ..], " \t\r");
            if (cores_per_socket == 0) cores_per_socket = std.fmt.parseUnsigned(u32, v, 10) catch 0;
            continue;
        }
        if (std.mem.startsWith(u8, line, "physical id")) {
            const colon = std.mem.indexOfScalar(u8, line, ':') orelse continue;
            const v = std.mem.trim(u8, line[colon + 1 ..], " \t\r");
            const id = std.fmt.parseUnsigned(u8, v, 10) catch continue;
            if (id < sockets_seen.len and !sockets_seen[id]) {
                sockets_seen[id] = true;
                sockets += 1;
            }
        }
    }

    const cores_count: u32 = if (cores_per_socket > 0 and sockets > 0)
        cores_per_socket * sockets
    else if (cores_per_socket > 0)
        cores_per_socket
    else
        threads;

    return .{
        .cores = try std.fmt.allocPrint(allocator, "{d}", .{cores_count}),
        .threads = try std.fmt.allocPrint(allocator, "{d}", .{threads}),
    };
}

fn readCommandOutput(allocator: std.mem.Allocator, argv: []const []const u8) ?[]u8 {
    var child = std.process.Child.init(argv, allocator);
    child.stdin_behavior = .Ignore;
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Ignore;

    child.spawn() catch |err| switch (err) {
        error.FileNotFound => return null,
        else => return null,
    };
    const out_file = child.stdout orelse {
        _ = child.wait() catch {};
        return null;
    };
    const out = out_file.readToEndAlloc(allocator, 128 * 1024) catch {
        _ = child.wait() catch {};
        return null;
    };
    const term = child.wait() catch {
        allocator.free(out);
        return null;
    };
    return switch (term) {
        .Exited => |code| if (code == 0) out else blk: {
            allocator.free(out);
            break :blk null;
        },
        else => blk: {
            allocator.free(out);
            break :blk null;
        },
    };
}

fn detectGpu(allocator: std.mem.Allocator) ![]u8 {
    if (readCommandOutput(allocator, &[_][]const u8{ "lspci" })) |raw| {
        defer allocator.free(raw);
        var joined: std.ArrayList(u8) = .{};
        defer joined.deinit(allocator);
        var lines = std.mem.splitScalar(u8, raw, '\n');
        var found: usize = 0;
        while (lines.next()) |line| {
            var value: ?[]const u8 = null;
            if (std.mem.indexOf(u8, line, " VGA compatible controller: ")) |idx| {
                value = std.mem.trim(u8, line[idx + 27 ..], " \t\r");
            } else if (std.mem.indexOf(u8, line, " 3D controller: ")) |idx2| {
                value = std.mem.trim(u8, line[idx2 + 16 ..], " \t\r");
            } else if (std.mem.indexOf(u8, line, " Display controller: ")) |idx3| {
                value = std.mem.trim(u8, line[idx3 + 21 ..], " \t\r");
            }
            if (value) |gpu_name| {
                const clean = sanitizeGpuName(gpu_name);
                if (clean.len == 0) continue;
                if (found > 0) try joined.appendSlice(allocator, " | ");
                try joined.appendSlice(allocator, clean);
                found += 1;
            }
        }
        if (found > 0) return joined.toOwnedSlice(allocator);
    }

    const drm = detectGpuFromDrm(allocator) catch null;
    if (drm) |v| return v;
    return allocator.dupe(u8, "unknown");
}

fn sanitizeGpuName(name: []const u8) []const u8 {
    const trimmed = std.mem.trim(u8, name, " \t\r");
    if (std.mem.indexOf(u8, trimmed, " (rev ")) |rev_idx| return trimmed[0..rev_idx];
    return trimmed;
}

fn parseHexId(raw: []const u8) ?u16 {
    var value = std.mem.trim(u8, raw, " \t\r\n");
    if (std.mem.startsWith(u8, value, "0x")) value = value[2..];
    if (value.len == 0) return null;
    return std.fmt.parseUnsigned(u16, value, 16) catch null;
}

fn gpuVendorName(vendor_id: u16) []const u8 {
    return switch (vendor_id) {
        0x10de => "NVIDIA",
        0x1002, 0x1022 => "AMD",
        0x8086 => "Intel",
        0x13b5 => "ARM",
        0x5143 => "Qualcomm",
        else => "GPU",
    };
}

fn detectGpuFromDrm(allocator: std.mem.Allocator) !?[]u8 {
    var drm_dir = std.fs.openDirAbsolute("/sys/class/drm", .{ .iterate = true }) catch return null;
    defer drm_dir.close();

    var out: std.ArrayList(u8) = .{};
    defer out.deinit(allocator);
    var found: usize = 0;
    var it = drm_dir.iterate();
    while (try it.next()) |entry| {
        if (entry.kind != .directory) continue;
        if (!std.mem.startsWith(u8, entry.name, "card")) continue;
        if (std.mem.indexOfScalar(u8, entry.name, '-')) |_| continue;

        var vendor_path_buf: [std.fs.max_path_bytes]u8 = undefined;
        const vendor_path = std.fmt.bufPrint(&vendor_path_buf, "/sys/class/drm/{s}/device/vendor", .{entry.name}) catch continue;
        const vendor_raw = readFileAlloc(allocator, vendor_path) catch continue;
        defer allocator.free(vendor_raw);
        const vendor_id = parseHexId(vendor_raw) orelse continue;

        var device_path_buf: [std.fs.max_path_bytes]u8 = undefined;
        const device_path = std.fmt.bufPrint(&device_path_buf, "/sys/class/drm/{s}/device/device", .{entry.name}) catch continue;
        const device_raw = readFileAlloc(allocator, device_path) catch continue;
        defer allocator.free(device_raw);
        const device_id = parseHexId(device_raw) orelse 0;

        if (found > 0) try out.appendSlice(allocator, " | ");
        const label = try std.fmt.allocPrint(allocator, "{s} ({x:0>4}:{x:0>4})", .{ gpuVendorName(vendor_id), vendor_id, device_id });
        defer allocator.free(label);
        try out.appendSlice(allocator, label);
        found += 1;
    }
    if (found == 0) return null;
    const owned = try out.toOwnedSlice(allocator);
    return owned;
}

fn baseName(path: []const u8) []const u8 {
    return std.fs.path.basename(path);
}

fn countDirEntries(path: []const u8) u64 {
    var dir = std.fs.openDirAbsolute(path, .{ .iterate = true }) catch return 0;
    defer dir.close();
    var it = dir.iterate();
    var n: u64 = 0;
    while (it.next() catch null) |entry| {
        if (entry.kind == .directory or entry.kind == .file) n += 1;
    }
    return n;
}

fn detectPackageCount(allocator: std.mem.Allocator) ![]u8 {
    const pacman = countDirEntries("/var/lib/pacman/local");
    if (pacman > 0) return std.fmt.allocPrint(allocator, "{d} (pacman)", .{pacman});

    const dpkg = countDirEntries("/var/lib/dpkg/info");
    if (dpkg > 0) return std.fmt.allocPrint(allocator, "{d} (dpkg)", .{dpkg});

    const rpm = countDirEntries("/var/lib/rpm");
    if (rpm > 0) return std.fmt.allocPrint(allocator, "{d}+ (rpm db entries)", .{rpm});

    const apk = countDirEntries("/lib/apk/db");
    if (apk > 0) return std.fmt.allocPrint(allocator, "{d}+ (apk db entries)", .{apk});

    return allocator.dupe(u8, "unknown");
}

fn detectSession(allocator: std.mem.Allocator) ![]u8 {
    if (std.posix.getenv("XDG_SESSION_TYPE")) |s| return allocator.dupe(u8, s);
    if (std.posix.getenv("WAYLAND_DISPLAY") != null) return allocator.dupe(u8, "wayland");
    if (std.posix.getenv("DISPLAY") != null) return allocator.dupe(u8, "x11");
    return allocator.dupe(u8, "tty");
}

fn detectWm(allocator: std.mem.Allocator) ![]u8 {
    if (std.posix.getenv("XDG_CURRENT_DESKTOP")) |s| return allocator.dupe(u8, s);
    if (std.posix.getenv("SWAYSOCK") != null) return allocator.dupe(u8, "sway");
    if (std.posix.getenv("HYPRLAND_INSTANCE_SIGNATURE") != null) return allocator.dupe(u8, "hyprland");
    return allocator.dupe(u8, "unknown");
}

fn readTrimmedFile(allocator: std.mem.Allocator, path: []const u8) ?[]u8 {
    const raw = readFileAlloc(allocator, path) catch return null;
    defer allocator.free(raw);
    const v = std.mem.trim(u8, firstLineOrFallback(raw, ""), " \t\r");
    if (v.len == 0) return null;
    return allocator.dupe(u8, v) catch null;
}

fn dmiValue(allocator: std.mem.Allocator, field: []const u8) ?[]u8 {
    var path_buf: [std.fs.max_path_bytes]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buf, "/sys/devices/virtual/dmi/id/{s}", .{field}) catch return null;
    return readTrimmedFile(allocator, path);
}

fn detectHostModel(allocator: std.mem.Allocator) ![]u8 {
    const product = dmiValue(allocator, "product_name");
    defer if (product) |v| allocator.free(v);
    const vendor = dmiValue(allocator, "sys_vendor");
    defer if (vendor) |v| allocator.free(v);
    if (product) |p| {
        if (vendor) |v| {
            if (std.mem.eql(u8, p, v)) return allocator.dupe(u8, p);
            return std.fmt.allocPrint(allocator, "{s} {s}", .{ v, p });
        }
        return allocator.dupe(u8, p);
    }
    return allocator.dupe(u8, "unknown");
}

fn detectBios(allocator: std.mem.Allocator) ![]u8 {
    const vendor = dmiValue(allocator, "bios_vendor");
    defer if (vendor) |v| allocator.free(v);
    const ver = dmiValue(allocator, "bios_version");
    defer if (ver) |v| allocator.free(v);
    if (vendor != null and ver != null) return std.fmt.allocPrint(allocator, "{s} {s}", .{ vendor.?, ver.? });
    if (vendor) |v| return allocator.dupe(u8, v);
    if (ver) |v| return allocator.dupe(u8, v);
    return allocator.dupe(u8, "unknown");
}

fn detectMotherboard(allocator: std.mem.Allocator) ![]u8 {
    const vendor = dmiValue(allocator, "board_vendor");
    defer if (vendor) |v| allocator.free(v);
    const name = dmiValue(allocator, "board_name");
    defer if (name) |v| allocator.free(v);
    if (vendor != null and name != null) return std.fmt.allocPrint(allocator, "{s} {s}", .{ vendor.?, name.? });
    if (name) |v| return allocator.dupe(u8, v);
    if (vendor) |v| return allocator.dupe(u8, v);
    return allocator.dupe(u8, "unknown");
}

fn detectGpuDriver(allocator: std.mem.Allocator) ![]u8 {
    var drm_dir = std.fs.openDirAbsolute("/sys/class/drm", .{ .iterate = true }) catch return allocator.dupe(u8, "unknown");
    defer drm_dir.close();
    var out: std.ArrayList(u8) = .{};
    defer out.deinit(allocator);
    var found: usize = 0;
    var it = drm_dir.iterate();
    while (try it.next()) |entry| {
        if (entry.kind != .directory) continue;
        if (!std.mem.startsWith(u8, entry.name, "card")) continue;
        if (std.mem.indexOfScalar(u8, entry.name, '-')) |_| continue;

        var link_path_buf: [std.fs.max_path_bytes]u8 = undefined;
        const link_path = std.fmt.bufPrint(&link_path_buf, "/sys/class/drm/{s}/device/driver", .{entry.name}) catch continue;
        var target_buf: [std.fs.max_path_bytes]u8 = undefined;
        const link = std.fs.readLinkAbsolute(link_path, &target_buf) catch continue;
        const driver = std.fs.path.basename(link);
        if (driver.len == 0) continue;
        if (found > 0) try out.appendSlice(allocator, " | ");
        try out.appendSlice(allocator, driver);
        found += 1;
    }
    if (found == 0) return allocator.dupe(u8, "unknown");
    return out.toOwnedSlice(allocator);
}

fn detectResolutionFromXrandr(allocator: std.mem.Allocator) ?[]u8 {
    const raw = readCommandOutput(allocator, &[_][]const u8{ "xrandr", "--current" }) orelse return null;
    defer allocator.free(raw);
    var lines = std.mem.splitScalar(u8, raw, '\n');
    while (lines.next()) |line| {
        if (std.mem.indexOf(u8, line, " connected ") == null) continue;
        var tok = std.mem.tokenizeAny(u8, line, " \t");
        _ = tok.next();
        _ = tok.next();
        while (tok.next()) |t| {
            if (std.mem.indexOfScalar(u8, t, 'x') == null) continue;
            const plus = std.mem.indexOfScalar(u8, t, '+') orelse t.len;
            if (plus == 0) continue;
            return allocator.dupe(u8, t[0..plus]) catch null;
        }
    }
    return null;
}

fn detectResolutionFromDrm(allocator: std.mem.Allocator) ?[]u8 {
    var drm_dir = std.fs.openDirAbsolute("/sys/class/drm", .{ .iterate = true }) catch return null;
    defer drm_dir.close();
    var it = drm_dir.iterate();
    while ((it.next() catch null)) |entry| {
        if (entry.kind != .directory) continue;
        if (!std.mem.startsWith(u8, entry.name, "card")) continue;
        if (std.mem.indexOfScalar(u8, entry.name, '-')) |_| {} else continue;

        var status_path_buf: [std.fs.max_path_bytes]u8 = undefined;
        const status_path = std.fmt.bufPrint(&status_path_buf, "/sys/class/drm/{s}/status", .{entry.name}) catch continue;
        const status = readTrimmedFile(allocator, status_path) orelse continue;
        defer allocator.free(status);
        if (!std.mem.eql(u8, status, "connected")) continue;

        var mode_path_buf: [std.fs.max_path_bytes]u8 = undefined;
        const mode_path = std.fmt.bufPrint(&mode_path_buf, "/sys/class/drm/{s}/modes", .{entry.name}) catch continue;
        const mode_raw = readFileAlloc(allocator, mode_path) catch continue;
        defer allocator.free(mode_raw);
        const mode = std.mem.trim(u8, firstLineOrFallback(mode_raw, ""), " \t\r");
        if (mode.len == 0) continue;
        return allocator.dupe(u8, mode) catch null;
    }
    return null;
}

fn detectResolution(allocator: std.mem.Allocator) ![]u8 {
    if (detectResolutionFromXrandr(allocator)) |v| return v;
    if (detectResolutionFromDrm(allocator)) |v| return v;
    return allocator.dupe(u8, "unknown");
}

fn detectDisk(allocator: std.mem.Allocator) ![]u8 {
    if (readCommandOutput(allocator, &[_][]const u8{ "df", "-h", "--output=used,size,pcent", "/" })) |raw| {
        defer allocator.free(raw);
        var lines = std.mem.splitScalar(u8, raw, '\n');
        _ = lines.next();
        const line = lines.next() orelse return allocator.dupe(u8, "unknown");
        var tok = std.mem.tokenizeAny(u8, line, " \t");
        const used = tok.next() orelse return allocator.dupe(u8, "unknown");
        const size = tok.next() orelse return allocator.dupe(u8, "unknown");
        const pct = tok.next() orelse return allocator.dupe(u8, "unknown");
        return std.fmt.allocPrint(allocator, "{s} / {s} ({s})", .{ used, size, pct });
    }
    return allocator.dupe(u8, "unknown");
}

fn detectSwap(allocator: std.mem.Allocator) ![]u8 {
    const text = readFileAlloc(allocator, "/proc/meminfo") catch return allocator.dupe(u8, "unknown");
    defer allocator.free(text);
    var total_kb: u64 = 0;
    var free_kb: u64 = 0;
    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "SwapTotal:")) {
            var tok = std.mem.tokenizeAny(u8, line, " \t");
            _ = tok.next();
            if (tok.next()) |n| total_kb = std.fmt.parseUnsigned(u64, n, 10) catch 0;
        } else if (std.mem.startsWith(u8, line, "SwapFree:")) {
            var tok2 = std.mem.tokenizeAny(u8, line, " \t");
            _ = tok2.next();
            if (tok2.next()) |n2| free_kb = std.fmt.parseUnsigned(u64, n2, 10) catch 0;
        }
    }
    if (total_kb == 0) return allocator.dupe(u8, "disabled");
    const used_kb = if (total_kb > free_kb) total_kb - free_kb else 0;
    return std.fmt.allocPrint(allocator, "{d} MiB / {d} MiB", .{ used_kb / 1024, total_kb / 1024 });
}

fn detectBattery(allocator: std.mem.Allocator) ![]u8 {
    var pwr_dir = std.fs.openDirAbsolute("/sys/class/power_supply", .{ .iterate = true }) catch return allocator.dupe(u8, "unknown");
    defer pwr_dir.close();
    var it = pwr_dir.iterate();
    while ((it.next() catch null)) |entry| {
        if (entry.kind != .directory) continue;
        if (!std.mem.startsWith(u8, entry.name, "BAT")) continue;

        var cap_path_buf: [std.fs.max_path_bytes]u8 = undefined;
        const cap_path = std.fmt.bufPrint(&cap_path_buf, "/sys/class/power_supply/{s}/capacity", .{entry.name}) catch continue;
        const cap = readTrimmedFile(allocator, cap_path) orelse continue;
        defer allocator.free(cap);

        var status_path_buf: [std.fs.max_path_bytes]u8 = undefined;
        const status_path = std.fmt.bufPrint(&status_path_buf, "/sys/class/power_supply/{s}/status", .{entry.name}) catch continue;
        const status = readTrimmedFile(allocator, status_path) orelse try allocator.dupe(u8, "Unknown");
        defer allocator.free(status);
        return std.fmt.allocPrint(allocator, "{s}% ({s})", .{ cap, status });
    }
    return allocator.dupe(u8, "not present");
}

fn detectCpuFreq(allocator: std.mem.Allocator) ![]u8 {
    const text = readFileAlloc(allocator, "/proc/cpuinfo") catch return allocator.dupe(u8, "unknown");
    defer allocator.free(text);
    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, "cpu MHz")) continue;
        const colon = std.mem.indexOfScalar(u8, line, ':') orelse continue;
        const value = std.mem.trim(u8, line[colon + 1 ..], " \t\r");
        const mhz = std.fmt.parseFloat(f64, value) catch continue;
        return std.fmt.allocPrint(allocator, "{d:.2} GHz", .{mhz / 1000.0});
    }
    return allocator.dupe(u8, "unknown");
}

fn detectCpuTemp(allocator: std.mem.Allocator) ![]u8 {
    var thermal_dir = std.fs.openDirAbsolute("/sys/class/thermal", .{ .iterate = true }) catch return allocator.dupe(u8, "unknown");
    defer thermal_dir.close();
    var it = thermal_dir.iterate();
    while ((it.next() catch null)) |entry| {
        if (entry.kind != .directory) continue;
        if (!std.mem.startsWith(u8, entry.name, "thermal_zone")) continue;

        var type_path_buf: [std.fs.max_path_bytes]u8 = undefined;
        const type_path = std.fmt.bufPrint(&type_path_buf, "/sys/class/thermal/{s}/type", .{entry.name}) catch continue;
        const zone_type = readTrimmedFile(allocator, type_path) orelse continue;
        defer allocator.free(zone_type);
        const likely_cpu = std.mem.indexOf(u8, zone_type, "cpu") != null or
            std.mem.indexOf(u8, zone_type, "x86_pkg_temp") != null or
            std.mem.indexOf(u8, zone_type, "package") != null;
        if (!likely_cpu) continue;

        var temp_path_buf: [std.fs.max_path_bytes]u8 = undefined;
        const temp_path = std.fmt.bufPrint(&temp_path_buf, "/sys/class/thermal/{s}/temp", .{entry.name}) catch continue;
        const temp_raw = readTrimmedFile(allocator, temp_path) orelse continue;
        defer allocator.free(temp_raw);
        const milli = std.fmt.parseInt(i64, temp_raw, 10) catch continue;
        return std.fmt.allocPrint(allocator, "{d:.1} C", .{@as(f64, @floatFromInt(milli)) / 1000.0});
    }
    return allocator.dupe(u8, "unknown");
}

fn detectLoad(allocator: std.mem.Allocator) ![]u8 {
    const raw = readFileAlloc(allocator, "/proc/loadavg") catch return allocator.dupe(u8, "unknown");
    defer allocator.free(raw);
    var tok = std.mem.tokenizeAny(u8, firstLineOrFallback(raw, ""), " \t");
    const l1 = tok.next() orelse return allocator.dupe(u8, "unknown");
    const l5 = tok.next() orelse return allocator.dupe(u8, "unknown");
    const l15 = tok.next() orelse return allocator.dupe(u8, "unknown");
    return std.fmt.allocPrint(allocator, "{s} {s} {s}", .{ l1, l5, l15 });
}

fn detectProcesses(allocator: std.mem.Allocator) ![]u8 {
    var proc = std.fs.openDirAbsolute("/proc", .{ .iterate = true }) catch return allocator.dupe(u8, "unknown");
    defer proc.close();
    var it = proc.iterate();
    var count: usize = 0;
    while ((it.next() catch null)) |entry| {
        if (entry.kind != .directory) continue;
        if (entry.name.len == 0) continue;
        if (std.ascii.isDigit(entry.name[0])) count += 1;
    }
    return std.fmt.allocPrint(allocator, "{d}", .{count});
}

fn defaultInterfaceFromRoute(allocator: std.mem.Allocator) ?[]u8 {
    const raw = readFileAlloc(allocator, "/proc/net/route") catch return null;
    defer allocator.free(raw);
    var lines = std.mem.splitScalar(u8, raw, '\n');
    _ = lines.next();
    while (lines.next()) |line| {
        var tok = std.mem.tokenizeAny(u8, line, " \t");
        const iface = tok.next() orelse continue;
        const dest = tok.next() orelse continue;
        _ = tok.next();
        const flags = tok.next() orelse continue;
        if (!std.mem.eql(u8, dest, "00000000")) continue;
        const flags_num = std.fmt.parseUnsigned(u32, flags, 16) catch 0;
        if ((flags_num & 0x2) == 0) continue;
        return allocator.dupe(u8, iface) catch null;
    }
    return null;
}

fn ifaceIPv4(allocator: std.mem.Allocator, iface: []const u8) ?[]u8 {
    const raw = readCommandOutput(allocator, &[_][]const u8{ "ip", "-4", "addr", "show", "dev", iface }) orelse return null;
    defer allocator.free(raw);
    var lines = std.mem.splitScalar(u8, raw, '\n');
    while (lines.next()) |line| {
        const t = std.mem.trim(u8, line, " \t\r");
        if (!std.mem.startsWith(u8, t, "inet ")) continue;
        var tok = std.mem.tokenizeAny(u8, t, " \t");
        _ = tok.next();
        const cidr = tok.next() orelse continue;
        const slash = std.mem.indexOfScalar(u8, cidr, '/') orelse cidr.len;
        return allocator.dupe(u8, cidr[0..slash]) catch null;
    }
    return null;
}

fn ifaceSpeed(allocator: std.mem.Allocator, iface: []const u8) ?[]u8 {
    var path_buf: [std.fs.max_path_bytes]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buf, "/sys/class/net/{s}/speed", .{iface}) catch return null;
    return readTrimmedFile(allocator, path);
}

fn detectNetwork(allocator: std.mem.Allocator) ![]u8 {
    const iface = defaultInterfaceFromRoute(allocator) orelse return allocator.dupe(u8, "offline");
    defer allocator.free(iface);
    const ip4 = ifaceIPv4(allocator, iface);
    defer if (ip4) |v| allocator.free(v);
    const speed = ifaceSpeed(allocator, iface);
    defer if (speed) |v| allocator.free(v);

    if (ip4 != null and speed != null) return std.fmt.allocPrint(allocator, "{s} {s} ({s} Mb/s)", .{ iface, ip4.?, speed.? });
    if (ip4 != null) return std.fmt.allocPrint(allocator, "{s} {s}", .{ iface, ip4.? });
    return allocator.dupe(u8, iface);
}

fn detectAudio(allocator: std.mem.Allocator) ![]u8 {
    if (readCommandOutput(allocator, &[_][]const u8{ "pactl", "get-default-sink" })) |raw| {
        defer allocator.free(raw);
        const v = std.mem.trim(u8, firstLineOrFallback(raw, ""), " \t\r");
        if (v.len > 0) return allocator.dupe(u8, v);
    }
    if (readCommandOutput(allocator, &[_][]const u8{ "wpctl", "status" })) |raw2| {
        defer allocator.free(raw2);
        var lines = std.mem.splitScalar(u8, raw2, '\n');
        while (lines.next()) |line| {
            const t = std.mem.trim(u8, line, " \t\r");
            if (!std.mem.startsWith(u8, t, "*")) continue;
            return allocator.dupe(u8, t[1..]) catch null;
        }
    }
    return allocator.dupe(u8, "unknown");
}

fn detectShell(allocator: std.mem.Allocator) ![]u8 {
    const self_pid = std.os.linux.getpid();
    if (self_pid <= 1) return allocator.dupe(u8, baseName(std.posix.getenv("SHELL") orelse "unknown"));
    var pid: u32 = @intCast(self_pid);
    var depth: usize = 0;
    while (depth < 16 and pid > 1) : (depth += 1) {
        const ppid = readPpidForPid(allocator, pid) catch break;
        if (ppid <= 1) break;
        pid = ppid;
        const comm = readCommForPid(allocator, pid) catch continue;
        defer allocator.free(comm);
        if (isKnownShell(comm)) return allocator.dupe(u8, comm);
    }
    return allocator.dupe(u8, baseName(std.posix.getenv("SHELL") orelse "unknown"));
}

fn isKnownShell(name: []const u8) bool {
    return std.mem.eql(u8, name, "bash") or
        std.mem.eql(u8, name, "fish") or
        std.mem.eql(u8, name, "zsh") or
        std.mem.eql(u8, name, "ksh") or
        std.mem.eql(u8, name, "dash") or
        std.mem.eql(u8, name, "sh") or
        std.mem.eql(u8, name, "nu") or
        std.mem.eql(u8, name, "pwsh");
}

fn readCommForPid(allocator: std.mem.Allocator, pid: u32) ![]u8 {
    var path_buf: [std.fs.max_path_bytes]u8 = undefined;
    const comm_path = try std.fmt.bufPrint(&path_buf, "/proc/{d}/comm", .{pid});
    const comm_raw = try readFileAlloc(allocator, comm_path);
    defer allocator.free(comm_raw);
    const comm = std.mem.trim(u8, firstLineOrFallback(comm_raw, "unknown"), " \t\r");
    if (comm.len == 0) return error.InvalidData;
    return allocator.dupe(u8, comm);
}

fn readPpidForPid(allocator: std.mem.Allocator, pid: u32) !u32 {
    var path_buf: [std.fs.max_path_bytes]u8 = undefined;
    const status_path = try std.fmt.bufPrint(&path_buf, "/proc/{d}/status", .{pid});
    const raw = try readFileAlloc(allocator, status_path);
    defer allocator.free(raw);
    var lines = std.mem.splitScalar(u8, raw, '\n');
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, "PPid:")) continue;
        var tok = std.mem.tokenizeAny(u8, line, " \t");
        _ = tok.next();
        const ppid_raw = tok.next() orelse return error.InvalidData;
        return std.fmt.parseUnsigned(u32, ppid_raw, 10);
    }
    return error.InvalidData;
}

pub fn collect(allocator: std.mem.Allocator) !Snapshot {
    var os: os_release.OsRelease = os_release.read(allocator) catch .{
        .pretty_name = try allocator.dupe(u8, "Linux"),
        .id = try allocator.dupe(u8, "linux"),
        .id_like = null,
        .logo = null,
    };
    defer os.deinit(allocator);
    const topo: CpuTopology = readCpuTopology(allocator) catch .{
        .cores = try allocator.dupe(u8, "unknown"),
        .threads = try allocator.dupe(u8, "unknown"),
    };

    return .{
        .user = try allocator.dupe(u8, std.posix.getenv("USER") orelse "unknown"),
        .host = readHostname(allocator) catch try allocator.dupe(u8, "unknown"),
        .os_name = try allocator.dupe(u8, os.pretty_name),
        .arch = try allocator.dupe(u8, @tagName(builtin.cpu.arch)),
        .kernel = readKernel(allocator) catch try allocator.dupe(u8, "unknown"),
        .uptime = readUptime(allocator) catch try allocator.dupe(u8, "unknown"),
        .host_model = detectHostModel(allocator) catch try allocator.dupe(u8, "unknown"),
        .bios = detectBios(allocator) catch try allocator.dupe(u8, "unknown"),
        .motherboard = detectMotherboard(allocator) catch try allocator.dupe(u8, "unknown"),
        .cpu = readCpuModel(allocator) catch try allocator.dupe(u8, "unknown"),
        .cpu_cores = topo.cores,
        .cpu_threads = topo.threads,
        .cpu_freq = detectCpuFreq(allocator) catch try allocator.dupe(u8, "unknown"),
        .cpu_temp = detectCpuTemp(allocator) catch try allocator.dupe(u8, "unknown"),
        .gpu = detectGpu(allocator) catch try allocator.dupe(u8, "unknown"),
        .gpu_driver = detectGpuDriver(allocator) catch try allocator.dupe(u8, "unknown"),
        .resolution = detectResolution(allocator) catch try allocator.dupe(u8, "unknown"),
        .memory = readMemInfo(allocator) catch try allocator.dupe(u8, "unknown"),
        .swap = detectSwap(allocator) catch try allocator.dupe(u8, "unknown"),
        .disk = detectDisk(allocator) catch try allocator.dupe(u8, "unknown"),
        .battery = detectBattery(allocator) catch try allocator.dupe(u8, "unknown"),
        .load = detectLoad(allocator) catch try allocator.dupe(u8, "unknown"),
        .processes = detectProcesses(allocator) catch try allocator.dupe(u8, "unknown"),
        .network = detectNetwork(allocator) catch try allocator.dupe(u8, "unknown"),
        .audio = detectAudio(allocator) catch try allocator.dupe(u8, "unknown"),
        .packages = detectPackageCount(allocator) catch try allocator.dupe(u8, "unknown"),
        .shell = detectShell(allocator) catch try allocator.dupe(u8, baseName(std.posix.getenv("SHELL") orelse "unknown")),
        .terminal = try allocator.dupe(u8, std.posix.getenv("TERM_PROGRAM") orelse (std.posix.getenv("TERM") orelse "unknown")),
        .desktop = try allocator.dupe(u8, std.posix.getenv("XDG_CURRENT_DESKTOP") orelse (std.posix.getenv("DESKTOP_SESSION") orelse "tty")),
        .session = detectSession(allocator) catch try allocator.dupe(u8, "unknown"),
        .wm = detectWm(allocator) catch try allocator.dupe(u8, "unknown"),
        .distro_id = try allocator.dupe(u8, os.id),
        .distro_logo = if (os.logo) |v| try allocator.dupe(u8, v) else null,
        .distro_id_like = if (os.id_like) |v| try allocator.dupe(u8, v) else null,
    };
}
