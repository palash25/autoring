const std = @import("std");
const benchmark = @import("benchmark.zig");
const Allocator = std.mem.Allocator;
const autoring = @import("root.zig");

pub fn main() !void {
    (try benchmark.run(enqueueOneThousandIters)).print("enqueue 1_000 iters");
    (try benchmark.run(enqueueOneMillionIters)).print("enqueue 1_000_000 iters");
}

fn enqueueOneThousandIters(allocator: Allocator, timer: *std.time.Timer) !void {
    timer.reset();

    const queue = try autoring.Queue(u32).init(allocator, 1024);
    defer queue.deinit();

    for (0..1_000) |i| {
        try queue.enqueue(@intCast(i));
    }
}

fn enqueueOneMillionIters(allocator: Allocator, timer: *std.time.Timer) !void {
    timer.reset();

    const queue = try autoring.Queue(u32).init(allocator, 1024);
    defer queue.deinit();

    for (0..1_000_000) |i| {
        try queue.enqueue(@intCast(i));
    }
}
