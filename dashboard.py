"""
Sales & Invoicing System — Team 16 Dashboard
MIS 380, San Diego State University

Section 8: Enterprise (Web) Database Dashboard
Built with Streamlit + SQLite. Uses 10 of the 20 reports from Section 6.

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
# Report definitions (the 10 chosen for the dashboard)
# ----------------------------------------------------------------------
REPORTS = {
    "📈 Business KPI Summary (Report 20)": {
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
    "📅 Monthly Revenue (Report 11)": {
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
    "🏆 Top Customers by Spending (Report 12)": {
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
    "👥 Sales by Employee (Report 13)": {
        "desc": "Which employees are creating the most invoice revenue (uses LEFT JOIN to include those with zero).",
        "sql": """
            SELECT e.first_name || ' ' || e.last_name AS "Employee",
                   e.role                             AS "Role",
                   COUNT(i.invoice_id)                AS "Invoices Created",
                   ROUND(COALESCE(SUM(i.total_amount), 0), 2) AS "Total Sales ($)"
            FROM Employee e
            LEFT JOIN Invoice i ON e.employee_id = i.employee_id
            GROUP BY e.employee_id
            ORDER BY SUM(i.total_amount) DESC NULLS LAST;
        """,
        "kind": "bar",
        "x": "Employee",
        "y": "Total Sales ($)",
    },
    "💳 Payment Methods Breakdown (Report 14)": {
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
    "🏛️ Tax Collected Per Rate (Report 15)": {
        "desc": "Tax collected by jurisdiction — uses LEFT JOIN so unused tax rates still show.",
        "sql": """
            SELECT t.tax_name                                  AS "Tax Name",
                   ROUND(t.tax_rate * 100, 2)                  AS "Rate (%)",
                   COUNT(i.invoice_id)                         AS "Invoices",
                   ROUND(COALESCE(SUM(i.tax_amount), 0), 2)    AS "Tax Collected ($)"
            FROM Tax t
            LEFT JOIN Invoice i ON t.tax_id = i.tax_id
            GROUP BY t.tax_id
            ORDER BY SUM(i.tax_amount) DESC NULLS LAST;
        """,
        "kind": "bar",
        "x": "Tax Name",
        "y": "Tax Collected ($)",
    },
    "🌆 Revenue by Customer City (Report 19)": {
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
    "📦 Inventory Status (Report 5)": {
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
    "⚠️ Unpaid & Overdue Invoices (Report 6)": {
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
    "💰 Payment Reconciliation (Report 16)": {
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
}


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
kpi = run_query(REPORTS["📈 Business KPI Summary (Report 20)"]["sql"]).iloc[0]
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
