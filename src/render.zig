const std = @import("std");
const sysinfo = @import("sysinfo.zig");
const config = @import("config.zig");

fn useColor(cfg: config.Config) bool {
    return cfg.color and std.posix.isatty(std.posix.STDOUT_FILENO);
}

fn c(code: []const u8, enabled: bool) []const u8 {
    return if (enabled) code else "";
}

fn printFrameTop(stdout: anytype, cfg: config.Config) !void {
    switch (cfg.border) {
        .rounded => try stdout.print("  ╭──────────────────────────────────────────────╮\n", .{}),
        .ascii => try stdout.print("  +----------------------------------------------+\n", .{}),
        .none => {},
    }
}

fn printFrameBottom(stdout: anytype, cfg: config.Config) !void {
    switch (cfg.border) {
        .rounded => try stdout.print("  ╰──────────────────────────────────────────────╯\n", .{}),
        .ascii => try stdout.print("  +----------------------------------------------+\n", .{}),
        .none => {},
    }
}

fn printLine(stdout: anytype, cfg: config.Config, text: []const u8) !void {
    switch (cfg.border) {
        .rounded => try stdout.print("  │ {s}\n", .{text}),
        .ascii => try stdout.print("  | {s}\n", .{text}),
        .none => try stdout.print("  {s}\n", .{text}),
    }
}

fn printSep(stdout: anytype, cfg: config.Config) !void {
    switch (cfg.border) {
        .rounded => try stdout.print("  │\n", .{}),
        .ascii => try stdout.print("  |\n", .{}),
        .none => try stdout.print("\n", .{}),
    }
}

fn printModule(
    stdout: anytype,
    cfg: config.Config,
    colors: bool,
    label: []const u8,
    value: []const u8,
) !void {
    var buf: [320]u8 = undefined;
    const line = std.fmt.bufPrint(
        &buf,
        "{s}{s:<10}{s} {s}:{s} {s}",
        .{
            c("\x1b[38;5;111m", colors),
            label,
            c("\x1b[0m", colors),
            c("\x1b[38;5;245m", colors),
            c("\x1b[0m", colors),
            value,
        },
    ) catch value;
    try printLine(stdout, cfg, line);
}

fn printColorBar(stdout: anytype, cfg: config.Config) !void {
    if (!std.posix.isatty(std.posix.STDOUT_FILENO)) return;
    if (!useColor(cfg)) return;
    const bar = "\x1b[40m  \x1b[41m  \x1b[42m  \x1b[43m  \x1b[44m  \x1b[45m  \x1b[46m  \x1b[47m  \x1b[0m";
    try printLine(stdout, cfg, bar);
}

pub fn print(
    stdout: anytype,
    snapshot: sysinfo.Snapshot,
    icon_path: ?[]const u8,
    icon_rendered: bool,
    cfg: config.Config,
) !void {
    const colors = useColor(cfg);

    try stdout.print("\n", .{});

    if (cfg.show_icon and !icon_rendered and cfg.show_icon_path) {
        if (icon_path) |p| {
            var icon_buf: [320]u8 = undefined;
            const icon_line = std.fmt.bufPrint(&icon_buf, "Icon: {s}", .{p}) catch p;
            try printLine(stdout, cfg, icon_line);
            if (cfg.show_icon_note and !cfg.compact) {
                try printLine(stdout, cfg, "Tip: install `chafa` for inline distro icon rendering.");
            }
            try stdout.print("\n", .{});
        }
    }

    try printFrameTop(stdout, cfg);

    var title_buf: [256]u8 = undefined;
    const title = std.fmt.bufPrint(
        &title_buf,
        "{s}{s}@{s}{s}",
        .{
            c("\x1b[1;38;5;81m", colors),
            snapshot.user,
            snapshot.host,
            c("\x1b[0m", colors),
        },
    ) catch "zigfetch";
    try printLine(stdout, cfg, title);

    var under_buf: [128]u8 = undefined;
    const n = @min(title.len, under_buf.len);
    @memset(under_buf[0..n], '-');
    try printLine(stdout, cfg, under_buf[0..n]);

    if (!cfg.compact) try printSep(stdout, cfg);

    try printModule(stdout, cfg, colors, "OS", snapshot.os_name);
    try printModule(stdout, cfg, colors, "Arch", snapshot.arch);
    try printModule(stdout, cfg, colors, "Kernel", snapshot.kernel);
    try printModule(stdout, cfg, colors, "Uptime", snapshot.uptime);
    try printModule(stdout, cfg, colors, "CPU", snapshot.cpu);
    try printModule(stdout, cfg, colors, "Memory", snapshot.memory);
    try printModule(stdout, cfg, colors, "Packages", snapshot.packages);
    try printModule(stdout, cfg, colors, "Shell", snapshot.shell);
    try printModule(stdout, cfg, colors, "Terminal", snapshot.terminal);
    try printModule(stdout, cfg, colors, "Session", snapshot.session);
    try printModule(stdout, cfg, colors, "Desktop", snapshot.desktop);
    try printModule(stdout, cfg, colors, "WM", snapshot.wm);

    if (!cfg.compact) {
        try printSep(stdout, cfg);
        try printColorBar(stdout, cfg);
    }

    try printFrameBottom(stdout, cfg);
    try stdout.print("\n", .{});
}
