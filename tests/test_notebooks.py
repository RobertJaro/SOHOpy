import json
from pathlib import Path

NOTEBOOKS = sorted(Path("notebooks").glob("*.ipynb"))


def test_notebooks_are_valid_json() -> None:
    assert NOTEBOOKS
    for path in NOTEBOOKS:
        notebook = json.loads(path.read_text())
        assert notebook["nbformat"] == 4
        assert notebook["cells"]


def test_notebooks_expose_user_friendly_widgets() -> None:
    combined_source = "\n".join(
        "\n".join(cell.get("source", []))
        for path in NOTEBOOKS
        for cell in json.loads(path.read_text())["cells"]
    )

    assert "ipywidgets" in combined_source
    assert "widgets.Text" in combined_source
    assert "Button" in combined_source
    assert "start_time" in combined_source
    assert "end_time" in combined_source
