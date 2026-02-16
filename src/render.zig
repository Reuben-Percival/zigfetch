const std = @import("std");
const sysinfo = @import("sysinfo.zig");
const config = @import("config.zig");

fn printFrameTop(stdout: anytype, cfg: config.Config, width: usize) !void {
    switch (cfg.border) {
        .rounded => {
            try stdout.print("  ╭", .{});
            for (0..width) |_| try stdout.print("─", .{});
            try stdout.print("╮\n", .{});
        },
        .ascii => {
            try stdout.print("  +", .{});
            for (0..width) |_| try stdout.print("-", .{});
            try stdout.print("+\n", .{});
        },
        .none => {},
    }
}

fn printFrameBottom(stdout: anytype, cfg: config.Config, width: usize) !void {
    switch (cfg.border) {
        .rounded => {
            try stdout.print("  ╰", .{});
            for (0..width) |_| try stdout.print("─", .{});
            try stdout.print("╯\n", .{});
        },
        .ascii => {
            try stdout.print("  +", .{});
            for (0..width) |_| try stdout.print("-", .{});
            try stdout.print("+\n", .{});
        },
        .none => {},
    }
}

fn printRow(stdout: anytype, cfg: config.Config, row: []const u8) !void {
    switch (cfg.border) {
        .rounded => try stdout.print("  │{s}│\n", .{row}),
        .ascii => try stdout.print("  |{s}|\n", .{row}),
        .none => try stdout.print("  {s}\n", .{row}),
    }
}

const Ansi = struct {
    const reset = "\x1b[0m";
    // Natural, low-fatigue palette: moss/stone/sand.
    const frame = "\x1b[38;5;108m";
    const label = "\x1b[1;38;5;114m";
    const value = "\x1b[38;5;252m";
    const sep = "\x1b[38;5;242m";
    const title_user = "\x1b[1;38;5;151m";
    const title_host = "\x1b[38;5;109m";
    const muted = "\x1b[38;5;240m";
};

fn colorEnabled(cfg: config.Config) bool {
    return switch (cfg.color_mode) {
        .on => true,
        .off => false,
        .auto => blk: {
            if (std.posix.getenv("NO_COLOR") != null) break :blk false;
            if (!std.posix.isatty(std.posix.STDOUT_FILENO)) break :blk false;
            const term = std.posix.getenv("TERM") orelse break :blk false;
            if (std.mem.eql(u8, term, "dumb")) break :blk false;
            break :blk true;
        },
    };
}

fn isAllChar(line: []const u8, ch: u8) bool {
    if (line.len == 0) return false;
    for (line) |c| if (c != ch) return false;
    return true;
}

fn printLeftSegment(stdout: anytype, line: []const u8, left_width: usize, use_color: bool) !void {
    if (use_color and line.len > 0) {
        if (std.mem.indexOf(u8, line, " : ")) |sep_idx| {
            const label = line[0..sep_idx];
            const value = line[sep_idx + 3 ..];
            try stdout.print("{s}{s}{s}{s} : {s}{s}{s}", .{
                Ansi.label,
                label,
                Ansi.reset,
                Ansi.sep,
                Ansi.value,
                value,
                Ansi.reset,
            });
        } else if (std.mem.indexOfScalar(u8, line, '@')) |at_idx| {
            const user = line[0..at_idx];
            const host = line[at_idx + 1 ..];
            try stdout.print("{s}{s}{s}@{s}{s}{s}", .{
                Ansi.title_user,
                user,
                Ansi.reset,
                Ansi.title_host,
                host,
                Ansi.reset,
            });
        } else if (isAllChar(line, '-')) {
            try stdout.print("{s}{s}{s}", .{ Ansi.muted, line, Ansi.reset });
        } else {
            try stdout.print("{s}", .{line});
        }
    } else {
        try stdout.print("{s}", .{line});
    }

    var pad = if (left_width > line.len) left_width - line.len else 0;
    while (pad > 0) : (pad -= 1) try stdout.print(" ", .{});
}

fn printRowComposed(
    stdout: anytype,
    cfg: config.Config,
    left_line: []const u8,
    left_width: usize,
    right_line: []const u8,
    right_width: usize,
    use_color: bool,
) !void {
    switch (cfg.border) {
        .rounded => {
            if (use_color) try stdout.print("  {s}│{s}", .{ Ansi.frame, Ansi.reset }) else try stdout.print("  │", .{});
        },
        .ascii => {
            if (use_color) try stdout.print("  {s}|{s}", .{ Ansi.frame, Ansi.reset }) else try stdout.print("  |", .{});
        },
        .none => try stdout.print("  ", .{}),
    }

    try printLeftSegment(stdout, left_line, left_width, use_color);

    if (right_width > 0) {
        try stdout.print("  {s}", .{right_line});
        const right_cols = utf8Columns(right_line);
        var pad = if (right_width > right_cols) right_width - right_cols else 0;
        while (pad > 0) : (pad -= 1) try stdout.print(" ", .{});
    }

    switch (cfg.border) {
        .rounded => {
            if (use_color) try stdout.print("{s}│{s}\n", .{ Ansi.frame, Ansi.reset }) else try stdout.print("│\n", .{});
        },
        .ascii => {
            if (use_color) try stdout.print("{s}|{s}\n", .{ Ansi.frame, Ansi.reset }) else try stdout.print("|\n", .{});
        },
        .none => try stdout.print("\n", .{}),
    }
}

