"""Command line entry points for LASCO processing."""

from __future__ import annotations

import argparse
from pathlib import Path

from .assets import (
    DEFAULT_CALIBRATION_BASE_URLS,
    ensure_calibration_assets,
    inspect_calibration_assets,
)
from .config import LASCOConfig
from .level1 import reduce_level_1


def level1_main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Reduce a LASCO Level 0.5 FITS file.")
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument(
        "--calibration-root",
        required=True,
        type=Path,
        help="Directory containing LASCO calibration assets.",
    )
    parser.add_argument("--overwrite", action="store_true")
    args = parser.parse_args(argv)

    config = LASCOConfig(calibration_root=args.calibration_root)
    reduce_level_1(
        args.input,
        config=config,
        output_path=args.output,
        overwrite=args.overwrite,
    )
    return 0


def calibration_main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Inspect or download required LASCO calibration assets."
    )
    parser.add_argument("calibration_root", type=Path)
    parser.add_argument(
        "--download",
        action="store_true",
        help="Download missing assets into calibration_root.",
    )
    parser.add_argument(
        "--base-url",
        action="append",
        dest="base_urls",
        help=(
            "Calibration archive base URL. May be repeated. Defaults to known "
            "SOHO/SolarSoft candidates."
        ),
    )
    parser.add_argument("--overwrite", action="store_true")
    parser.add_argument("--timeout", type=float, default=30.0)
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
