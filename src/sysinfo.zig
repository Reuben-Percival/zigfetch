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
    cpu: []u8,
    memory: []u8,
    shell: []u8,
    terminal: []u8,
    desktop: []u8,
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
        allocator.free(self.cpu);
        allocator.free(self.memory);
        allocator.free(self.shell);
        allocator.free(self.terminal);
        allocator.free(self.desktop);
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

fn baseName(path: []const u8) []const u8 {
    return std.fs.path.basename(path);
}

pub fn collect(allocator: std.mem.Allocator) !Snapshot {
    var os: os_release.OsRelease = os_release.read(allocator) catch .{
        .pretty_name = try allocator.dupe(u8, "Linux"),
        .id = try allocator.dupe(u8, "linux"),
        .id_like = null,
        .logo = null,
    };
    defer os.deinit(allocator);

    return .{
        .user = try allocator.dupe(u8, std.posix.getenv("USER") orelse "unknown"),
        .host = readHostname(allocator) catch try allocator.dupe(u8, "unknown"),
        .os_name = try allocator.dupe(u8, os.pretty_name),
        .arch = try allocator.dupe(u8, @tagName(builtin.cpu.arch)),
        .kernel = readKernel(allocator) catch try allocator.dupe(u8, "unknown"),
        .uptime = readUptime(allocator) catch try allocator.dupe(u8, "unknown"),
        .cpu = readCpuModel(allocator) catch try allocator.dupe(u8, "unknown"),
        .memory = readMemInfo(allocator) catch try allocator.dupe(u8, "unknown"),
        .shell = try allocator.dupe(u8, baseName(std.posix.getenv("SHELL") orelse "unknown")),
        .terminal = try allocator.dupe(u8, std.posix.getenv("TERM_PROGRAM") orelse (std.posix.getenv("TERM") orelse "unknown")),
        .desktop = try allocator.dupe(u8, std.posix.getenv("XDG_CURRENT_DESKTOP") orelse (std.posix.getenv("DESKTOP_SESSION") orelse "tty")),
        .distro_id = try allocator.dupe(u8, os.id),
        .distro_logo = if (os.logo) |v| try allocator.dupe(u8, v) else null,
        .distro_id_like = if (os.id_like) |v| try allocator.dupe(u8, v) else null,
    };
}