fn utf8PrefixByColumns(s: []const u8, max_cols: usize) []const u8 {
    if (max_cols == 0 or s.len == 0) return "";
    var i: usize = 0;
    var cols: usize = 0;
    while (i < s.len and cols < max_cols) {
        const step = std.unicode.utf8ByteSequenceLength(s[i]) catch 1;
        if (i + step > s.len) break;
        i += step;
        cols += 1;
    }
    return s[0..i];
}

fn utf8Columns(s: []const u8) usize {
    var i: usize = 0;
    var cols: usize = 0;
    while (i < s.len) {
        const step = std.unicode.utf8ByteSequenceLength(s[i]) catch 1;
        if (i + step > s.len) break;
        i += step;
        cols += 1;
    }
    return cols;
}

fn appendLeftLine(lines: *[160][320]u8, lens: *[160]usize, count: *usize, text: []const u8) void {
    if (count.* >= lines.len) return;
    const n = @min(text.len, lines[count.*].len);
    if (n > 0) @memcpy(lines[count.*][0..n], text[0..n]);
    lens[count.*] = n;
    count.* += 1;
}

fn appendWrapped(
    lines: *[160][320]u8,
    lens: *[160]usize,
    count: *usize,
    left_width: usize,
    text: []const u8,
) void {
    var remaining = text;
    while (remaining.len > left_width and count.* < lines.len) {
        var cut = left_width;
        var i = left_width;
        while (i > 0) : (i -= 1) {
            if (remaining[i - 1] == ' ') {
                cut = i - 1;
                break;
            }
        }
        if (cut == 0) cut = left_width;
        appendLeftLine(lines, lens, count, remaining[0..cut]);
        remaining = std.mem.trimLeft(u8, remaining[cut..], " ");
    }
    appendLeftLine(lines, lens, count, remaining);
}

fn moduleValue(snapshot: sysinfo.Snapshot, m: config.Module) []const u8 {
    return switch (m) {
        .os => snapshot.os_name,
        .arch => snapshot.arch,
        .kernel => snapshot.kernel,
        .uptime => snapshot.uptime,
        .host_model => snapshot.host_model,
        .bios => snapshot.bios,
        .motherboard => snapshot.motherboard,
        .cpu => snapshot.cpu,
        .cpu_cores => snapshot.cpu_cores,
        .cpu_threads => snapshot.cpu_threads,
        .cpu_freq => snapshot.cpu_freq,
        .cpu_temp => snapshot.cpu_temp,
        .gpu => snapshot.gpu,
        .gpu_driver => snapshot.gpu_driver,
        .resolution => snapshot.resolution,
        .memory => snapshot.memory,
        .swap => snapshot.swap,
        .disk => snapshot.disk,
        .battery => snapshot.battery,
        .load => snapshot.load,
        .processes => snapshot.processes,
        .network => snapshot.network,
        .audio => snapshot.audio,
        .packages => snapshot.packages,
        .shell => snapshot.shell,
        .terminal => snapshot.terminal,
        .session => snapshot.session,
        .desktop => snapshot.desktop,
        .wm => snapshot.wm,
    };
}

fn moduleLabel(m: config.Module) []const u8 {
    return switch (m) {
        .os => "OS",
        .arch => "Arch",
        .kernel => "Kernel",
        .uptime => "Uptime",
        .host_model => "Model",
        .bios => "BIOS",
        .motherboard => "Board",
        .cpu => "CPU",
        .cpu_cores => "Cores",
        .cpu_threads => "Threads",
        .cpu_freq => "CPU Freq",
        .cpu_temp => "CPU Temp",
        .gpu => "GPU",
        .gpu_driver => "GPU Driver",
        .resolution => "Display",
        .memory => "Memory",
        .swap => "Swap",
        .disk => "Disk",
        .battery => "Battery",
        .load => "Load",
        .processes => "Processes",
        .network => "Network",
        .audio => "Audio",
        .packages => "Packages",
        .shell => "Shell",
        .terminal => "Terminal",
        .session => "Session",
        .desktop => "Desktop",
        .wm => "WM",
    };
}

fn terminalColumns() ?usize {
    const raw = std.posix.getenv("COLUMNS") orelse return null;
    const cols = std.fmt.parseUnsigned(usize, raw, 10) catch return null;
    if (cols < 20) return null;
    return cols;
}

