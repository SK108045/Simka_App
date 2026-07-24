SIMKA INVOICE WEB APP

What this does:
- Opens a small local web page in your browser.
- Lets a normal user type invoice number, dates, client details, and item rows.
- Generates a PDF invoice using the default SIMKA logo, company details, blue bars, blue table header, grey row shading, totals, balance due, and footer.

Windows:
1. Extract the ZIP folder.
2. Double-click start_windows.bat.
3. The browser should open at http://127.0.0.1:8000.
4. Enter invoice details.
5. Click Generate PDF Invoice.

Mac/Linux:
1. Extract the ZIP folder.
2. Open Terminal in the folder.
3. Run: ./start_mac_linux.sh
4. Open http://127.0.0.1:8000 if it does not open automatically.

Manual run:
python -m pip install -r requirements.txt
python app.py

To stop:
Press CTRL+C in the terminal window.

Files:
- app.py: local web server and form.
- invoice_pdf_core.py: PDF template and layout engine.
- static/simka_logo.jpg: SIMKA logo used in the PDF and web page.
