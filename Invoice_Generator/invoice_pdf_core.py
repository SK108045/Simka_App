from __future__ import annotations

import io
from pathlib import Path
from typing import Iterable, List, Dict, Any

from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase.pdfmetrics import stringWidth

# Default company details. Keep these fixed unless SIMKA changes them.
COMPANY_NAME = "SIMKA TECHNOLOGIES FIRE SERVICES"
COMPANY_ADDRESS_1 = "P.O, BOX 7785 - 00200"
COMPANY_ADDRESS_2 = "NAIROBI"
COMPANY_PHONE = "+254 725 625 952, +254 738 456 909"

DARK_BLUE = colors.Color(0.121569, 0.329412, 0.560784)
LIGHT_BLUE = colors.Color(0.32549, 0.556863, 0.843137)
ROW_GREY = colors.Color(0.878431, 0.878431, 0.878431)
BLACK = colors.black
WHITE = colors.white

BASE_DIR = Path(__file__).resolve().parent
DEFAULT_LOGO_PATH = BASE_DIR / "static" / "simka_logo.jpg"


def ksh(value: Any) -> str:
    try:
        value = float(value)
    except Exception:
        value = 0.0
    return f"Ksh.{value:,.2f}"


def parse_money(value: Any) -> float:
    if value is None or str(value).strip() == "":
        return 0.0
    cleaned = str(value).replace("Ksh.", "").replace("Ksh", "").replace(",", "").replace("%", "").strip()
    return float(cleaned)


def clean_text(value: Any) -> str:
    return str(value or "").replace("\r", "").strip()


def sanitize_item(raw: Dict[str, Any]) -> Dict[str, Any]:
    qty_raw = raw.get("qty", "")
    code = clean_text(raw.get("code", ""))
    description = clean_text(raw.get("description", ""))
    unit_price = parse_money(raw.get("unit_price", 0))
    vat = parse_money(raw.get("vat", 0))
    tax_percent = parse_money(raw.get("tax_percent", 0))

    # Completely empty row should be ignored
    if not code and not description and str(qty_raw).strip() == "" and unit_price == 0:
        raise ValueError("Empty item row")

    # If user picked/typed an item but left Qty blank, assume 1
    if str(qty_raw).strip() == "":
        qty = 1
    else:
        qty = parse_money(qty_raw)

    # Do not allow zero or negative quantity on real invoice rows
    if qty <= 0:
        raise ValueError(
            f"Quantity must be greater than 0 for item: {description or code}"
        )

    if unit_price < 0:
        raise ValueError(
            f"Unit price cannot be negative for item: {description or code}"
        )

    return {
        "qty": qty,
        "code": code,
        "description": description,
        "unit_price": unit_price,
        "vat": vat,
        "tax_percent": tax_percent,
    }

