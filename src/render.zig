const std = @import("std");
const sysinfo = @import("sysinfo.zig");

pub fn print(
    stdout: anytype,
    snapshot: sysinfo.Snapshot,
    icon_path: ?[]const u8,
    icon_rendered: bool,
) !void {
    try stdout.print("\n", .{});

    if (!icon_rendered) {
        if (icon_path) |p| {
            try stdout.print("  Icon:    {s}\n", .{p});
            try stdout.print("  Note:    Install `chafa`, `wezterm`, or `kitty` image tools to render inline.\n\n", .{});
        }
    }

    try stdout.print("  {s}@{s}\n", .{ snapshot.user, snapshot.host });
    try stdout.print("  -------------------------\n", .{});
    try stdout.print("  OS:      {s}\n", .{snapshot.os_name});
    try stdout.print("  Arch:    {s}\n", .{snapshot.arch});
    try stdout.print("  Kernel:  {s}\n", .{snapshot.kernel});
    try stdout.print("  Uptime:  {s}\n", .{snapshot.uptime});
    try stdout.print("  CPU:     {s}\n", .{snapshot.cpu});
    try stdout.print("  Memory:  {s}\n", .{snapshot.memory});
    try stdout.print("  Shell:   {s}\n", .{snapshot.shell});
    try stdout.print("  Terminal: {s}\n", .{snapshot.terminal});
    try stdout.print("  Desktop: {s}\n", .{snapshot.desktop});
    try stdout.print("\n", .{});
}
