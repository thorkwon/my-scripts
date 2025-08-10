#!/usr/bin/env python3
import sys
import datetime
from pathlib import Path


def get_file(file_name: Path) -> list[str]:
    try:
        return file_name.read_text(encoding="utf-8").splitlines(keepends=True)
    except FileNotFoundError:
        return []


def create_file(file_name: Path, content: list[str]) -> None:
    file_name.write_text("".join(content), encoding="utf-8")


def fix_time(lines: list[str], delay: float) -> None:
    delay_ms = int(delay * 1000)
    flag = 0  # idx:0 time:1 text:2

    for i, line in enumerate(lines):
        if line == "\n":
            flag = 0
            continue

        if flag == 0:
            flag = 1
        elif flag == 1:
            start_str, end_str = (part.strip() for part in line.split("-->"))
            start_time = datetime.datetime.strptime(start_str, "%H:%M:%S,%f")
            end_time = datetime.datetime.strptime(end_str, "%H:%M:%S,%f")

            start_time += datetime.timedelta(milliseconds=delay_ms)
            end_time += datetime.timedelta(milliseconds=delay_ms)

            lines[i] = f"{start_time.strftime('%H:%M:%S,%f')[:-3]} --> {end_time.strftime('%H:%M:%S,%f')[:-3]}\n"
            flag = 2


def main() -> None:
    if len(sys.argv) != 3:
        script_name = Path(sys.argv[0]).name
        print(f"Usage: {script_name} <srt_file> <delay>\n")
        print("Enter the delay in seconds. Examples:")
        print("  +1 or 1")
        print("  -1 or -1.5")
        return

    srt_file = Path(sys.argv[1])
    try:
        delay = float(sys.argv[2])
    except ValueError:
        print("Error: delay must be a number.")
        return

    print(f"Subtitle delay: {delay:.3f} seconds")

    lines = get_file(srt_file)
    if not lines:
        print(f"Error: file '{srt_file}' not found or empty.")
        return

    fix_time(lines, delay)
    create_file(srt_file, lines)
    print("Subtitle times updated!")


if __name__ == "__main__":
    main()
