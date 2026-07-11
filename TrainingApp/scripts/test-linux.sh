#!/usr/bin/env bash
# Run the package tests on the nixpkgs Swift 5.8 toolchain, which lacks
# libIndexStore.so and therefore SwiftPM test discovery. Builds each library
# as a testable module, then compiles the test module with a generated
# XCTMain entry point. Mac / official-toolchain CI use plain `swift test`.
set -euo pipefail
cd "$(dirname "$0")/.."
source ./swift-env.sh

BUILD=.build/linux-tests
mkdir -p "$BUILD"
ABS_BUILD="$(pwd)/$BUILD"

build_lib() { # <ModuleName>
    local name=$1
    swiftc -enable-testing -emit-module -emit-library $SWIFT_CORELIBS_LDFLAGS \
        -module-name "$name" \
        -emit-module-path "$BUILD/$name.swiftmodule" \
        -I "$BUILD" -L "$BUILD" \
        Sources/"$name"/*.swift \
        -o "$BUILD/lib$name.so"
}

run_tests() { # <TestModule> <linked-libs...>
    local name=$1; shift
    local gen_dir="$BUILD/${name}-gen"; mkdir -p "$gen_dir"; local gen="$gen_dir/main.swift"
    python3 scripts/gen-test-main.py "Tests/${name}" "$gen"
    local link_args=()
    for lib in "$@"; do link_args+=("-l$lib"); done
    swiftc -enable-testing $SWIFT_CORELIBS_LDFLAGS -module-name "${name}" \
        -I "$BUILD" -L "$BUILD" "${link_args[@]}" \
        -Xlinker -rpath -Xlinker "$ABS_BUILD" \
        Tests/"${name}"/*.swift "$gen" \
        -o "$BUILD/${name}"
    echo "── ${name} ──"
    "$BUILD/${name}"
}

build_lib TrainingCore

case "${1:-all}" in
    core) run_tests TrainingCoreTests TrainingCore ;;
    fit)
        build_lib TrainingFIT
        run_tests TrainingFITTests TrainingCore TrainingFIT ;;
    sync)
        build_lib TrainingSync
        run_tests TrainingSyncTests TrainingCore TrainingSync ;;
    all)
        build_lib TrainingFIT
        build_lib TrainingSync
        run_tests TrainingCoreTests TrainingCore
        run_tests TrainingFITTests TrainingCore TrainingFIT
        run_tests TrainingSyncTests TrainingCore TrainingSync ;;
    *) echo "usage: $0 [core|fit|sync|all]"; exit 2 ;;
esac
