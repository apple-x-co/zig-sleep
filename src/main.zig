const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    const prog = args.next().?;
    const paramSeconds = args.next() orelse {
        std.log.err("usage: {s} seconds", .{prog});

        return error.InvalidArgs;
    };

    const stdout = std.io.getStdOut();
    const writer = stdout.writer();

    // TODO: 1秒以下の秒数
    const seconds = try std.fmt.parseInt(u64, paramSeconds, 10);

    var i: u64 = 0;
    while (i <= seconds) : (i += 1) {
        var strings = try progressBar(allocator, i, seconds);
        defer strings.deinit();

        // TODO: リファクタリング
        var loading = "⠿";
        if (i % 7 == 1) {
            loading = "⠷";
        }
        if (i % 7 == 2) {
            loading = "⠯";
        }
        if (i % 7 == 3) {
            loading = "⠟";
        }
        if (i % 7 == 4) {
            loading = "⠻";
        }
        if (i % 7 == 5) {
            loading = "⠽";
        }
        if (i % 7 == 6) {
            loading = "⠾";
        }

        try writer.print("[\x1b[2K(\u{001b}[46m\u{001b}[37m", .{});
        try writer.print("{s}", .{strings.items});
        try writer.print("\u{001b}[0m) {s} \u{001b}[1m\u{001b}[36m{}/{}\u{001b}[0m\r", .{loading, seconds - i, seconds});

        std.time.sleep(1000000000);
    }

    try writer.print("\n", .{});
}

fn progressBar(allocator: std.mem.Allocator, currentTime: u64, totalTime: u64) anyerror!std.ArrayList(u8) {
    const maxWidth = 50;
    const ratio = @intToFloat(f64, currentTime) / @intToFloat(f64, totalTime);
    const current = @floatToInt(u64, maxWidth * ratio);

    var strings = std.ArrayList(u8).init(allocator);

    var i: u64 = 0;
    while (i < maxWidth) : (i += 1)  {
        if (maxWidth == current) {
            try strings.append('*');
            continue;
        }

        if (i < current) {
            try strings.append('-');
            continue;
        }

        if (i == current) {
            try strings.append('>');
            continue;
        }

        try strings.append('_');
    }

    return strings;
}
