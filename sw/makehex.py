#!/usr/bin/env python3
#
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.

import sys


def main() -> int:
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <input_file>", file=sys.stderr)
        return 2

    with open(sys.argv[1], "rb") as f:
        idx = 3
        word = ["00"] * 4
        while True:
            data = f.read(1)
            if not data:
                print(" ".join(word))
                return 0

            word[idx] = f"{data[0]:02X}"

            if idx == 0:
                print(" ".join(word))
                word = ["00"] * 4
                idx = 3
            else:
                idx -= 1


if __name__ == "__main__":
    sys.exit(main())