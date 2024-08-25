const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    b.installArtifact(b.addExecutable(.{
        .name = "cube",
        .root_source_file = b.path("src/cube.zig"),
        .target = target,
        .optimize = optimize,
        .strip = true,
    }));
    b.installArtifact(b.addExecutable(.{
        .name = "reg",
        .root_source_file = b.path("src/reg.zig"),
        .target = target,
        .optimize = optimize,
        .strip = true,
    }));

    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/test.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);

    const benchmarks = b.addExecutable(.{
        .name = "benchmark",
        .root_source_file = b.path("src/bench.zig"),
        .target = target,
        .optimize = .ReleaseFast,
    });

    b.installArtifact(benchmarks);
    const run_benchmarks = b.addRunArtifact(benchmarks);

    const bench_step = b.step("bench", "Run benchmarks");
    bench_step.dependOn(&run_benchmarks.step);
}
