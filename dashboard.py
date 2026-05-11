"""
Sales & Invoicing System — Team 16 Dashboard (v2)
MIS 380, San Diego State University

Section 8: Enterprise (Web) Database Dashboard
Built with Streamlit + SQLite. Uses all 20 reports from Section 6.
13-table schema with supertype/subtype (Online/Offline Payment) and
multivalued attribute (CustomerPhone).

To run:
    pip install streamlit pandas
    streamlit run dashboard.py
"""

import sqlite3
from pathlib import Path

import pandas as pd
import streamlit as st

st.set_page_config(
    page_title="Sales & Invoicing Dashboard — Team 16",
    page_icon="📊",
    layout="wide",
)

DB_PATH = Path(__file__).parent / "sales.db"


@st.cache_data
def run_query(sql: str) -> pd.DataFrame:
    with sqlite3.connect(DB_PATH) as conn:
        return pd.read_sql_query(sql, conn)


REPORTS = {
    "Report 1 — 📦 Products & Unit Prices": {
        "desc": "All products with category and unit price (highest first).",
        "sql": "SELECT p.product_id AS \"Product ID\", p.product_name AS \"Product Name\", c.category_name AS \"Category\", p.unit_price AS \"Unit Price ($)\" FROM Product p JOIN Category c ON p.category_id = c.category_id ORDER BY p.unit_price DESC;",
        "kind": "bar", "x": "Product Name", "y": "Unit Price ($)",
    },
    "Report 2 — 👥 Customer Contacts": {
        "desc": "All customers with phone from CustomerPhone (LEFT JOIN on multivalued table).",
        "sql": "SELECT c.customer_id AS \"ID\", c.first_name || ' ' || c.last_name AS \"Full Name\", c.email AS \"Email\", cp.phone_number AS \"Phone\", c.city || ', ' || c.state AS \"Location\" FROM Customer c LEFT JOIN CustomerPhone cp ON cp.customer_id = c.customer_id ORDER BY c.last_name, c.first_name;",
        "kind": "table",
    },
    "Report 3 — 🧑‍💼 Employees & Roles": {
        "desc": "All employees with role and hire date (newest first).",
        "sql": "SELECT e.employee_id AS \"ID\", e.first_name || ' ' || e.last_name AS \"Full Name\", e.role AS \"Role\", e.hire_date AS \"Hire Date\" FROM Employee e ORDER BY e.hire_date DESC;",
        "kind": "table",
    },
    "Report 4 — 🧾 All Invoices with Customer": {
        "desc": "Invoices with customer, date, total, and status.",
        "sql": "SELECT i.invoice_id AS \"Invoice #\", c.first_name || ' ' || c.last_name AS \"Customer\", i.transaction_date AS \"Date\", i.total_amount AS \"Total ($)\", i.status AS \"Status\" FROM Invoice i JOIN Customer c ON i.customer_id = c.customer_id ORDER BY i.transaction_date DESC;",
        "kind": "table",
    },
    "Report 5 — 📊 Inventory Status": {
        "desc": "Current stock levels with CASE-based status labels.",
        "sql": "SELECT p.product_name AS \"Product\", p.inventory_qty AS \"Stock Qty\", CASE WHEN p.inventory_qty = 0 THEN 'OUT OF STOCK' WHEN p.inventory_qty < 20 THEN 'LOW STOCK' ELSE 'In Stock' END AS \"Stock Status\" FROM Product p ORDER BY p.inventory_qty ASC;",
        "kind": "bar", "x": "Product", "y": "Stock Qty",
    },
    "Report 6 — ⚠️ Unpaid & Overdue Invoices": {
        "desc": "Invoices needing follow-up (uses IN clause).",
        "sql": "SELECT i.invoice_id AS \"Invoice #\", c.first_name || ' ' || c.last_name AS \"Customer\", i.due_date AS \"Due Date\", i.total_amount AS \"Amount Due ($)\", i.status AS \"Status\" FROM Invoice i JOIN Customer c ON i.customer_id = c.customer_id WHERE i.status IN ('Unpaid', 'Partial') ORDER BY i.due_date;",
        "kind": "table",
    },
    "Report 7 — 📝 Invoice Line Items": {
        "desc": "Detail of every line on every invoice, including discount column.",
        "sql": "SELECT il.invoice_id AS \"Invoice #\", p.product_name AS \"Product\", il.quantity AS \"Qty\", il.unit_price AS \"Unit Price ($)\", il.discount AS \"Discount ($)\", il.subtotal AS \"Line Total ($)\" FROM Invoice_Line il JOIN Invoice i ON il.invoice_id = i.invoice_id JOIN Product p ON il.product_id = p.product_id ORDER BY il.invoice_id, il.line_id;",
        "kind": "table",
    },
    "Report 8 — 💵 Payment History": {
        "desc": "Every payment recorded, with type (Online/Offline) and reference number.",
        "sql": "SELECT p.payment_id AS \"Payment ID\", i.invoice_id AS \"Invoice #\", p.payment_date AS \"Payment Date\", p.amount AS \"Amount ($)\", p.payment_type AS \"Type\", p.reference_num AS \"Reference\" FROM Payment p JOIN Invoice i ON p.invoice_id = i.invoice_id ORDER BY p.payment_date DESC;",
        "kind": "table",
    },
    "Report 9 — 🔔 Payment Reminders Log": {
        "desc": "All reminder messages, newest first.",
        "sql": "SELECT pr.reminder_id AS \"Reminder ID\", pr.invoice_id AS \"Invoice #\", pr.reminder_date AS \"Reminder Date\", pr.sent_status AS \"Status\" FROM Payment_Reminder pr ORDER BY pr.reminder_date DESC;",
        "kind": "table",
    },
    "Report 10 — 📋 Audit Log (Recent Changes)": {
        "desc": "The 10 most recent database changes — who, what, when.",
        "sql": "SELECT al.log_id AS \"Log ID\", al.table_name AS \"Table\", al.action AS \"Action\", al.record_id AS \"Record ID\", al.changed_by AS \"Changed By\", al.change_date AS \"Date/Time\" FROM Audit_Log al ORDER BY al.change_date DESC LIMIT 10;",
        "kind": "table",
    },
    "Report 11 — 📅 Monthly Revenue": {
        "desc": "Revenue, tax, and invoice count grouped by month.",
        "sql": "SELECT strftime('%Y-%m', i.transaction_date) AS \"Month\", COUNT(i.invoice_id) AS \"Invoice Count\", ROUND(SUM(i.subtotal), 2) AS \"Subtotal ($)\", ROUND(SUM(i.tax_amount), 2) AS \"Tax ($)\", ROUND(SUM(i.total_amount), 2) AS \"Total Revenue ($)\" FROM Invoice i GROUP BY strftime('%Y-%m', i.transaction_date) ORDER BY 1;",
        "kind": "bar", "x": "Month", "y": "Total Revenue ($)",
    },
    "Report 12 — 🏆 Top Customers by Spending": {
        "desc": "Customers ranked by total dollars spent.",
        "sql": "SELECT c.first_name || ' ' || c.last_name AS \"Customer Name\", COUNT(i.invoice_id) AS \"Total Orders\", ROUND(SUM(i.total_amount), 2) AS \"Total Spent ($)\" FROM Customer c JOIN Invoice i ON c.customer_id = i.customer_id GROUP BY c.customer_id ORDER BY SUM(i.total_amount) DESC;",
        "kind": "bar", "x": "Customer Name", "y": "Total Spent ($)",
    },
    "Report 13 — 👤 Sales by Employee": {
        "desc": "Which employees are creating the most revenue (LEFT JOIN to include those with zero sales).",
        "sql": "SELECT e.first_name || ' ' || e.last_name AS \"Employee\", e.role AS \"Role\", COUNT(i.invoice_id) AS \"Invoices Created\", ROUND(COALESCE(SUM(i.total_amount), 0), 2) AS \"Total Sales ($)\" FROM Employee e LEFT JOIN Invoice i ON e.employee_id = i.employee_id GROUP BY e.employee_id ORDER BY 4 DESC;",
        "kind": "bar", "x": "Employee", "y": "Total Sales ($)",
    },
    "Report 14 — 💳 Payment Type Summary": {
        "desc": "Online vs. Offline payments — count, total, and average (uses HAVING).",
        "sql": "SELECT p.payment_type AS \"Payment Type\", COUNT(p.payment_id) AS \"Transaction Count\", ROUND(SUM(p.amount), 2) AS \"Total Collected ($)\", ROUND(AVG(p.amount), 2) AS \"Avg Payment ($)\" FROM Payment p GROUP BY p.payment_type HAVING COUNT(p.payment_id) > 0 ORDER BY SUM(p.amount) DESC;",
        "kind": "bar", "x": "Payment Type", "y": "Total Collected ($)",
    },
    "Report 15 — 🏛️ Tax Collected Per Rate": {
        "desc": "Tax collected by jurisdiction (LEFT JOIN keeps unused tax rates visible).",
        "sql": "SELECT t.tax_name AS \"Tax Name\", ROUND(t.tax_rate * 100, 2) AS \"Rate (%)\", COUNT(i.invoice_id) AS \"Invoices\", ROUND(COALESCE(SUM(i.tax_amount), 0), 2) AS \"Tax Collected ($)\" FROM Tax t LEFT JOIN Invoice i ON t.tax_id = i.tax_id GROUP BY t.tax_id ORDER BY 4 DESC;",
        "kind": "bar", "x": "Tax Name", "y": "Tax Collected ($)",
    },
    "Report 16 — 💰 Payment Reconciliation": {
        "desc": "Per-invoice balance with OR/AND filter on status (uses COALESCE for unpaid).",
        "sql": "SELECT i.invoice_id AS \"Invoice #\", c.first_name || ' ' || c.last_name AS \"Customer\", i.total_amount AS \"Invoice Total ($)\", COALESCE(SUM(p.amount), 0) AS \"Total Paid ($)\", i.total_amount - COALESCE(SUM(p.amount), 0) AS \"Balance Due ($)\", i.status AS \"Status\" FROM Invoice i JOIN Customer c ON i.customer_id = c.customer_id LEFT JOIN Payment p ON i.invoice_id = p.invoice_id WHERE i.status = 'Paid' OR i.status IN ('Unpaid', 'Partial') GROUP BY i.invoice_id ORDER BY i.invoice_id;",
        "kind": "table",
    },
    "Report 17 — 🤝 Customers Who Referred Others": {
        "desc": "Self-join on Customer via referred_by — uses BETWEEN and LIKE.",
        "sql": "SELECT c1.first_name || ' ' || c1.last_name AS \"Referring Customer\", c1.email AS \"Email\", c2.first_name || ' ' || c2.last_name AS \"Referred Customer\", c2.created_at AS \"Sign-Up Date\" FROM Customer c1 JOIN Customer c2 ON c1.customer_id = c2.referred_by WHERE c2.created_at BETWEEN '2023-01-01' AND '2024-12-31' AND c1.email LIKE '%@email.com' ORDER BY c1.last_name;",
        "kind": "table",
    },
    "Report 18 — 📨 Invoices with Multiple Reminders": {
        "desc": "Invoices that received >1 reminder — uses EXISTS subquery and HAVING.",
        "sql": "SELECT pr.invoice_id AS \"Invoice #\", c.first_name || ' ' || c.last_name AS \"Customer\", i.total_amount AS \"Amount Due ($)\", COUNT(pr.reminder_id) AS \"Reminders Sent\", MAX(pr.reminder_date) AS \"Last Reminder\" FROM Payment_Reminder pr JOIN Invoice i ON pr.invoice_id = i.invoice_id JOIN Customer c ON i.customer_id = c.customer_id WHERE EXISTS (SELECT 1 FROM Customer cu WHERE cu.customer_id = i.customer_id) GROUP BY pr.invoice_id HAVING COUNT(pr.reminder_id) > 1 ORDER BY COUNT(pr.reminder_id) DESC;",
        "kind": "bar", "x": "Customer", "y": "Reminders Sent",
    },
    "Report 19 — 🔀 Paid vs Unpaid Invoice List": {
        "desc": "UNION of paid and unpaid invoices into a single labeled list.",
        "sql": "SELECT i.invoice_id AS \"Invoice #\", c.first_name || ' ' || c.last_name AS \"Customer\", i.total_amount AS \"Amount ($)\", i.status AS \"Status\", 'Closed' AS \"Category\" FROM Invoice i JOIN Customer c ON i.customer_id = c.customer_id WHERE i.status = 'Paid' UNION SELECT i.invoice_id, c.first_name || ' ' || c.last_name, i.total_amount, i.status, 'Open' FROM Invoice i JOIN Customer c ON i.customer_id = c.customer_id WHERE i.status IN ('Unpaid', 'Partial') ORDER BY \"Category\", \"Invoice #\";",
        "kind": "table",
    },
    "Report 20 — 📈 Business KPI Summary": {
        "desc": "Top-level health metrics: customers, products, invoices, paid count, revenue, employees.",
        "sql": "SELECT (SELECT COUNT(*) FROM Customer) AS \"Total Customers\", (SELECT COUNT(*) FROM Product WHERE inventory_qty > 0) AS \"Products In Stock\", (SELECT COUNT(*) FROM Invoice) AS \"Total Invoices\", (SELECT COUNT(*) FROM Invoice WHERE status = 'Paid') AS \"Paid Invoices\", (SELECT ROUND(SUM(total_amount),2) FROM Invoice WHERE status='Paid') AS \"Revenue Collected ($)\", (SELECT COUNT(*) FROM Employee) AS \"Total Employees\";",
        "kind": "kpi",
    },
}