class InvoicePDF:
    def __init__(
        self,
        output: str | io.BytesIO,
        invoice_no: str,
        invoice_date: str,
        due_date: str,
        bill_to_lines: Iterable[str],
        items: List[Dict[str, Any]],
        logo_path: str | Path = DEFAULT_LOGO_PATH,
    ):
        self.output = output
        self.invoice_no = clean_text(invoice_no)
        self.invoice_date = clean_text(invoice_date)
        self.due_date = clean_text(due_date)
        self.bill_to_lines = [clean_text(x) for x in bill_to_lines if clean_text(x)]
        self.items = items
        self.c = canvas.Canvas(output, pagesize=A4)
        self.W, self.H = A4
        self.logo = ImageReader(str(logo_path)) if Path(logo_path).exists() else None

    # Top-left coordinate helpers, designed to match the uploaded SIMKA invoice layout.
    def rect_tl(self, x, y, w, h, fill_color=None, stroke_color=None, stroke_width=1):
        c = self.c
        if fill_color is not None:
            c.setFillColor(fill_color)
        if stroke_color is not None:
            c.setStrokeColor(stroke_color)
            c.setLineWidth(stroke_width)
        c.rect(x, self.H - y - h, w, h, stroke=1 if stroke_color is not None else 0, fill=1 if fill_color is not None else 0)

    def line_tl(self, x1, y1, x2, y2, color=BLACK, width=1):
        self.c.setStrokeColor(color)
        self.c.setLineWidth(width)
        self.c.line(x1, self.H - y1, x2, self.H - y2)

    def string_tl(self, x, baseline_y, text, font="Times-Roman", size=10, color=BLACK):
        self.c.setFont(font, size)
        self.c.setFillColor(color)
        self.c.drawString(x, self.H - baseline_y, str(text))

    def right_string_tl(self, x_right, baseline_y, text, font="Times-Roman", size=10, color=BLACK):
        self.c.setFont(font, size)
        self.c.setFillColor(color)
        self.c.drawRightString(x_right, self.H - baseline_y, str(text))

    def centered_string_tl(self, x_center, baseline_y, text, font="Times-Bold", size=22, color=BLACK):
        self.c.setFont(font, size)
        self.c.setFillColor(color)
        self.c.drawCentredString(x_center, self.H - baseline_y, str(text))

    def wrap_lines(self, text, max_width, font="Times-Roman", size=8):
        text = clean_text(text).replace("\\n", "\n")
        result = []
        for raw in text.split("\n"):
            words = raw.split()
            if not words:
                result.append("")
                continue
            current = words[0]
            for word in words[1:]:
                test = current + " " + word
                if stringWidth(test, font, size) <= max_width:
                    current = test
                else:
                    result.append(current)
                    current = word
            result.append(current)
        return result or [""]

    def wrapped_text_tl(self, x, y_top, w, h, text, font="Times-Roman", size=8, leading=9.6, align="left"):
        lines = self.wrap_lines(text, w - 6, font, size)
        self.c.setFont(font, size)
        self.c.setFillColor(BLACK)
        baseline = y_top + size + 3
        for line in lines:
            if baseline > y_top + h - 2:
                break
            if align == "right":
                self.c.drawRightString(x + w - 4, self.H - baseline, line)
            elif align == "center":
                self.c.drawCentredString(x + w / 2, self.H - baseline, line)
            else:
                self.c.drawString(x + 4, self.H - baseline, line)
            baseline += leading

    def draw_header_page_1(self):
        self.rect_tl(54, 54, 487, 19, DARK_BLUE)
        self.rect_tl(286, 79, 78, 36, WHITE)
        self.centered_string_tl(325, 108, "Invoice", "Times-Bold", 22)
        self.rect_tl(54, 122, 270, 9, DARK_BLUE)
        self.rect_tl(327, 122, 216, 9, DARK_BLUE)

        if self.logo:
            self.c.drawImage(self.logo, 60, self.H - 192, width=51, height=54, mask='auto')
        self.string_tl(60, 212, COMPANY_NAME, "Times-Bold", 10)
        self.string_tl(60, 229, COMPANY_ADDRESS_1, "Times-Roman", 10)
        self.string_tl(60, 241, COMPANY_ADDRESS_2, "Times-Roman", 10)
        self.string_tl(60, 253, COMPANY_PHONE, "Times-Roman", 10)
        self.rect_tl(54, 255, 270, 2, DARK_BLUE)

        self.string_tl(333, 150, "Date:", "Times-Roman", 10)
        self.string_tl(435, 150, self.invoice_date, "Times-Roman", 10)
        self.string_tl(333, 162, "Invoice No.:", "Times-Roman", 10)
        self.string_tl(435, 162, self.invoice_no, "Times-Roman", 10)
        self.string_tl(333, 174, "Due Date:", "Times-Roman", 10)
        self.string_tl(435, 174, self.due_date, "Times-Roman", 10)
        self.rect_tl(327, 181, 216, 2, DARK_BLUE)

        self.rect_tl(54, 330, 244, 9, LIGHT_BLUE)
        self.string_tl(60, 358, "Bill To:", "Times-Roman", 10)
        y = 370
        for line in self.bill_to_lines[:5]:
            self.string_tl(60, y, line, "Times-Roman", 10)
            y += 12
        self.rect_tl(54, 413, 244, 2, LIGHT_BLUE)

    def draw_table_header(self, top_y):
        xs = [54, 92, 170, 248, 331, 394, 452, 535]
        self.rect_tl(54, top_y, 481, 20, LIGHT_BLUE)
        self.line_tl(54, top_y, 535, top_y, BLACK, 1)
        self.line_tl(54, top_y + 20, 535, top_y + 20, BLACK, 1)
        for x in xs:
            self.line_tl(x, top_y, x, top_y + 20, BLACK, 1)

        labels = ["Qty", "Item", "Description", "Unit Price", "VAT", "TAX %", "Total"]
        col_pairs = list(zip(xs[:-1], xs[1:]))
        aligns = ["right", "left", "left", "right", "right", "right", "right"]
        for idx, label in enumerate(labels):
            self.wrapped_text_tl(col_pairs[idx][0], top_y + 1, col_pairs[idx][1] - col_pairs[idx][0], 18, label, "Helvetica-Bold", 7, align=aligns[idx])

    def row_height(self, item):
        desc_lines = self.wrap_lines(item["description"], 72, "Times-Roman", 8)
        item_lines = self.wrap_lines(item["code"], 70, "Times-Roman", 8)
        n = max(len(desc_lines), len(item_lines), 1)
        return max(31, int(n * 9.6 + 11))

    def draw_table_grid(self, top_y, bottom_y):
        xs = [54, 92, 170, 248, 331, 394, 452, 535]
        for x in xs:
            self.line_tl(x, top_y, x, bottom_y, BLACK, 1)
        self.line_tl(54, bottom_y, 535, bottom_y, BLACK, 1)

    def draw_item_row(self, row_top, row_h, item, idx):
        xs = [54, 92, 170, 248, 331, 394, 452, 535]
        if idx % 2 == 1:
            self.rect_tl(55, row_top + 1, 480, row_h - 1, ROW_GREY)
        self.line_tl(54, row_top + row_h, 535, row_top + row_h, BLACK, 1)
        qty_text = str(int(item["qty"])) if float(item["qty"]).is_integer() else f"{item['qty']:g}"
        self.wrapped_text_tl(xs[0], row_top + 1, xs[1] - xs[0], row_h - 2, qty_text, "Times-Roman", 8, align="right")
        self.wrapped_text_tl(xs[1], row_top + 1, xs[2] - xs[1], row_h - 2, item["code"], "Times-Roman", 8)
        self.wrapped_text_tl(xs[2], row_top + 1, xs[3] - xs[2], row_h - 2, item["description"], "Times-Roman", 8)
        self.wrapped_text_tl(xs[3], row_top + 1, xs[4] - xs[3], row_h - 2, ksh(item["unit_price"]), "Times-Roman", 8, align="right")
        self.wrapped_text_tl(xs[4], row_top + 1, xs[5] - xs[4], row_h - 2, ksh(item.get("vat", 0)), "Times-Roman", 8, align="right")
        self.wrapped_text_tl(xs[5], row_top + 1, xs[6] - xs[5], row_h - 2, f"{item.get('tax_percent', 0):g}%", "Times-Roman", 8, align="right")
        self.wrapped_text_tl(xs[6], row_top + 1, xs[7] - xs[6], row_h - 2, ksh(item["line_total"]), "Times-Roman", 8, align="right")

    def footer(self, page_num):
        self.right_string_tl(541, 835, f"Invoice #{self.invoice_no}, Page {page_num}", "Times-Roman", 8)

    def draw_totals(self, total):
        self.right_string_tl(465, 694, "Total", "Times-Bold", 10)
        self.right_string_tl(531, 694, ksh(total), "Times-Bold", 10)
        self.right_string_tl(465, 716, "Balance Due", "Times-Bold", 10)
        self.right_string_tl(531, 716, ksh(total), "Times-Bold", 10)
        self.string_tl(54, 751, "Thank you for your business.", "Times-Bold", 11)
        self.rect_tl(54, 769, 487, 19, LIGHT_BLUE)

    def build(self):
        for item in self.items:
            qty = float(item.get("qty", 0) or 0)
            unit = float(item.get("unit_price", 0) or 0)
            vat = float(item.get("vat", 0) or 0)
            tax_pct = float(item.get("tax_percent", 0) or 0)
            subtotal = qty * unit
            item["line_total"] = subtotal + vat + (subtotal * tax_pct / 100.0)
        grand_total = sum(i["line_total"] for i in self.items)

        page_num = 1
        i = 0
        while i < len(self.items):
            if page_num == 1:
                self.draw_header_page_1()
                table_top = 410
                page_bottom_for_continuing = 788
                page_bottom_for_last = 671
            else:
                table_top = 54
                page_bottom_for_continuing = 671
                page_bottom_for_last = 671

            self.draw_table_header(table_top)
            y = table_top + 20
            j = i
            while j < len(self.items):
                h = self.row_height(self.items[j])
                tentative_bottom = page_bottom_for_last if j == len(self.items) - 1 else page_bottom_for_continuing
                if y + h > tentative_bottom:
                    break
                self.draw_item_row(y, h, self.items[j], j)
                y += h
                j += 1

            if j == i:
                h = min(self.row_height(self.items[i]), page_bottom_for_continuing - y)
                self.draw_item_row(y, h, self.items[i], i)
                y += h
                j += 1

            last_page = j >= len(self.items)
            table_bottom = page_bottom_for_last if last_page else page_bottom_for_continuing
            self.draw_table_grid(table_top, table_bottom)

            if last_page:
                self.draw_totals(grand_total)
            self.footer(page_num)

            if not last_page:
                self.c.showPage()
                page_num += 1
            i = j

        if not self.items:
            self.draw_header_page_1()
            self.draw_table_header(410)
            self.draw_table_grid(410, 671)
            self.draw_totals(0)
            self.footer(1)

        self.c.save()
        return self.output


