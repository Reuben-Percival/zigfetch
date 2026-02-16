const std = @import("std");
<<<<<<< Updated upstream
const sysinfo = @import("sysinfo.zig");
const icon = @import("icon.zig");
const render = @import("render.zig");
const config = @import("config.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const stdout = std.fs.File.stdout().deprecatedWriter();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len > 1) {
        if (std.mem.eql(u8, args[1], "--help") or std.mem.eql(u8, args[1], "-h")) {
            try stdout.print(
                \\zigfetch
                \\  --help            Show this help
                \\  --init-config     Create config file if missing
                \\  --init-config --force  Overwrite config file with defaults
                \\  --doctor-config   Validate config keys and values
                \\
                ,
                .{},
            );
            return;
        }
        if (std.mem.eql(u8, args[1], "--init-config")) {
            const force = args.len > 2 and std.mem.eql(u8, args[2], "--force");
            const path = config.initConfigFile(allocator, force) orelse {
                try stdout.print("Failed to initialize config.\n", .{});
                return;
            };
            defer allocator.free(path);
            try stdout.print("Config initialized at: {s}\n", .{path});
            return;
        }
        if (std.mem.eql(u8, args[1], "--doctor-config")) {
            try config.doctorConfig(allocator, stdout);
            return;
        }
    }

    const cfg = config.load(allocator);

    var snapshot = try sysinfo.collect(allocator);
    defer snapshot.deinit(allocator);

    const icon_path = try icon.findRealDistroIconPath(
        allocator,
        snapshot.distro_id,
        snapshot.distro_logo,
        snapshot.distro_id_like,
    );
    defer if (icon_path) |p| allocator.free(p);

    const right_icon_block = if (icon_path != null)
        icon.getRightSideIconBlock(allocator, icon_path.?, cfg) catch null
    else
        null;
    defer if (right_icon_block) |b| allocator.free(b);

    var printed_real_icon = false;
    if (right_icon_block == null) {
        if (icon_path) |p| {
            printed_real_icon = icon.renderIconAutoWithConfig(allocator, p, cfg) catch false;
            if (printed_real_icon) try stdout.print("\n", .{});
        }
    }

    try render.print(stdout, snapshot, if (printed_real_icon) null else icon_path, right_icon_block, cfg);
=======

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

fn parseOsPrettyName(os_release: []const u8) ?[]const u8 {
    var lines = std.mem.splitScalar(u8, os_release, '\n');
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, "PRETTY_NAME=")) continue;

        var value = line[12..];
        value = std.mem.trim(u8, value, " \t\r");

        if (value.len >= 2 and value[0] == '"' and value[value.len - 1] == '"') {
            return value[1 .. value.len - 1];
        }
        return value;
    }
    return null;
}

fn readHostname(allocator: std.mem.Allocator) ![]u8 {
    const data = try readFileAlloc(allocator, "/proc/sys/kernel/hostname");
    return allocator.dupe(u8, firstLineOrFallback(data, "unknown"));
}

fn readKernel(allocator: std.mem.Allocator) ![]u8 {
    const data = try readFileAlloc(allocator, "/proc/sys/kernel/osrelease");
    return allocator.dupe(u8, firstLineOrFallback(data, "unknown"));
}

fn readUptime(allocator: std.mem.Allocator) ![]u8 {
    const text = try readFileAlloc(allocator, "/proc/uptime");
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
    const mib: u64 = 1024;
    return std.fmt.allocPrint(allocator, "{d} MiB / {d} MiB", .{ used_kb / mib, total_kb / mib });
}

fn readCpuModel(allocator: std.mem.Allocator) ![]u8 {
    const text = try readFileAlloc(allocator, "/proc/cpuinfo");
    var lines = std.mem.splitScalar(u8, text, '\n');

    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, "model name")) continue;
        const colon = std.mem.indexOfScalar(u8, line, ':') orelse continue;
        const value = std.mem.trim(u8, line[colon + 1 ..], " \t\r");
        if (value.len > 0) return allocator.dupe(u8, value);
    }

    return allocator.dupe(u8, "unknown");
}

fn readOsName(allocator: std.mem.Allocator) ![]u8 {
    const os_release = try readFileAlloc(allocator, "/etc/os-release");
    if (parseOsPrettyName(os_release)) |name| {
        return allocator.dupe(u8, name);
    }
    return allocator.dupe(u8, "Linux");
}

fn safeRead(allocator: std.mem.Allocator, f: anytype) []const u8 {
    return f(allocator) catch "unknown";
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const stdout = std.fs.File.stdout().deprecatedWriter();

    const user = std.posix.getenv("USER") orelse "unknown";
    const host = safeRead(allocator, readHostname);
    const os_name = safeRead(allocator, readOsName);
    const kernel = safeRead(allocator, readKernel);
    const uptime = safeRead(allocator, readUptime);
    const memory = safeRead(allocator, readMemInfo);
    const cpu = safeRead(allocator, readCpuModel);

    try stdout.print("\n", .{});
    try stdout.print("  {s}@{s}\n", .{ user, host });
    try stdout.print("  -------------------------\n", .{});
    try stdout.print("  OS:      {s}\n", .{ os_name });
    try stdout.print("  Kernel:  {s}\n", .{ kernel });
    try stdout.print("  Uptime:  {s}\n", .{ uptime });
    try stdout.print("  CPU:     {s}\n", .{ cpu });
    try stdout.print("  Memory:  {s}\n", .{ memory });
    try stdout.print("\n", .{});
>>>>>>> Stashed changes
}
