#!/usr/bin/env python3
"""Generate an XCTMain entry point for one test module.

The nixpkgs Swift 5.8 toolchain lacks libIndexStore.so, so SwiftPM's
automatic test discovery fails on this machine. This script scans a test
directory for `final class XTests: XCTestCase` classes and their
`func testX()` methods and emits a main.swift that registers them with
XCTMain. Mac and official-toolchain CI keep using plain `swift test`.
"""
import re
import sys
from pathlib import Path

def main() -> None:
    if len(sys.argv) != 3:
        sys.exit("usage: gen-test-main.py <tests-dir> <out-file>")
    tests_dir, out_file = Path(sys.argv[1]), Path(sys.argv[2])

    class_re = re.compile(r"class\s+(\w+)\s*:\s*XCTestCase")
    method_re = re.compile(r"func\s+(test\w+)\s*\(")

    registrations: list[str] = []
    for path in sorted(tests_dir.glob("*.swift")):
        raw = path.read_text()
        # Drop line comments so commented-out tests don't register, and
        # refuse async tests, which XCTMain's testCase() would silently skip.
        text = "\n".join(
            line for line in raw.splitlines()
            if not line.lstrip().startswith("//"))
        if re.search(r"func\s+test\w+\s*\([^)]*\)\s*async", text):
            sys.exit(f"{path}: async test methods are not supported by the "
                     "Linux XCTMain runner — make them synchronous or run on Mac CI")
        # Split per class so methods attach to the right one.
        pieces = class_re.split(text)
        # pieces = [prefix, class1, body1, class2, body2, ...]
        for i in range(1, len(pieces), 2):
            cls, body = pieces[i], pieces[i + 1]
            methods = method_re.findall(body)
            if not methods:
                continue
            entries = ",\n        ".join(
                f'("{m}", {cls}.{m})' for m in methods)
            registrations.append(
                f"extension {cls} {{\n"
                f"    static let __allTests: [(String, ({cls}) -> () throws -> Void)] = [\n"
                f"        {entries},\n"
                f"    ]\n"
                f"}}\n")
            registrations.append(
                f"__cases.append(testCase({cls}.__allTests))\n"
                .replace("__cases.append", "// REGISTER: "))

    ext_blocks = [r for r in registrations if r.startswith("extension")]
    case_lines = [
        r.split("// REGISTER: ")[1].strip()
        for r in registrations if r.startswith("// REGISTER: ")]

    out = ["import XCTest", ""]
    out += ext_blocks
    out.append("var __cases: [XCTestCaseEntry] = []")
    out += [f"__cases.append({line})" for line in case_lines]
    out.append("XCTMain(__cases)")
    out_file.write_text("\n".join(out) + "\n")
    print(f"{out_file}: {len(case_lines)} test classes registered")

if __name__ == "__main__":
    main()
