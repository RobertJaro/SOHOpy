"""Run the end-to-end synthetic LASCO workflow and write outputs to disk."""

from __future__ import annotations

import argparse
import sys
from importlib import import_module
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Run SOHOpy's synthetic LASCO reduction and plotting workflow."
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("runs/lasco_synthetic_workflow"),
        help="Directory where FITS and PNG products will be written.",
    )
    args = parser.parse_args(argv)
    run_workflow = import_module("examples.lasco_full_workflow").run_workflow
    outputs = run_workflow(args.output_dir)
    print(f"Wrote {len(outputs)} products to {args.output_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
