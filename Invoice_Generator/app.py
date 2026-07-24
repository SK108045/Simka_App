from __future__ import annotations

import html
import json
import mimetypes
import os
import sys
import threading
import traceback
import urllib.parse
import webbrowser
from datetime import datetime, timedelta
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

from invoice_pdf_core import (
    COMPANY_ADDRESS_1,
    COMPANY_ADDRESS_2,
    COMPANY_NAME,
    COMPANY_PHONE,
    SAMPLE_ITEMS,
    generate_invoice_pdf_bytes,
    parse_money,
    sanitize_item,
)

BASE_DIR = Path(__file__).resolve().parent
HOST = os.environ.get("SIMKA_HOST", "127.0.0.1")
PORT = int(os.environ.get("SIMKA_PORT", "8000"))


def today_text(days_add: int = 0) -> str:
    return (datetime.now() + timedelta(days=days_add)).strftime("%d %B %Y")


def esc(value) -> str:
    return html.escape(str(value or ""), quote=True)


def render_page(error: str = "") -> bytes:
    today = today_text(0)
    due = today_text(30)
    sample_items_json = json.dumps(SAMPLE_ITEMS)
    error_html = f'<div class="alert">{esc(error)}</div>' if error else ""
    # Build datalist options from all unique descriptions in SAMPLE_ITEMS
    seen_descs: set[str] = set()
    desc_option_tags: list[str] = []
    for item in SAMPLE_ITEMS:
        d = item.get("description", "").strip()
        if d and d not in seen_descs:
            seen_descs.add(d)
            desc_option_tags.append(f'<option value="{esc(d)}">')
    desc_options_html = "\n  ".join(desc_option_tags)
    desc_options_json = json.dumps(list(seen_descs))
    # Build description → {code, unit_price} map for auto-fill
    desc_map: dict[str, dict] = {}
    for item in SAMPLE_ITEMS:
        d = item.get("description", "").strip()
        if d:
            desc_map[d] = {"code": item.get("code", ""), "unit_price": item.get("unit_price", "")}
    desc_map_json = json.dumps(desc_map)
    body = f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>SIMKA Invoice Generator</title>
  <style>
    :root {{
      --dark-blue: #1f548f;
      --light-blue: #538ed7;
      --grey: #e0e0e0;
      --border: #1f2937;
      --bg: #f3f6fb;
    }}
    * {{ box-sizing: border-box; }}
    body {{
      margin: 0;
      font-family: Arial, Helvetica, sans-serif;
      background: var(--bg);
      color: #111827;
    }}
    .topbar {{
      background: var(--dark-blue);
      color: white;
      padding: 18px 24px;
      font-weight: 700;
      letter-spacing: .2px;
    }}
    .wrap {{ max-width: 1180px; margin: 24px auto; padding: 0 18px; }}
    .card {{
      background: white;
      border-radius: 14px;
      box-shadow: 0 10px 30px rgba(15, 23, 42, .12);
      padding: 22px;
      margin-bottom: 18px;
    }}
    .header-row {{ display: flex; gap: 18px; align-items: center; flex-wrap: wrap; }}
    .logo {{ width: 76px; height: 80px; object-fit: contain; }}
    h1 {{ margin: 0; font-size: 24px; }}
    .muted {{ color: #4b5563; line-height: 1.45; }}
    .fixed-box {{ border-left: 7px solid var(--dark-blue); padding-left: 14px; }}
    .grid {{ display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 14px; }}
    .grid2 {{ display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }}
    label {{ display: block; font-size: 13px; font-weight: 700; margin-bottom: 6px; color: #374151; }}
    input, textarea {{
      width: 100%;
      border: 1px solid #cbd5e1;
      border-radius: 10px;
      padding: 10px 11px;
      font-size: 14px;
      outline: none;
      background: white;
    }}
    input:focus, textarea:focus {{ border-color: var(--light-blue); box-shadow: 0 0 0 3px rgba(83, 142, 215, .18); }}
    textarea {{ min-height: 94px; resize: vertical; }}
    table {{ width: 100%; border-collapse: collapse; margin-top: 12px; }}
    th {{ background: var(--light-blue); color: #111; text-align: left; font-size: 13px; padding: 9px 7px; border: 1px solid var(--border); }}
    td {{ border: 1px solid #cbd5e1; padding: 6px; vertical-align: top; }}
    tr:nth-child(even) td {{ background: var(--grey); }}
    td input {{ border-radius: 7px; padding: 8px; }}
    .desc-cell {{ display:flex; flex-direction:column; gap:4px; min-width:200px; }}
    .desc-select {{
      width:100%; border:1px solid #cbd5e1; border-radius:7px;
      padding:8px; font-size:14px; background:white; cursor:pointer;
      color:#374151;
    }}
    .desc-select:focus {{ border-color:var(--light-blue); box-shadow:0 0 0 3px rgba(83,142,215,.18); outline:none; }}
    .desc-custom {{ display:none; }}
    .desc-custom.visible {{ display:block; }}
    .actions {{ display: flex; flex-wrap: wrap; gap: 10px; margin-top: 16px; align-items: center; }}
    button, .button {{
      border: 0;
      border-radius: 10px;
      padding: 11px 16px;
      font-weight: 700;
      cursor: pointer;
      background: var(--dark-blue);
      color: white;
      text-decoration: none;
      display: inline-block;
    }}
    button.secondary {{ background: #334155; }}
    button.light {{ background: #e5e7eb; color: #111827; }}
    button.danger {{ background: #b91c1c; padding: 8px 10px; }}
    .alert {{ background: #fee2e2; color: #991b1b; padding: 12px 14px; border-radius: 10px; margin-bottom: 16px; font-weight: 700; }}
    .small {{ font-size: 12px; color: #64748b; }}
    @media (max-width: 760px) {{ .grid, .grid2 {{ grid-template-columns: 1fr; }} table {{ font-size: 12px; }} }}
  </style>
</head>
<body>
  <div class="topbar">SIMKA Technologies Fire Services - Web Invoice Generator</div>
  <div class="wrap">
    {error_html}
    <div class="card">
      <div class="header-row">
        <img class="logo" src="/static/simka_logo.jpg" alt="SIMKA logo">
        <div class="fixed-box">
          <h1>Default SIMKA invoice template</h1>
          <div class="muted">
            <strong>{esc(COMPANY_NAME)}</strong><br>
            {esc(COMPANY_ADDRESS_1)}<br>
            {esc(COMPANY_ADDRESS_2)}<br>
            {esc(COMPANY_PHONE)}
          </div>
        </div>
      </div>
      <p class="small">Company details, logo, blue bars, table header, grey row shading, totals, and footer are locked into the PDF generator.</p>
    </div>

<form method="post" action="/preview" target="_blank">
      <div class="card">
        <h2>Invoice details</h2>
        <div class="grid" style="grid-template-columns: repeat(4, minmax(0, 1fr))">
          <div>
            <label>Invoice No.</label>
            <input name="invoice_no" value="1004" required>
          </div>
          <div>
            <label>Date</label>
            <input name="invoice_date" id="invoice_date" value="{esc(today)}" required
              oninput="calcDueDate()">
          </div>
          <div>
            <label>Net Days <span style="font-weight:400;color:#64748b"></span></label>
            <input type="number" id="net_days" value="30" min="0" max="365"
              placeholder="30" oninput="calcDueDate()"
              style="background:#eff6ff;border-color:#93c5fd;">
          </div>
          <div>
            <label>Due Date</label>
            <input name="due_date" id="due_date" value="{esc(due)}" required>
          </div>
        </div>
      </div>

      <div class="card">
        <h2>Bill To</h2>
        <div class="grid2">
          <div>
            <label>Client name and address</label>
            <textarea name="bill_to" required>CONSOLATA SEMINARY
Off Magadi Road,Behind Brookhouse
School</textarea>
          </div>
          <div class="muted">
            <label>How to type it</label>
            Put each address line on a new line. The PDF will place this under the default blue Bill To line.
          </div>
        </div>
      </div>

      <div class="card">
        <h2>Items</h2>
        <div class="small">Leave VAT and TAX % as 0 when they do not apply.</div>
        <table id="itemsTable">
          <thead>
            <tr>
              <th style="width:70px">Qty</th>
              <th style="width:160px">Item</th>
              <th>Description</th>
              <th style="width:130px">Unit Price</th>
              <th style="width:100px">VAT</th>
              <th style="width:90px">TAX %</th>
              <th style="width:80px">Remove</th>
            </tr>
          </thead>
          <tbody id="itemRows"></tbody>
        </table>
        <div class="actions">
          <button type="button" onclick="addRow()">Add item row</button>
          <button type="button" class="secondary" onclick="loadSample()">Load sample rows</button>
          <button type="button" class="light" onclick="clearRows()">Clear rows</button>
        </div>
      </div>

      <div class="card">
        <div class="actions">
<button type="submit">Preview PDF Invoice</button>
<button type="submit" formaction="/generate" target="_self" class="secondary">Download PDF</button>
          <span class="small">The PDF downloads immediately after clicking generate.</span>
        </div>
      </div>
    </form>
  </div>
<script>
const sampleItems = {sample_items_json};
const DESC_OPTIONS = {desc_options_json};
const DESC_MAP = {desc_map_json};
function cellInput(name, value, placeholder) {{
  return `<input name="${{name}}" value="${{String(value ?? '').replaceAll('"','&quot;')}}" placeholder="${{placeholder||''}}">`;

}}
function descInput(value) {{
  const isCustom = value && !DESC_OPTIONS.includes(value);
  const opts = DESC_OPTIONS.map(d =>
    `<option value="${{d.replaceAll('"','&quot;')}}"${{d===value?' selected':''}}>` +
    d.substring(0,60) + (d.length>60?'...':'') +
    `</option>`
  ).join('');
  return `<div class="desc-cell">
    <input type="hidden" name="description" class="desc-hidden" value="${{String(value??'').replaceAll('"','&quot;')}}"/>
    <select class="desc-select" onchange="onDescChange(this)">
      <option value="">-- Select description --</option>
      ${{opts}}
      <option value="__custom__"${{isCustom?' selected':''}}>✏️ Type custom...</option>
    </select>
    <input class="desc-custom${{isCustom?' visible':''}}" placeholder="Enter custom description"
      value="${{isCustom?String(value??'').replaceAll('"','&quot;'):''}}"
      oninput="this.closest('.desc-cell').querySelector('.desc-hidden').value=this.value"/>
  </div>`;
}}
function onDescChange(sel) {{
  const cell = sel.closest('.desc-cell');
  const hidden = cell.querySelector('.desc-hidden');
  const custom = cell.querySelector('.desc-custom');
  const tr = sel.closest('tr');
  if (sel.value === '__custom__') {{
    custom.classList.add('visible');
    custom.focus();
    hidden.value = custom.value;
  }} else {{
    custom.classList.remove('visible');
    hidden.value = sel.value;
    // Auto-fill Item code and Unit Price from the map
    const match = DESC_MAP[sel.value];
    if (match && tr) {{
      const codeInput = tr.querySelector('input[name="code"]');
      const priceInput = tr.querySelector('input[name="unit_price"]');
      if (codeInput && match.code) codeInput.value = match.code;
      if (priceInput && match.unit_price !== undefined) priceInput.value = match.unit_price;
    }}
  }}
}}
function addRow(item={{}}) {{
  const tr = document.createElement('tr');
  tr.innerHTML = `
    <td>${{cellInput('qty', item.qty??'', '1')}}</td>
    <td>${{cellInput('code', item.code??'', 'STFS/FES/0003')}}</td>
    <td>${{descInput(item.description??'')}}</td>
    <td>${{cellInput('unit_price', item.unit_price??'', '300')}}</td>
    <td>${{cellInput('vat', item.vat??0, '0')}}</td>
    <td>${{cellInput('tax_percent', item.tax_percent??0, '0')}}</td>
    <td><button type="button" class="danger" onclick="this.closest('tr').remove()">X</button></td>
  `;
  document.getElementById('itemRows').appendChild(tr);
}}
function clearRows() {{
  document.getElementById('itemRows').innerHTML='';
  addRow();
}}
function loadSample() {{
  document.getElementById('itemRows').innerHTML='';
  sampleItems.forEach(addRow);
}}
addRow();
function calcDueDate() {{
  const dateStr = document.getElementById('invoice_date').value.trim();
  const days = parseInt(document.getElementById('net_days').value, 10);
  if (!dateStr || isNaN(days)) return;
  // Parse date formats like "23 June 2026" or "2026-06-23"
  const d = new Date(dateStr);
  if (isNaN(d.getTime())) return;
  d.setDate(d.getDate() + days);
  const months = ['January','February','March','April','May','June',
                  'July','August','September','October','November','December'];
  document.getElementById('due_date').value =
    d.getDate() + ' ' + months[d.getMonth()] + ' ' + d.getFullYear();
}}
</script>
</body>
</html>"""
    return body.encode("utf-8")


class Handler(BaseHTTPRequestHandler):
    server_version = "SIMKAInvoiceHTTP/1.0"

    def log_message(self, format, *args):
        return

    def send_bytes(self, status: int, body: bytes, content_type: str, headers: dict[str, str] | None = None):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        if headers:
            for key, value in headers.items():
                self.send_header(key, value)
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/":
            return self.send_bytes(200, render_page(), "text/html; charset=utf-8")
        if parsed.path.startswith("/static/"):
            rel = parsed.path.lstrip("/")
            path = (BASE_DIR / rel).resolve()
            if not str(path).startswith(str(BASE_DIR.resolve())) or not path.exists():
                return self.send_bytes(404, b"Not found", "text/plain")
            ctype = mimetypes.guess_type(str(path))[0] or "application/octet-stream"
            return self.send_bytes(200, path.read_bytes(), ctype)
        return self.send_bytes(404, b"Not found", "text/plain")

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path not in ("/generate", "/preview"):
            return self.send_bytes(404, b"Not found", "text/plain")
        try:
            length = int(self.headers.get("Content-Length", "0"))
            raw = self.rfile.read(length).decode("utf-8", errors="replace")
            form = urllib.parse.parse_qs(raw, keep_blank_values=True)

            invoice_no = form.get("invoice_no", [""])[0].strip()
            invoice_date = form.get("invoice_date", [""])[0].strip()
            due_date = form.get("due_date", [""])[0].strip()
            bill_to_text = form.get("bill_to", [""])[0]
            bill_to_lines = [line.strip() for line in bill_to_text.splitlines() if line.strip()]

            qtys = form.get("qty", [])
            codes = form.get("code", [])
            descs = form.get("description", [])
            units = form.get("unit_price", [])
            vats = form.get("vat", [])
            taxes = form.get("tax_percent", [])

            max_len = max(len(qtys), len(codes), len(descs), len(units), len(vats), len(taxes), 0)
            items = []
            for i in range(max_len):
                raw_item = {
                    "qty": qtys[i] if i < len(qtys) else "",
                    "code": codes[i] if i < len(codes) else "",
                    "description": descs[i] if i < len(descs) else "",
                    "unit_price": units[i] if i < len(units) else "",
                    "vat": vats[i] if i < len(vats) else 0,
                    "tax_percent": taxes[i] if i < len(taxes) else 0,
                }
                try:
                    items.append(sanitize_item(raw_item))
                except ValueError as exc:
                    if str(exc) == "Empty item row":
                        continue
                    raise

            if not invoice_no or not invoice_date or not due_date or not bill_to_lines:
                raise ValueError("Invoice number, date, due date, and Bill To details are required.")
            if not items:
                raise ValueError("Add at least one item row before generating the invoice.")

            pdf_bytes = generate_invoice_pdf_bytes(invoice_no, invoice_date, due_date, bill_to_lines, items)
            safe_no = "".join(ch for ch in invoice_no if ch.isalnum() or ch in ("-", "_")) or "invoice"
            filename = f"SIMKA_Invoice_{safe_no}.pdf"
            if parsed.path == "/preview":
                disposition = f'inline; filename="{filename}"'
            else:
                disposition = f'attachment; filename="{filename}"'
            
            return self.send_bytes(
                200,
                pdf_bytes,
                "application/pdf",
                {"Content-Disposition": disposition},
            )   
        except Exception as exc:
            message = f"Could not generate invoice: {exc}"
            print(message, file=sys.stderr)
            traceback.print_exc()
            return self.send_bytes(400, render_page(message), "text/html; charset=utf-8")


def main():
    server = HTTPServer((HOST, PORT), Handler)
    url = f"http://{HOST}:{PORT}"
    print(f"SIMKA Invoice Web App is running at {url}")
    print("Press CTRL+C to stop.")
    if os.environ.get("SIMKA_NO_BROWSER") != "1":
        threading.Timer(0.8, lambda: webbrowser.open(url)).start()
    server.serve_forever()


if __name__ == "__main__":
    main()