def generate_invoice_pdf_bytes(invoice_no: str, invoice_date: str, due_date: str, bill_to_lines: Iterable[str], items: List[Dict[str, Any]]) -> bytes:
    buffer = io.BytesIO()
    pdf = InvoicePDF(buffer, invoice_no, invoice_date, due_date, bill_to_lines, items)
    pdf.build()
    buffer.seek(0)
    return buffer.read()


SAMPLE_ITEMS = [
    {"qty": 1, "code": "STFS/FES/0003", "description": "6 LITRE FOAM FIRE EXTINGUISHER SERVICE", "unit_price": 300, "vat": 0, "tax_percent": 0},
    {"qty": 1, "code": "STFS/FES/0006", "description": "9 LITRE WATER FIRE EXTINGUISHER SERVICE", "unit_price": 300, "vat": 0, "tax_percent": 0},
    {"qty": 1, "code": "STFS/FES/0007", "description": "CATRIDGE REPLACEMENT", "unit_price": 2000, "vat": 0, "tax_percent": 0},
    {"qty": 1, "code": "STFS/FES/0008", "description": "CATRIDGE REFILL", "unit_price": 1500, "vat": 0, "tax_percent": 0},
    {"qty": 1, "code": "STFS/FES/0002", "description": "4KG/6KG/9KG DRY CHEMICAL POWDER FIRE EXTINGUISHER SERVICE", "unit_price": 300, "vat": 0, "tax_percent": 0},
    {"qty": 1, "code": "STFS/FES/001", "description": "2KG/5KG CO2 FIRE EXTINGUISHER SERVICE", "unit_price": 300, "vat": 0, "tax_percent": 0},
    {"qty": 1, "code": "STFS/FES/0010", "description": "FIRE BLANKET 4 X 4 SERVICE", "unit_price": 300, "vat": 0, "tax_percent": 0},
    {"qty": 1, "code": "STFS/FES/0011A", "description": "9 KG DRY CHEMICAL POWDER REFILL AND PRESSURIZING", "unit_price": 2500, "vat": 0, "tax_percent": 0},
    {"qty": 1, "code": "STFS/FES/0005", "description": "9 KG DRY POWDER FIRE EXTINGUISHER SERVICE", "unit_price": 300, "vat": 0, "tax_percent": 0},
    {"qty": 1, "code": "STFS/FES/0009", "description": "FIRE ALARM SYSTEM TESTING AND SERVICING", "unit_price": 4500, "vat": 0, "tax_percent": 0},
    {"qty": 1, "code": "STFS/FES/0004", "description": "CALL POINT BREAK GLASS REPLACEMENT", "unit_price": 600, "vat": 0, "tax_percent": 0},
    


]