pub fn print(
    stdout: anytype,
    snapshot: sysinfo.Snapshot,
    icon_path: ?[]const u8,
    right_icon_block: ?[]const u8,
    cfg: config.Config,
) !void {
    try stdout.print("\n", .{});
    const use_color = colorEnabled(cfg);

    const show_icon_path = switch (cfg.icon_mode) {
        .off => false,
        .path => icon_path != null,
        .auto, .force => right_icon_block == null and icon_path != null,
    };
    if (show_icon_path) {
        if (icon_path) |p| {
            try stdout.print("  Icon: {s}\n", .{p});
            if (cfg.show_icon_note and !cfg.compact) {
                try stdout.print("  Tip: install `chafa` for inline distro icon rendering.\n", .{});
            }
            try stdout.print("\n", .{});
        }
    }

    const min_left_width: usize = 16;
    const default_left_width: usize = 52;
    var right_width: usize = if (right_icon_block != null) @intCast(cfg.chafa_width) else 0;
    var left_width: usize = default_left_width;

    if (terminalColumns()) |cols| {
        const content_budget = if (cols > 4) cols - 4 else 0;
        if (content_budget > 0) {
            if (right_width > 0) {
                if (content_budget <= min_left_width + 2) {
                    right_width = 0;
                    left_width = content_budget;
                } else {
                    const max_right = content_budget - min_left_width - 2;
                    if (right_width > max_right) right_width = max_right;
                    left_width = content_budget - 2 - right_width;
                }
            } else {
                left_width = @min(default_left_width, content_budget);
            }
        }
    }
    if (left_width < min_left_width) left_width = min_left_width;
    const gap: usize = if (right_width > 0) 2 else 0;
    const total_width: usize = left_width + gap + right_width;

    var left_lines: [160][320]u8 = undefined;
    var left_lens: [160]usize = undefined;
    var left_count: usize = 0;

    var head: [320]u8 = undefined;
    const title = std.fmt.bufPrint(&head, "{s}@{s}", .{ snapshot.user, snapshot.host }) catch "zigfetch";
    appendLeftLine(&left_lines, &left_lens, &left_count, title);
    var u: [320]u8 = undefined;
    const n = @min(title.len, u.len);
    @memset(u[0..n], '-');
    appendLeftLine(&left_lines, &left_lens, &left_count, u[0..n]);
    if (!cfg.compact) appendLeftLine(&left_lines, &left_lens, &left_count, "");

    for (cfg.modules[0..cfg.module_count]) |m| {
        const value = moduleValue(snapshot, m);
        if (m == .gpu and std.mem.indexOf(u8, value, " | ") != null) {
            var part_it = std.mem.splitSequence(u8, value, " | ");
            var part_index: usize = 0;
            while (part_it.next()) |part| : (part_index += 1) {
                var label_buf: [32]u8 = undefined;
                const label = if (part_index == 0)
                    "GPU"
                else
                    std.fmt.bufPrint(&label_buf, "GPU {d}", .{part_index + 1}) catch "GPU";
                var mod: [320]u8 = undefined;
                const line = std.fmt.bufPrint(&mod, "{s:<10} : {s}", .{ label, part }) catch part;
                appendWrapped(&left_lines, &left_lens, &left_count, left_width, line);
            }
        } else {
            var mod: [320]u8 = undefined;
            const line = std.fmt.bufPrint(&mod, "{s:<10} : {s}", .{ moduleLabel(m), value }) catch value;
            appendWrapped(&left_lines, &left_lens, &left_count, left_width, line);
        }
    }

    var right_lines: [128][]const u8 = undefined;
    var right_count: usize = 0;
    if (right_width > 0 and right_icon_block != null) {
        const icon_text = right_icon_block.?;
        var it = std.mem.splitScalar(u8, icon_text, '\n');
        while (it.next()) |line| {
            if (line.len == 0) continue;
            if (right_count >= right_lines.len) break;
            right_lines[right_count] = line;
            right_count += 1;
        }
    }

    if (use_color and cfg.border != .none) try stdout.print("{s}", .{Ansi.frame});
    try printFrameTop(stdout, cfg, total_width);
    if (use_color and cfg.border != .none) try stdout.print("{s}", .{Ansi.reset});

    const rows = @max(left_count, right_count);
    var row_i: usize = 0;
    while (row_i < rows) : (row_i += 1) {
        const left_line = if (row_i < left_count)
            left_lines[row_i][0..@min(left_lens[row_i], left_width)]
        else
            "";
        const right_line = if (right_width > 0 and row_i < right_count)
            utf8PrefixByColumns(right_lines[row_i], right_width)
        else
            "";
        try printRowComposed(stdout, cfg, left_line, left_width, right_line, right_width, use_color);
    }

    if (use_color and cfg.border != .none) try stdout.print("{s}", .{Ansi.frame});
    try printFrameBottom(stdout, cfg, total_width);
    if (use_color and cfg.border != .none) try stdout.print("{s}", .{Ansi.reset});
    try stdout.print("\n", .{});
}
