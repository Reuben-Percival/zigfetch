const std = @import("std");
const sysinfo = @import("sysinfo.zig");
const icon = @import("icon.zig");
const render = @import("render.zig");
const config = @import("config.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const stdout = std.fs.File.stdout().deprecatedWriter();
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
