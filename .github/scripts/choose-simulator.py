#!/usr/bin/env python3
"""Pick the iPhone simulator CI should test against.

Reads `xcrun simctl list devices available --json` on stdin and prints the UDID
of an iPhone on the newest installed iOS runtime.

Chosen at run time rather than hard-coded because GitHub changes the simulator
lineup between runner images. A stale device name fails with a message that does
not obviously mean "that iPhone no longer exists here", and that is an expensive
thing to debug on a Mac runner.
"""

import json
import sys

RUNTIME_MARKER = "SimRuntime.iOS-"


def runtime_version(runtime_identifier: str) -> tuple[int, ...]:
    """Sortable version from a runtime id like `…SimRuntime.iOS-26-5` -> (26, 5)."""
    tail = runtime_identifier.split(RUNTIME_MARKER)[-1]
    return tuple(int(part) for part in tail.split("-"))


def choose(devices_by_runtime: dict[str, list[dict]]) -> tuple[str, str, str] | None:
    """Return (udid, device name, runtime) for an iPhone on the newest iOS runtime."""
    newest = None
    for runtime, devices in devices_by_runtime.items():
        if RUNTIME_MARKER not in runtime:
            continue
        version = runtime_version(runtime)
        for device in devices:
            if "iPhone" not in device.get("name", ""):
                continue
            if newest is None or version > newest[0]:
                newest = (version, device["udid"], device["name"], runtime)
    if newest is None:
        return None
    _, udid, name, runtime = newest
    return udid, name, runtime


def main() -> int:
    payload = json.load(sys.stdin)
    picked = choose(payload.get("devices", {}))
    if picked is None:
        print("No iPhone simulator is available on this runner.", file=sys.stderr)
        return 1
    udid, name, runtime = picked
    print(f"Using {name} on {runtime}", file=sys.stderr)
    print(udid)
    return 0


if __name__ == "__main__":
    sys.exit(main())
