# How to Run Your Dashboard — Step-by-Step

Hi Juliana — here's everything you need to get the dashboard running on your laptop and grab the screenshots for your report.

## What's in this folder

- **`dashboard.py`** — the Streamlit dashboard application (one file, ~250 lines)
- **`sales.db`** — your SQLite database, fully populated with 100 rows across 10 tables
- **`setup_database.sql`** — the SQL script that built `sales.db` (in case you ever need to rebuild it)
- **`HOW_TO_RUN.md`** — this file

## What the dashboard does

It runs **10 of your 20 Section-6 reports** through a clean web interface. The 10 chosen are the ones that look best as a dashboard (rankings, totals, group-bys — things that chart well). The other 10 reports are still in your team's PDF report and don't need to be in the dashboard.

The 10 reports included are:

1. Business KPI Summary (Report 20) — top-line metrics
2. Monthly Revenue (Report 11)
3. Top Customers by Spending (Report 12)
4. Sales by Employee (Report 13)
5. Payment Methods Breakdown (Report 14)
6. Tax Collected Per Rate (Report 15)
7. Revenue by Customer City (Report 19)
8. Inventory Status (Report 5)
9. Unpaid & Overdue Invoices (Report 6)
10. Payment Reconciliation (Report 16)

---

## Step 1 — Make sure Python is installed

Open **Command Prompt** (press the Windows key, type "cmd", hit Enter) and run:

```
python --version
```

You should see something like `Python 3.10.x` or higher. If you get an error, download Python from <https://www.python.org/downloads/> and re-install (make sure to check **"Add Python to PATH"** during install).

## Step 2 — Install the two libraries the dashboard needs

In the same Command Prompt window, run:

```
pip install streamlit pandas
```

This downloads about 100 MB. It's a one-time install. When it's done you'll see something like `Successfully installed streamlit-x.x.x pandas-x.x.x`.

## Step 3 — Navigate to the project folder

```
cd "C:\Users\figur\Documents\Claude\Projects\MIS 380 Dashboard"
```

(That's the same folder where this file lives.)

## Step 4 — Run the dashboard

```
streamlit run dashboard.py
```

Two things happen:
1. Your terminal will show a message like `You can now view your Streamlit app in your browser. Local URL: http://localhost:8501`
2. Your default browser will open automatically to the dashboard.

If the browser doesn't open on its own, just visit `http://localhost:8501` manually.

## Step 5 — Stopping the dashboard

When you're done, go back to the Command Prompt window and press **Ctrl+C** to shut it down.

---

## Step 6 — Taking screenshots for your report

You need **one screenshot per report (10 total)** showing the report's results retrieved through the dashboard.

For each report in the sidebar:
1. Click the report name in the left sidebar.
2. Wait for the page to load (it's instant).
3. Press **Windows key + Shift + S** → drag a box around the dashboard area → the screenshot copies to your clipboard.
4. Paste it into your team's project report (Section 8) with a label like "Dashboard Report 1: Business KPI Summary."

Tip: expand the **"View SQL query"** section before screenshotting so the SQL is visible alongside the chart and table — graders love that.

## Step 7 — Submitting

Per the requirements, Section 8 needs:

- A short description of the dashboard ✓ *(use the text in the "What the dashboard does" section above, or write your own)*
- The application running with no errors ✓ *(test it on your laptop before the demo)*
- At least 10 reports utilized ✓ *(we have exactly 10)*
- Screenshots for all 10 reports ✓ *(see Step 6)*

You'll also want to include `dashboard.py` and `sales.db` in your final submission so the grader can re-run it.

---

## Troubleshooting

**"`streamlit` is not recognized as a command"** — Python's Scripts folder isn't on your PATH. The simplest fix:

```
python -m streamlit run dashboard.py
```

**"unable to open database file"** — make sure you're in the right folder. Run `dir` in Command Prompt and confirm you see `sales.db` in the list.

**Charts look weird or numbers are wrong** — close the browser tab, stop the server (Ctrl+C), and re-run `streamlit run dashboard.py`. The cache will clear.

**Need to rebuild `sales.db` from scratch** — delete `sales.db`, then in Python:

```python
import sqlite3
conn = sqlite3.connect("sales.db")
with open("setup_database.sql") as f:
    conn.executescript(f.read())
conn.commit()
conn.close()
```

---

## Talking points for your team / instructor

- **Built with Python + Streamlit** (per the rubric: "you can find and use software, online services, or programming codes based on your knowledge")
- **Database** is the same SQLite file we built in Section 5; the dashboard runs the actual SQL queries from Section 6 — no fake data.
- **10 reports** drawn from the 20 in Section 6, chosen for visual impact.
- **All queries run live** against `sales.db` — change a row in the database and the dashboard will reflect it on the next reload.

Good luck with the submission! 🎉
