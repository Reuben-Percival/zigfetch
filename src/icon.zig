const std = @import("std");
const config = @import("config.zig");

const search_roots = [_][]const u8{
    "/usr/share/icons",
    "/usr/share/pixmaps",
    "/usr/share/branding",
    "/usr/share/distribution-logos",
};

const exts = [_][]const u8{
    ".svg",
    ".png",
    ".xpm",
    ".jpg",
    ".jpeg",
    ".webp",
};

const rel_prefixes = [_][]const u8{
    "",
    "hicolor/scalable/apps/",
    "hicolor/128x128/apps/",
    "hicolor/64x64/apps/",
    "hicolor/48x48/apps/",
    "hicolor/32x32/apps/",
};

fn fileExists(path: []const u8) bool {
    const f = std.fs.openFileAbsolute(path, .{}) catch return false;
    f.close();
    return true;
}

fn appendIfMissing(names: *[32][]const u8, count: *usize, value: []const u8) !void {
    for (names[0..count.*]) |existing| {
        if (std.mem.eql(u8, existing, value)) return;
    }
    if (count.* >= names.len) return error.Overflow;
    names[count.*] = value;
    count.* += 1;
}

fn pushCandidateSet(
    allocator: std.mem.Allocator,
    names: *[32][]const u8,
    count: *usize,
    base: []const u8,
) !void {
    if (base.len == 0) return;
    try appendIfMissing(names, count, base);
    try appendIfMissing(names, count, try std.fmt.allocPrint(allocator, "{s}-logo", .{base}));
    try appendIfMissing(names, count, try std.fmt.allocPrint(allocator, "{s}-icon", .{base}));
}

fn addIdAliases(names: *[32][]const u8, count: *usize, distro_id: []const u8) !void {
    if (std.mem.eql(u8, distro_id, "arch")) {
        try appendIfMissing(names, count, "archlinux");
    } else if (std.mem.eql(u8, distro_id, "ubuntu")) {
        try appendIfMissing(names, count, "ubuntu");
    } else if (std.mem.eql(u8, distro_id, "debian")) {
        try appendIfMissing(names, count, "debian");
    } else if (std.mem.eql(u8, distro_id, "fedora")) {
        try appendIfMissing(names, count, "fedora");
    } else if (std.mem.eql(u8, distro_id, "nixos")) {
        try appendIfMissing(names, count, "nix-snowflake");
        try appendIfMissing(names, count, "nixos");
    } else if (std.mem.eql(u8, distro_id, "manjaro")) {
        try appendIfMissing(names, count, "manjaro");
    } else if (std.mem.eql(u8, distro_id, "linuxmint")) {
        try appendIfMissing(names, count, "mint");
    } else if (std.mem.eql(u8, distro_id, "alpine")) {
        try appendIfMissing(names, count, "alpine-linux");
    } else if (std.mem.eql(u8, distro_id, "gentoo")) {
        try appendIfMissing(names, count, "gentoo");
    } else if (std.mem.eql(u8, distro_id, "void")) {
        try appendIfMissing(names, count, "voidlinux");
    } else if (std.mem.eql(u8, distro_id, "kali")) {
        try appendIfMissing(names, count, "kalilinux");
    } else if (std.mem.eql(u8, distro_id, "endeavouros")) {
        try appendIfMissing(names, count, "endeavour");
    } else if (std.mem.eql(u8, distro_id, "opensuse-tumbleweed") or std.mem.eql(u8, distro_id, "opensuse-leap")) {
        try appendIfMissing(names, count, "opensuse");
    } else if (std.mem.eql(u8, distro_id, "rhel")) {
        try appendIfMissing(names, count, "redhat");
    } else if (std.mem.eql(u8, distro_id, "pop")) {
        try appendIfMissing(names, count, "pop-os");
    }
}

fn firstIdLike(id_like: ?[]const u8) ?[]const u8 {
    const raw = id_like orelse return null;
    var tok = std.mem.tokenizeAny(u8, raw, " \t\r");
    return tok.next();
}

