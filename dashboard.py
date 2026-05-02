"""
Sales & Invoicing System — Team 16 Dashboard
MIS 380, San Diego State University

Section 8: Enterprise (Web) Database Dashboard
Built with Streamlit + SQLite. Uses all 20 reports from Section 6.

To run:
    pip install streamlit pandas
    streamlit run dashboard.py
"""

import sqlite3
from pathlib import Path

import pandas as pd
import streamlit as st

# ----------------------------------------------------------------------
# Page setup
# ----------------------------------------------------------------------
st.set_page_config(
    page_title="Sales & Invoicing Dashboard — Team 16",
    page_icon="📊",
    layout="wide",
)

DB_PATH = Path(__file__).parent / "sales.db"


@st.cache_data
def run_query(sql: str) -> pd.DataFrame:
    """Run a SQL query against sales.db and return a DataFrame."""
    with sqlite3.connect(DB_PATH) as conn:
        return pd.read_sql_query(sql, conn)


# ----------------------------------------------------------------------
# Report definitions (all 20 reports from Section 6, in order 1–20)
# ----------------------------------------------------------------------
REPORTS = {
    "Report 1 — 📦 Products & Unit Prices": {
        "desc": "All products with their category and unit price, ordered most expensive first.",
        "sql": """
            SELECT p.product_id   AS "Product ID",
                   p.product_name AS "Product Name",
                   c.category_name AS "Category",
                   p.unit_price   AS "Unit Price ($)"
            FROM Product p
            JOIN Category c ON p.category_id = c.category_id
            ORDER BY p.unit_price DESC;
        """,
        "kind": "bar",
        "x": "Product Name",
        "y": "Unit Price ($)",
    },
    "Report 2 — 👥 Customer Contacts": {
        "desc": "Full customer list with name, email, and city/state location.",
        "sql": """
            SELECT c.customer_id AS "ID",
                   c.first_name || ' ' || c.last_name AS "Full Name",
                   c.email AS "Email",
                   c.city || ', ' || c.state AS "Location"
            FROM Customer c
            ORDER BY c.last_name, c.first_name;
        """,
        "kind": "table",
    },
    "Report 3 — 🧑‍💼 Employees & Roles": {
        "desc": "All employees with their role and hire date, newest hires first.",
        "sql": """
            SELECT e.employee_id AS "ID",
                   e.first_name || ' ' || e.last_name AS "Full Name",
                   e.role        AS "Role",
                   e.hire_date   AS "Hire Date"
            FROM Employee e
            ORDER BY e.hire_date DESC;
        """,
        "kind": "table",
    },
    "Report 4 — 🧾 All Invoices with Customer": {
        "desc": "Invoices with customer name, transaction date, total, and payment status.",
        "sql": """
            SELECT i.invoice_id      AS "Invoice #",
                   c.first_name || ' ' || c.last_name AS "Customer",
                   i.transaction_date AS "Date",
                   i.total_amount    AS "Total ($)",
                   i.status          AS "Status"
            FROM Invoice i
            JOIN Customer c ON i.customer_id = c.customer_id
            ORDER BY i.transaction_date DESC;
        """,
        "kind": "table",
    },
    "Report 5 — 📊 Inventory Status": {
        "desc": "Current stock levels with low-stock and out-of-stock flags (uses CASE).",
        "sql": """
            SELECT p.product_name AS "Product",
                   p.inventory_qty AS "Stock Qty",
                   CASE
                       WHEN p.inventory_qty = 0 THEN 'OUT OF STOCK'
                       WHEN p.inventory_qty < 20 THEN 'LOW STOCK'
                       ELSE 'In Stock'
                   END AS "Stock Status"
            FROM Product p
            ORDER BY p.inventory_qty ASC;
        """,
        "kind": "bar",
        "x": "Product",
        "y": "Stock Qty",
    },
    "Report 6 — ⚠️ Unpaid & Overdue Invoices": {
        "desc": "Invoices that need follow-up — uses IN ('Unpaid','Partial').",
        "sql": """
            SELECT i.invoice_id                                   AS "Invoice #",
                   c.first_name || ' ' || c.last_name             AS "Customer",
                   i.due_date                                     AS "Due Date",
                   i.total_amount                                 AS "Amount Due ($)",
                   i.status                                       AS "Status"
            FROM Invoice i
            JOIN Customer c ON i.customer_id = c.customer_id
            WHERE i.status IN ('Unpaid', 'Partial')
            ORDER BY i.due_date;
        """,
        "kind": "table",
    },
    "Report 7 — 📝 Invoice Line Items": {
        "desc": "Detail of every line on every invoice — quantity, unit price, line total.",
        "sql": """
            SELECT il.invoice_id  AS "Invoice #",
                   p.product_name AS "Product",
                   il.quantity    AS "Qty",
                   il.unit_price  AS "Unit Price ($)",
                   il.subtotal    AS "Line Total ($)"
            FROM Invoice_Line il
            JOIN Product p ON il.product_id = p.product_id
            ORDER BY il.invoice_id, il.line_id;
        """,
        "kind": "table",
    },
    "Report 8 — 💵 Payment History": {
        "desc": "Every payment ever recorded, newest first, with method.",
        "sql": """
            SELECT p.payment_id    AS "Payment ID",
                   i.invoice_id    AS "Invoice #",
                   p.payment_date  AS "Payment Date",
                   p.amount        AS "Amount ($)",
                   p.payment_method AS "Method"
            FROM Payment p
            JOIN Invoice i ON p.invoice_id = i.invoice_id
            ORDER BY p.payment_date DESC;
        """,
        "kind": "table",
    },
    "Report 9 — 🔔 Payment Reminders Log": {
        "desc": "All reminder messages sent or pending for overdue invoices.",
        "sql": """
            SELECT pr.reminder_id   AS "Reminder ID",
                   pr.invoice_id    AS "Invoice #",
                   pr.reminder_date AS "Reminder Date",
                   pr.sent_status   AS "Status"
            FROM Payment_Reminder pr
            ORDER BY pr.reminder_date DESC;
        """,
        "kind": "table",
    },
    "Report 10 — 📋 Audit Log (Recent Changes)": {
        "desc": "The 10 most recent changes to the database — who changed what, when.",
        "sql": """
            SELECT al.log_id      AS "Log ID",
                   al.table_name AS "Table",
                   al.action     AS "Action",
                   al.record_id  AS "Record ID",
                   al.changed_by AS "Changed By",
                   al.change_date AS "Date/Time"
            FROM Audit_Log al
            ORDER BY al.change_date DESC
            LIMIT 10;
        """,
        "kind": "table",
    },
    "Report 11 — 📅 Monthly Revenue": {
        "desc": "Total subtotal, tax, and revenue collected each month — useful for spotting trends.",
        "sql": """
            SELECT strftime('%Y-%m', i.transaction_date) AS "Month",
                   COUNT(i.invoice_id)              AS "Invoice Count",
                   ROUND(SUM(i.subtotal), 2)        AS "Subtotal ($)",
                   ROUND(SUM(i.tax_amount), 2)      AS "Tax ($)",
                   ROUND(SUM(i.total_amount), 2)    AS "Total Revenue ($)"
            FROM Invoice i
            GROUP BY strftime('%Y-%m', i.transaction_date)
            ORDER BY 1;
        """,
        "kind": "bar",
        "x": "Month",
        "y": "Total Revenue ($)",
    },
    "Report 12 — 🏆 Top Customers by Spending": {
        "desc": "Customers ranked by total dollars spent — your VIPs.",
        "sql": """
            SELECT c.first_name || ' ' || c.last_name AS "Customer Name",
                   COUNT(i.invoice_id)                AS "Total Orders",
                   ROUND(SUM(i.total_amount), 2)      AS "Total Spent ($)"
            FROM Customer c
            JOIN Invoice  i ON c.customer_id = i.customer_id
            GROUP BY c.customer_id
            ORDER BY SUM(i.total_amount) DESC;
        """,
        "kind": "bar",
        "x": "Customer Name",
        "y": "Total Spent ($)",
    },
    "Report 13 — 👤 Sales by Employee": {
        "desc": "Which employees are creating the most invoice revenue (uses LEFT JOIN to include those with zero).",
        "sql": """
            SELECT e.first_name || ' ' || e.last_name AS "Employee",
                   e.role                             AS "Role",
                   COUNT(i.invoice_id)                AS "Invoices Created",
                   ROUND(COALESCE(SUM(i.total_amount), 0), 2) AS "Total Sales ($)"
            FROM Employee e
            LEFT JOIN Invoice i ON e.employee_id = i.employee_id
            GROUP BY e.employee_id
            ORDER BY 4 DESC;
        """,
        "kind": "bar",
        "x": "Employee",
        "y": "Total Sales ($)",
    },
    "Report 14 — 💳 Payment Methods Breakdown": {
        "desc": "How customers are paying you — mix of credit card, check, and cash.",
        "sql": """
            SELECT p.payment_method                AS "Payment Method",
                   COUNT(p.payment_id)             AS "Transaction Count",
                   ROUND(SUM(p.amount), 2)         AS "Total Collected ($)",
                   ROUND(AVG(p.amount), 2)         AS "Avg Payment ($)"
            FROM Payment p
            GROUP BY p.payment_method
            ORDER BY SUM(p.amount) DESC;
        """,
        "kind": "bar",
        "x": "Payment Method",
        "y": "Total Collected ($)",
    },
    "Report 15 — 🏛️ Tax Collected Per Rate": {
        "desc": "Tax collected by jurisdiction — uses LEFT JOIN so unused tax rates still show.",
        "sql": """
            SELECT t.tax_name                                  AS "Tax Name",
                   ROUND(t.tax_rate * 100, 2)                  AS "Rate (%)",
                   COUNT(i.invoice_id)                         AS "Invoices",
                   ROUND(COALESCE(SUM(i.tax_amount), 0), 2)    AS "Tax Collected ($)"
            FROM Tax t
            LEFT JOIN Invoice i ON t.tax_id = i.tax_id
            GROUP BY t.tax_id
            ORDER BY 4 DESC;
        """,
        "kind": "bar",
        "x": "Tax Name",
        "y": "Tax Collected ($)",
    },
    "Report 16 — 💰 Payment Reconciliation": {
        "desc": "Per-invoice balance: what was charged vs. what's been paid (LEFT JOIN + COALESCE).",
        "sql": """
            SELECT i.invoice_id                                   AS "Invoice #",
                   c.first_name || ' ' || c.last_name             AS "Customer",
                   i.total_amount                                 AS "Invoice Total ($)",
                   COALESCE(SUM(p.amount), 0)                     AS "Total Paid ($)",
                   ROUND(i.total_amount - COALESCE(SUM(p.amount), 0), 2) AS "Balance Due ($)",
                   i.status                                       AS "Status"
            FROM Invoice i
            JOIN Customer c ON i.customer_id = c.customer_id
            LEFT JOIN Payment p ON i.invoice_id = p.invoice_id
            GROUP BY i.invoice_id
            ORDER BY i.invoice_id;
        """,
        "kind": "table",
    },
    "Report 17 — 🚫 Products Not Yet Sold": {
        "desc": "Products that have never appeared on an invoice — candidates for promotion.",
        "sql": """
            SELECT p.product_id    AS "Product ID",
                   p.product_name  AS "Product Name",
                   c.category_name AS "Category",
                   p.unit_price    AS "Price ($)"
            FROM Product p
            JOIN Category c ON p.category_id = c.category_id
            LEFT JOIN Invoice_Line il ON p.product_id = il.product_id
            WHERE il.product_id IS NULL
            ORDER BY p.product_name;
        """,
        "kind": "table",
    },
    "Report 18 — 📨 Invoices with Multiple Reminders": {
        "desc": "Invoices that have received more than one payment reminder (HAVING clause).",
        "sql": """
            SELECT pr.invoice_id AS "Invoice #",
                   c.first_name || ' ' || c.last_name AS "Customer",
                   i.total_amount AS "Amount Due ($)",
                   COUNT(pr.reminder_id) AS "Reminders Sent",
                   MAX(pr.reminder_date) AS "Last Reminder"
            FROM Payment_Reminder pr
            JOIN Invoice i ON pr.invoice_id = i.invoice_id
            JOIN Customer c ON i.customer_id = c.customer_id
            GROUP BY pr.invoice_id
            HAVING COUNT(pr.reminder_id) > 1
            ORDER BY COUNT(pr.reminder_id) DESC;
        """,
        "kind": "bar",
        "x": "Customer",
        "y": "Reminders Sent",
    },
    "Report 19 — 🌆 Revenue by Customer City": {
        "desc": "Where your business is concentrated geographically.",
        "sql": """
            SELECT c.city                       AS "City",
                   c.state                      AS "State",
                   COUNT(i.invoice_id)          AS "Invoice Count",
                   ROUND(AVG(i.total_amount),2) AS "Avg Invoice ($)",
                   ROUND(SUM(i.total_amount),2) AS "Total Revenue ($)"
            FROM Customer c
            JOIN Invoice  i ON c.customer_id = i.customer_id
            GROUP BY c.city, c.state
            ORDER BY SUM(i.total_amount) DESC;
        """,
        "kind": "bar",
        "x": "City",
        "y": "Total Revenue ($)",
    },
    "Report 20 — 📈 Business KPI Summary": {
        "desc": "Top-level health check: customers, products in stock, invoices, revenue, employees.",
        "sql": """
            SELECT
              (SELECT COUNT(*) FROM Customer) AS "Total Customers",
              (SELECT COUNT(*) FROM Product WHERE inventory_qty > 0) AS "Products In Stock",
              (SELECT COUNT(*) FROM Invoice) AS "Total Invoices",
              (SELECT COUNT(*) FROM Invoice WHERE status = 'Paid') AS "Paid Invoices",
              (SELECT ROUND(SUM(total_amount),2) FROM Invoice WHERE status='Paid') AS "Revenue Collected ($)",
              (SELECT COUNT(*) FROM Employee) AS "Total Employees";
        """,
        "kind": "kpi",
    },
}

