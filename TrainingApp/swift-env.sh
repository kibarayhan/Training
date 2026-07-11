# Swift 5.8 (nixpkgs) environment for Linux dev/CI of the TrainingApp packages.
# Usage: source swift-env.sh
export PATH=/root/.nix-profile/bin:$PATH
FOUNDATION=/nix/store/2sk3swrzjjnh539p0afgh4l5wcyf4xwh-swift-corelibs-foundation-5.8
FOUNDATION_DEV=/nix/store/vgpjkm07ihiv39v231knk10acz653ag2-swift-corelibs-foundation-5.8-dev
DISPATCH=/nix/store/gf6q854awaspa70g4c2ma2ikg5qw7l2q-swift-corelibs-libdispatch-5.8
DISPATCH_DEV=/nix/store/rd3hl4jrjj33xrw813d0qqr5q8y86k58-swift-corelibs-libdispatch-5.8-dev
XCTEST=/nix/store/k68f35xr5kqw2bb5zkiil2grac7jm2jh-swift-corelibs-xctest-5.8
SWIFTLIB=/nix/store/zrhrwccm0km8739nvpx8xmr6kx7r0imj-swift-5.8-lib
export NIX_SWIFTFLAGS_COMPILE=""
export NIX_LDFLAGS=""
for p in "$FOUNDATION" "$FOUNDATION_DEV" "$DISPATCH" "$DISPATCH_DEV" "$XCTEST"; do
  for subdir in lib/swift/linux/x86_64 lib/swift; do
    [ -d "$p/$subdir" ] && NIX_SWIFTFLAGS_COMPILE+=" -I $p/$subdir"
  done
  for subdir in lib/swift/linux lib/swift; do
    [ -d "$p/$subdir" ] && NIX_LDFLAGS+=" -L $p/$subdir"
  done
done
export LD_LIBRARY_PATH="$FOUNDATION/lib/swift/linux:$DISPATCH/lib:$XCTEST/lib/swift/linux:$SWIFTLIB/lib/swift/linux:${LD_LIBRARY_PATH:-}"
# Clang-importer header paths for the C guts of Dispatch/Foundation.
export NIX_SWIFTFLAGS_COMPILE+=" -Xcc -I$DISPATCH_DEV/include -Xcc -I$FOUNDATION_DEV/include"
# Explicit linker search paths (the cc-wrapper does not consume our NIX_LDFLAGS here).
export SWIFT_CORELIBS_LDFLAGS="-L $FOUNDATION/lib/swift/linux -L $DISPATCH/lib -L $XCTEST/lib/swift/linux"
