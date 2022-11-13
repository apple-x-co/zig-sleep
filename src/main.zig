const std = @import("std");

pub fn main() !void {
    std.log.info("s:{s}, u:{u}\n", .{"👾👾", '👾'});

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

    var loadingMap = std.AutoHashMap(u64, []const u8).init(allocator);
    defer loadingMap.deinit();
    try loadingMap.put(0, "⠿");
    try loadingMap.put(1, "⠷");
    try loadingMap.put(2, "⠯");
    try loadingMap.put(3, "⠟");
    try loadingMap.put(4, "⠻");
    try loadingMap.put(5, "⠽");
    try loadingMap.put(6, "⠾");

    const seconds = try std.fmt.parseFloat(f32, paramSeconds);
    const milliseconds = @floatToInt(u64, seconds * std.time.ns_per_us);

    var totalSeconds: f32 = @intToFloat(f32, milliseconds) / @intToFloat(f32, std.time.ns_per_us);

    var i: u64 = 0;
    var currentSeconds: f64 = 0.0;
    var timer = try std.time.Timer.start();
    while (i < milliseconds) : (i += 1) {
        var strings = try progressBar(allocator, i, milliseconds);
        defer strings.deinit();

        const loading = loadingMap.get(i % 7).?;

        currentSeconds = @intToFloat(f32, (milliseconds - i)) / @intToFloat(f32, std.time.ns_per_us);

        try writer.print("[\x1b[2K(\u{001b}[46m\u{001b}[37m{s}\u{001b}[0m) {s} \u{001b}[1m\u{001b}[36m{d:.1}/{d:.1}\u{001b}[0m\r", .{ strings.items, loading, currentSeconds, totalSeconds });

        std.time.sleep(1 * std.time.ns_per_ms);
        i = timer.read() / std.time.ns_per_ms;
    }

    try writer.print("[\x1b[2K\u{001b}[46m\u{001b}[37mFINISH!! {d:.1} seconds.\u{001b}[0m\n", .{totalSeconds});
}

fn progressBar(allocator: std.mem.Allocator, currentTime: u64, totalTime: u64) anyerror!std.ArrayList(u8) {
    const maxWidth = 50;
    const ratio = @intToFloat(f64, currentTime) / @intToFloat(f64, totalTime);
    const current = @floatToInt(u64, maxWidth * ratio);

    var strings = std.ArrayList(u8).init(allocator);

    var i: u64 = 0;
    while (i < maxWidth) : (i += 1) {
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
