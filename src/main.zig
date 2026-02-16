const std = @import("std");
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

    const icon_rendered = if (icon_path) |p|
        icon.renderIconAutoWithConfig(allocator, p, cfg) catch false
    else
        false;

    try render.print(stdout, snapshot, icon_path, icon_rendered, cfg);
}