# Key used in the always-on KPI strip below — keep in sync with the dict above
KPI_KEY = "Report 20 — 📈 Business KPI Summary"


# ----------------------------------------------------------------------
# Sidebar — navigation
# ----------------------------------------------------------------------
st.sidebar.title("📊 Sales Dashboard")
st.sidebar.caption("Team 16 — MIS 380")
st.sidebar.markdown("---")

choice = st.sidebar.radio(
    "Select a report:",
    list(REPORTS.keys()),
    label_visibility="collapsed",
)

st.sidebar.markdown("---")
st.sidebar.markdown(
    "**About**\n\n"
    "This dashboard runs reports from Section 6 of our team project, "
    "powered directly by `sales.db` (SQLite)."
)
st.sidebar.markdown(
    "**Team 16**\n\n"
    "- Juliana Weisinger\n"
    "- Abdikarim Farah\n"
    "- Lena Truong"
)


# ----------------------------------------------------------------------
# Header
# ----------------------------------------------------------------------
st.title("Sales & Invoicing System Dashboard")
st.markdown(
    "An interactive dashboard for our small-business sales & invoicing database. "
    "Use the sidebar to navigate between reports."
)
st.markdown("---")


# ----------------------------------------------------------------------
# Always show top KPI strip on every page
# ----------------------------------------------------------------------
kpi = run_query(REPORTS[KPI_KEY]["sql"]).iloc[0]
c1, c2, c3, c4, c5, c6 = st.columns(6)
c1.metric("Customers",          int(kpi["Total Customers"]))
c2.metric("Products In Stock",  int(kpi["Products In Stock"]))
c3.metric("Total Invoices",     int(kpi["Total Invoices"]))
c4.metric("Paid Invoices",      int(kpi["Paid Invoices"]))
c5.metric("Revenue Collected",  f"${kpi['Revenue Collected ($)']:,.2f}")
c6.metric("Employees",          int(kpi["Total Employees"]))
st.markdown("---")


# ----------------------------------------------------------------------
# Selected report view
# ----------------------------------------------------------------------
report = REPORTS[choice]
st.subheader(choice)
st.caption(report["desc"])

with st.expander("View SQL query"):
    st.code(report["sql"].strip(), language="sql")

df = run_query(report["sql"])

if report["kind"] == "kpi":
    # Already shown in the strip above — show as a wide table for completeness
    st.dataframe(df, use_container_width=True, hide_index=True)

elif report["kind"] == "bar":
    left, right = st.columns([3, 2])
    with left:
        st.markdown("**Visualization**")
        chart_df = df.set_index(report["x"])[[report["y"]]]
        st.bar_chart(chart_df, height=400)
    with right:
        st.markdown("**Data**")
        st.dataframe(df, use_container_width=True, hide_index=True, height=400)

else:  # plain table
    st.dataframe(df, use_container_width=True, hide_index=True)

st.caption(f"Returned **{len(df)} rows** — query ran successfully.")
