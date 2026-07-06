"""Download or inspect the LASCO calibration cache used by SOHOpy."""

from __future__ import annotations

import argparse
from pathlib import Path

from sohopy.lasco import ensure_calibration_assets, inspect_calibration_assets
from sohopy.lasco.assets import DEFAULT_CALIBRATION_BASE_URLS


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Inspect or download required LASCO calibration FITS assets."
    )
    parser.add_argument("calibration_root", type=Path)
    parser.add_argument("--download", action="store_true")
    parser.add_argument("--overwrite", action="store_true")
    parser.add_argument("--timeout", type=float, default=30.0)
    parser.add_argument(
        "--base-url",
        action="append",
        dest="base_urls",
        help="Calibration archive base URL. May be repeated.",
    )
    args = parser.parse_args(argv)

    if args.download:
        ensure_calibration_assets(
            args.calibration_root,
            base_urls=tuple(args.base_urls or DEFAULT_CALIBRATION_BASE_URLS),
            timeout=args.timeout,
            overwrite=args.overwrite,
        )

    statuses = inspect_calibration_assets(args.calibration_root)
    for status in statuses:
        marker = "ok" if status.exists else "missing"
        print(f"{marker:7} {status.filename} {status.path}")
    return 0 if all(status.exists for status in statuses) else 1


if __name__ == "__main__":
    raise SystemExit(main())