KPI_KEY = "Report 20 — 📈 Business KPI Summary"


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
    "This dashboard runs all 20 reports from Section 6 of our team project, "
    "powered directly by `sales.db` (SQLite). The database covers a small-business "
    "sales & invoicing workflow across 13 related tables."
)
st.sidebar.markdown(
    "**Team 16**\n\n"
    "- Juliana Weisinger\n"
    "- Abdikarim Farah\n"
    "- Lena Truong"
)


st.title("Sales & Invoicing System Dashboard")
st.markdown(
    "An interactive dashboard for our small-business sales & invoicing database. "
    "Use the sidebar to navigate between all 20 reports."
)
st.markdown("---")


kpi = run_query(REPORTS[KPI_KEY]["sql"]).iloc[0]
c1, c2, c3, c4, c5, c6 = st.columns(6)
c1.metric("Customers",          int(kpi["Total Customers"]))
c2.metric("Products In Stock",  int(kpi["Products In Stock"]))
c3.metric("Total Invoices",     int(kpi["Total Invoices"]))
c4.metric("Paid Invoices",      int(kpi["Paid Invoices"]))
c5.metric("Revenue Collected",  f"${kpi['Revenue Collected ($)']:,.2f}")
c6.metric("Employees",          int(kpi["Total Employees"]))
st.markdown("---")


report = REPORTS[choice]
st.subheader(choice)
st.caption(report["desc"])

with st.expander("View SQL query"):
    st.code(report["sql"].strip(), language="sql")

df = run_query(report["sql"])

if report["kind"] == "kpi":
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

else:
    st.dataframe(df, use_container_width=True, hide_index=True)

st.caption(f"Returned **{len(df)} rows** — query ran successfully.")
