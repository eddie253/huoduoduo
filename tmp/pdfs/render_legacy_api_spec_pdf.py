from __future__ import annotations

import re
from pathlib import Path
from xml.sax.saxutils import escape

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle


ROOT = Path(__file__).resolve().parents[2]
INPUT_MD = ROOT / "docs" / "architecture" / "LEGACY_APP_API_SPEC_FINAL.zh-TW.md"
OUTPUT_PDF = ROOT / "output" / "pdf" / "LEGACY_APP_API_SPEC_FINAL.zh-TW.pdf"


def register_fonts() -> None:
    pdfmetrics.registerFont(TTFont("MSJH", r"C:\Windows\Fonts\msjh.ttc", subfontIndex=0))
    pdfmetrics.registerFont(TTFont("MSJH-B", r"C:\Windows\Fonts\msjhbd.ttc", subfontIndex=0))


def make_styles() -> dict[str, ParagraphStyle]:
    base = getSampleStyleSheet()
    return {
        "h1": ParagraphStyle(
            "h1",
            parent=base["Heading1"],
            fontName="MSJH-B",
            fontSize=18,
            leading=24,
            spaceAfter=10,
        ),
        "h2": ParagraphStyle(
            "h2",
            parent=base["Heading2"],
            fontName="MSJH-B",
            fontSize=14,
            leading=20,
            spaceBefore=8,
            spaceAfter=6,
        ),
        "h3": ParagraphStyle(
            "h3",
            parent=base["Heading3"],
            fontName="MSJH-B",
            fontSize=12,
            leading=17,
            spaceBefore=6,
            spaceAfter=4,
        ),
        "normal": ParagraphStyle(
            "normal",
            parent=base["BodyText"],
            fontName="MSJH",
            fontSize=10.5,
            leading=16,
            spaceAfter=2,
        ),
        "list": ParagraphStyle(
            "list",
            parent=base["BodyText"],
            fontName="MSJH",
            fontSize=10.5,
            leading=16,
            leftIndent=14,
            firstLineIndent=-10,
            spaceAfter=2,
        ),
        "table": ParagraphStyle(
            "table",
            parent=base["BodyText"],
            fontName="MSJH",
            fontSize=9.3,
            leading=13,
        ),
        "table_header": ParagraphStyle(
            "table_header",
            parent=base["BodyText"],
            fontName="MSJH-B",
            fontSize=9.3,
            leading=13,
        ),
    }


def is_table_separator(line: str) -> bool:
    raw_cells = [c.strip() for c in line.strip().strip("|").split("|")]
    if not raw_cells:
        return False
    return all(re.fullmatch(r":?-{3,}:?", c) for c in raw_cells)


def parse_table_block(lines: list[str], styles: dict[str, ParagraphStyle]) -> Table:
    rows: list[list[str]] = []
    for line in lines:
        if is_table_separator(line):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        rows.append(cells)

    if not rows:
        rows = [[""]]

    col_count = max(len(r) for r in rows)
    normalized_rows: list[list[Paragraph]] = []
    for row_index, row in enumerate(rows):
        padded = row + [""] * (col_count - len(row))
        style = styles["table_header"] if row_index == 0 else styles["table"]
        normalized_rows.append(
            [
                Paragraph(
                    escape(cell).replace("\n", "<br/>"),
                    style,
                )
                for cell in padded
            ]
        )

    usable_width = A4[0] - 36 * 2
    col_width = usable_width / col_count
    table = Table(normalized_rows, colWidths=[col_width] * col_count, repeatRows=1)
    table.setStyle(
        TableStyle(
            [
                ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#B6BCC6")),
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#EEF2F7")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
            ]
        )
    )
    return table


def line_to_paragraph(line: str, styles: dict[str, ParagraphStyle]) -> Paragraph:
    stripped = line.strip()
    if re.match(r"^\d+\.\s+", stripped) or stripped.startswith("- "):
        return Paragraph(escape(stripped), styles["list"])
    return Paragraph(escape(stripped), styles["normal"])


def render_markdown_to_pdf(input_md: Path, output_pdf: Path) -> None:
    register_fonts()
    styles = make_styles()

    content = input_md.read_text(encoding="utf-8-sig")
    lines = content.splitlines()

    story = []
    i = 0
    in_code_block = False
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        if stripped.startswith("```"):
            in_code_block = not in_code_block
            i += 1
            continue

        if in_code_block:
            story.append(Paragraph(escape(line), styles["normal"]))
            i += 1
            continue

        if not stripped:
            story.append(Spacer(1, 6))
            i += 1
            continue

        if stripped.startswith("|"):
            table_lines = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                table_lines.append(lines[i])
                i += 1
            story.append(parse_table_block(table_lines, styles))
            story.append(Spacer(1, 10))
            continue

        heading = re.match(r"^(#{1,6})\s+(.*)$", stripped)
        if heading:
            level = len(heading.group(1))
            text = heading.group(2).strip()
            if level == 1:
                style = styles["h1"]
            elif level == 2:
                style = styles["h2"]
            else:
                style = styles["h3"]
            story.append(Paragraph(escape(text), style))
            i += 1
            continue

        story.append(line_to_paragraph(line, styles))
        i += 1

    output_pdf.parent.mkdir(parents=True, exist_ok=True)
    doc = SimpleDocTemplate(
        str(output_pdf),
        pagesize=A4,
        leftMargin=36,
        rightMargin=36,
        topMargin=36,
        bottomMargin=36,
        title="LEGACY_APP_API_SPEC_FINAL.zh-TW",
        author="Codex",
    )
    doc.build(story)


if __name__ == "__main__":
    render_markdown_to_pdf(INPUT_MD, OUTPUT_PDF)
    print(str(OUTPUT_PDF))
