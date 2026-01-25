import sys
import os
import re


def usage() -> None:
    prog = os.path.basename(sys.argv[0])
    print(f"Usage: {prog} <input.hex>")
    sys.exit(1)


def make_symbol_name(path: str) -> str:
    base = os.path.basename(path)
    name, _sep, _ext = base.partition('.')
    # Replace invalid characters with underscore
    name = re.sub(r"[^0-9a-zA-Z_]", "_", name)
    if not name:
        name = "data"
    # C identifiers cannot start with a digit
    if name[0].isdigit():
        name = "data_" + name
    return name


def read_hex_bytes(path: str) -> list[int]:
    bytes_out: list[int] = []
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            parts = line.split()
            for part in parts:
                # Allow comments starting with '#'
                if part.startswith('#'):
                    break
                try:
                    value = int(part, 16)
                except ValueError:
                    raise ValueError(f"Invalid hex byte '{part}' in {path}") from None
                if not 0 <= value <= 0xFF:
                    raise ValueError(f"Hex value out of byte range: '{part}' in {path}")
                bytes_out.append(value)
    return bytes_out


def emit_c_array(name: str, data: list[int]) -> str:
    lines: list[str] = []
    lines.append(f"const char {name}[] = {{\n")

    # Format 12 bytes per line for readability
    per_line = 12
    for i in range(0, len(data), per_line):
        chunk = data[i : i + per_line]
        hex_bytes = ", ".join(f"0x{b:02X}" for b in chunk)
        lines.append(f"    {hex_bytes},\n")

    lines.append("};\n\n")
    lines.append(f"const size_t {name}_len = sizeof({name});\n")
    return "".join(lines)


def main() -> None:
    if len(sys.argv) != 2:
        usage()

    in_path = sys.argv[1]
    if not os.path.isfile(in_path):
        print(f"Error: file not found: {in_path}", file=sys.stderr)
        sys.exit(1)

    symbol = make_symbol_name(in_path)
    data = read_hex_bytes(in_path)
    c_code = emit_c_array(symbol, data)
    sys.stdout.write(c_code)


if __name__ == "__main__":
    main()
