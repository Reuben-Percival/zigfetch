const std = @import("std");

pub const OsRelease = struct {
    pretty_name: []u8,
    id: []u8,
    id_like: ?[]u8,
    logo: ?[]u8,

    pub fn deinit(self: *OsRelease, allocator: std.mem.Allocator) void {
        allocator.free(self.pretty_name);
        allocator.free(self.id);
        if (self.id_like) |v| allocator.free(v);
        if (self.logo) |v| allocator.free(v);
    }
};

fn readFileAlloc(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const file = try std.fs.openFileAbsolute(path, .{});
    defer file.close();
    return file.readToEndAlloc(allocator, 128 * 1024);
}

fn trimAndUnquote(value: []const u8) []const u8 {
    const trimmed = std.mem.trim(u8, value, " \t\r");
    if (trimmed.len >= 2 and trimmed[0] == '"' and trimmed[trimmed.len - 1] == '"') {
        return trimmed[1 .. trimmed.len - 1];
    }
    return trimmed;
}

fn parseValue(os_release: []const u8, key: []const u8) ?[]const u8 {
    var lines = std.mem.splitScalar(u8, os_release, '\n');
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, key)) continue;
        if (line.len <= key.len or line[key.len] != '=') continue;
        return trimAndUnquote(line[key.len + 1 ..]);
    }
    return null;
}

pub fn read(allocator: std.mem.Allocator) !OsRelease {
    const data = try readFileAlloc(allocator, "/etc/os-release");
    defer allocator.free(data);

    const pretty = parseValue(data, "PRETTY_NAME") orelse "Linux";
    const id = parseValue(data, "ID") orelse "linux";
    const id_like = parseValue(data, "ID_LIKE");
    const logo = parseValue(data, "LOGO");

    return .{
        .pretty_name = try allocator.dupe(u8, pretty),
        .id = try allocator.dupe(u8, id),
        .id_like = if (id_like) |v| try allocator.dupe(u8, v) else null,
        .logo = if (logo) |v| try allocator.dupe(u8, v) else null,
    };
}
