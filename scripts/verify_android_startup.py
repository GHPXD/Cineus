"""Verify reflective startup constructors in the actual minified APK or AAB.

Room's legacy consumer rule can keep WorkDatabase_Impl while R8 strips its
constructor. A successful build or manifest check does not detect that crash.
Read the packaged DEX class data, without requiring Android SDK tooling.
"""

from __future__ import annotations

import argparse
import struct
import zipfile
from pathlib import Path


REQUIRED = {
    "Ldev/cineus/cineus/MainActivity;",
    "Landroidx/work/impl/WorkDatabase_Impl;",
}


def public_constructors(data: bytes) -> set[str]:
    if not data.startswith(b"dex\n"):
        raise ValueError("Unsupported DEX header")

    def u32(offset: int) -> int:
        return struct.unpack_from("<I", data, offset)[0]

    def uleb(offset: int) -> tuple[int, int]:
        value = 0
        for shift in range(0, 35, 7):
            byte = data[offset]
            offset += 1
            value |= (byte & 0x7F) << shift
            if byte < 0x80:
                return value, offset
        raise ValueError("Invalid DEX integer")

    strings_offset = u32(60)
    types_offset = u32(68)
    protos_offset = u32(76)
    methods_offset = u32(92)

    def string(index: int) -> str:
        offset = u32(strings_offset + index * 4)
        _, start = uleb(offset)
        return data[start:data.index(b"\0", start)].decode("utf-8", "replace")

    def type_name(index: int) -> str:
        return string(u32(types_offset + index * 4))

    found = set()
    classes_offset = u32(100)
    for i in range(u32(96)):
        definition = classes_offset + i * 32
        name = type_name(u32(definition))
        if name not in REQUIRED:
            continue
        # A public concrete class is required for reflective instantiation.
        class_flags = u32(definition + 4)
        if not class_flags & 1 or class_flags & (0x200 | 0x400):
            continue
        offset = u32(definition + 24)
        if not offset:
            continue
        counts = []
        for _ in range(4):
            value, offset = uleb(offset)
            counts.append(value)
        for _ in range(counts[0] + counts[1]):
            _, offset = uleb(offset)  # field index delta
            _, offset = uleb(offset)  # access flags
        # Constructors are encoded as direct methods, with delta method IDs.
        method_index = 0
        for _ in range(counts[2]):
            delta, offset = uleb(offset)
            flags, offset = uleb(offset)
            code, offset = uleb(offset)
            method_index += delta
            owner, proto, method_name = struct.unpack_from(
                "<HHI", data, methods_offset + method_index * 8,
            )
            signature = protos_offset + proto * 12
            if (string(method_name) == "<init>" and flags & 1 and code
                    and type_name(owner) == name
                    and type_name(u32(signature + 4)) == "V"
                    and u32(signature + 8) == 0):
                found.add(name)
    return found


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("artifact", type=Path)
    args = parser.parse_args()
    found: set[str] = set()
    with zipfile.ZipFile(args.artifact) as archive:
        for name in archive.namelist():
            if name.endswith(".dex"):
                found.update(public_constructors(archive.read(name)))
    missing = REQUIRED - found
    if missing:
        parser.exit(1, "Android startup check FAILED: missing public no-arg "
                    "constructor: " + ", ".join(sorted(missing)) + "\n")
    print("Android startup constructors verified in " + str(args.artifact))


if __name__ == "__main__":
    main()
