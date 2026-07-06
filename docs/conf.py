"""Sphinx configuration for SOHOpy."""

from __future__ import annotations

from pathlib import Path
import os
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))

project = "SOHOpy"
author = "Robert Jarolim"
copyright = "2026, Robert Jarolim"
release = "0.1.0"

extensions = [
    "myst_parser",
    "sphinx.ext.autodoc",
    "sphinx.ext.autosummary",
    "sphinx.ext.napoleon",
    "sphinx.ext.viewcode",
    "sphinx_autodoc_typehints",
    "sphinx_copybutton",
]

if os.environ.get("SOHOPY_ENABLE_INTERSPHINX") == "1":
    extensions.append("sphinx.ext.intersphinx")

source_suffix = {
    ".rst": "restructuredtext",
    ".md": "markdown",
}
master_doc = "index"

autosummary_generate = True
autodoc_member_order = "bysource"
autodoc_typehints = "description"
napoleon_google_docstring = True
napoleon_numpy_docstring = True

html_theme = "furo"
html_title = "SOHOpy"
html_static_path = ["_static"]
html_logo = "../assets/sohopy_logo.png"
html_favicon = "../assets/sohopy_logo.png"
html_theme_options = {
    "sidebar_hide_name": False,
}

myst_enable_extensions = [
    "colon_fence",
    "deflist",
    "substitution",
]

if os.environ.get("SOHOPY_ENABLE_INTERSPHINX") == "1":
    intersphinx_mapping = {
        "python": ("https://docs.python.org/3", None),
        "numpy": ("https://numpy.org/doc/stable/", None),
        "scipy": ("https://docs.scipy.org/doc/scipy/", None),
        "astropy": ("https://docs.astropy.org/en/stable/", None),
        "sunpy": ("https://docs.sunpy.org/en/stable/", None),
    }

exclude_patterns = [
    "_build",
    "Thumbs.db",
    ".DS_Store",
]