pub fn findRealDistroIconPath(
    allocator: std.mem.Allocator,
    distro_id: []const u8,
    logo_key: ?[]const u8,
    id_like: ?[]const u8,
) !?[]u8 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    var names: [32][]const u8 = undefined;
    var names_count: usize = 0;

    if (logo_key) |v| try pushCandidateSet(a, &names, &names_count, v);
    try pushCandidateSet(a, &names, &names_count, distro_id);
    try addIdAliases(&names, &names_count, distro_id);
    if (firstIdLike(id_like)) |v| try pushCandidateSet(a, &names, &names_count, v);
    try appendIfMissing(&names, &names_count, "distributor-logo");

    for (search_roots) |root| {
        for (names[0..names_count]) |name| {
            for (rel_prefixes) |rel| {
                for (exts) |ext| {
                    const path = if (rel.len == 0)
                        try std.fmt.allocPrint(a, "{s}/{s}{s}", .{ root, name, ext })
                    else
                        try std.fmt.allocPrint(a, "{s}/{s}{s}{s}", .{ root, rel, name, ext });
                    if (fileExists(path)) {
                        const out = try allocator.dupe(u8, path);
                        return out;
                    }
                }
            }
        }
    }
    return null;
}

fn runRenderer(allocator: std.mem.Allocator, argv: []const []const u8) !bool {
    var child = std.process.Child.init(argv, allocator);
    child.stdin_behavior = .Ignore;
    child.stdout_behavior = .Inherit;
    child.stderr_behavior = .Ignore;

    const term = child.spawnAndWait() catch |err| switch (err) {
        error.FileNotFound => return false,
        else => return err,
    };

    return switch (term) {
        .Exited => |code| code == 0,
        else => false,
    };
}

fn stdoutLooksInteractive() bool {
    const posix = std.posix;
    if (!posix.isatty(posix.STDOUT_FILENO)) return false;
    const term = posix.getenv("TERM") orelse return false;
    if (std.mem.eql(u8, term, "dumb")) return false;
    return true;
}

fn inKitty() bool {
    const term = std.posix.getenv("TERM") orelse return false;
    return std.mem.indexOf(u8, term, "kitty") != null;
}

fn inWezTerm() bool {
    const tp = std.posix.getenv("TERM_PROGRAM") orelse return false;
    return std.mem.eql(u8, tp, "WezTerm");
}

pub fn renderIconAuto(allocator: std.mem.Allocator, icon_path: []const u8) !bool {
    return renderIconAutoWithConfig(allocator, icon_path, .{});
}

pub fn renderIconAutoWithConfig(
    allocator: std.mem.Allocator,
    icon_path: []const u8,
    cfg: config.Config,
) !bool {
    if (!cfg.show_icon) return false;
    if (std.posix.getenv("ZIGFETCH_NO_ICON")) |v| {
        if (std.mem.eql(u8, v, "1")) return false;
    }

    const env_force_icon = if (std.posix.getenv("ZIGFETCH_FORCE_ICON")) |v|
        std.mem.eql(u8, v, "1")
    else
        false;
    const force_icon = cfg.force_icon or env_force_icon;
    if (!force_icon and !stdoutLooksInteractive()) return false;

    const size = try std.fmt.allocPrint(allocator, "{d}x{d}", .{ cfg.chafa_width, cfg.chafa_height });
    defer allocator.free(size);
    if (try runRenderer(allocator, &[_][]const u8{ "chafa", "--size", size, icon_path })) return true;
    if (inWezTerm()) {
        const w = try std.fmt.allocPrint(allocator, "{d}", .{cfg.chafa_width});
        defer allocator.free(w);
        if (try runRenderer(allocator, &[_][]const u8{ "wezterm", "imgcat", "--width", w, icon_path })) return true;
    }
    if (inKitty()) {
        if (try runRenderer(allocator, &[_][]const u8{ "kitten", "icat", "--align", "left", icon_path })) return true;
        if (try runRenderer(allocator, &[_][]const u8{ "kitty", "+kitten", "icat", "--align", "left", icon_path })) return true;
    }
    return false;
}
