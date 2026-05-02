-- =====================================================================
-- Sales & Invoicing System Database — Team 16, MIS 380
-- Rebuild script for sales.db
-- =====================================================================

-- Drop existing tables (so this script can be re-run cleanly)
DROP TABLE IF EXISTS Audit_Log;
DROP TABLE IF EXISTS Payment_Reminder;
DROP TABLE IF EXISTS Payment;
DROP TABLE IF EXISTS Invoice_Line;
DROP TABLE IF EXISTS Invoice;
DROP TABLE IF EXISTS Product;
DROP TABLE IF EXISTS Customer;
DROP TABLE IF EXISTS Employee;
DROP TABLE IF EXISTS Tax;
DROP TABLE IF EXISTS Category;

-- =====================================================================
-- Section 5.1 — DDL
-- =====================================================================

-- 1. Category
CREATE TABLE Category (
    category_id   INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL,
    description   TEXT
);

-- 2. Tax
CREATE TABLE Tax (
    tax_id         INTEGER PRIMARY KEY,
    tax_name       TEXT NOT NULL,
    tax_rate       REAL NOT NULL,
    effective_date TEXT NOT NULL
);

-- 3. Employee
CREATE TABLE Employee (
    employee_id INTEGER PRIMARY KEY,
    first_name  TEXT NOT NULL,
    last_name   TEXT NOT NULL,
    email       TEXT UNIQUE NOT NULL,
    phone       TEXT,
    hire_date   TEXT NOT NULL,
    role        TEXT
);

-- 4. Customer
CREATE TABLE Customer (
    customer_id INTEGER PRIMARY KEY,
    first_name  TEXT NOT NULL,
    last_name   TEXT NOT NULL,
    email       TEXT UNIQUE NOT NULL,
    phone       TEXT,
    address     TEXT,
    city        TEXT,
    state       TEXT,
    zip_code    TEXT,
    created_at  TEXT NOT NULL
);

-- 5. Product
CREATE TABLE Product (
    product_id    INTEGER PRIMARY KEY,
    category_id   INTEGER NOT NULL,
    product_name  TEXT NOT NULL,
    description   TEXT,
    unit_price    REAL NOT NULL,
    inventory_qty INTEGER NOT NULL DEFAULT 0,
    CHECK (inventory_qty >= 0),
    CONSTRAINT FK_Product_Category FOREIGN KEY (category_id)
        REFERENCES Category(category_id)
);

-- 6. Invoice
CREATE TABLE Invoice (
    invoice_id       INTEGER PRIMARY KEY,
    customer_id      INTEGER NOT NULL,
    employee_id      INTEGER,
    tax_id           INTEGER NOT NULL,
    transaction_date TEXT NOT NULL,
    due_date         TEXT NOT NULL,
    subtotal         REAL NOT NULL DEFAULT 0.00,
    tax_amount       REAL NOT NULL DEFAULT 0.00,
    total_amount     REAL NOT NULL DEFAULT 0.00,
    status           TEXT NOT NULL DEFAULT 'Unpaid',
    CONSTRAINT FK_Invoice_Customer FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    CONSTRAINT FK_Invoice_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id),
    CONSTRAINT FK_Invoice_Tax      FOREIGN KEY (tax_id)      REFERENCES Tax(tax_id)
);

-- 7. Invoice_Line
CREATE TABLE Invoice_Line (
    line_id     INTEGER PRIMARY KEY,
    invoice_id  INTEGER NOT NULL,
    product_id  INTEGER NOT NULL,
    quantity    INTEGER NOT NULL,
    unit_price  REAL NOT NULL,
    subtotal    REAL NOT NULL DEFAULT 0.00,
    CHECK (quantity > 0),
    CONSTRAINT FK_InvLine_Invoice FOREIGN KEY (invoice_id) REFERENCES Invoice(invoice_id),
    CONSTRAINT FK_InvLine_Product FOREIGN KEY (product_id) REFERENCES Product(product_id)
);

-- 8. Payment
CREATE TABLE Payment (
    payment_id     INTEGER PRIMARY KEY,
    invoice_id     INTEGER NOT NULL,
    payment_date   TEXT NOT NULL,
    amount         REAL NOT NULL,
    payment_method TEXT NOT NULL,
    CHECK (amount > 0),
    CONSTRAINT FK_Payment_Invoice FOREIGN KEY (invoice_id) REFERENCES Invoice(invoice_id)
);

-- 9. Payment_Reminder
CREATE TABLE Payment_Reminder (
    reminder_id   INTEGER PRIMARY KEY,
    invoice_id    INTEGER NOT NULL,
    reminder_date TEXT NOT NULL,
    message       TEXT NOT NULL,
    sent_status   TEXT NOT NULL DEFAULT 'Pending',
    CONSTRAINT FK_Reminder_Invoice FOREIGN KEY (invoice_id) REFERENCES Invoice(invoice_id)
);

-- 10. Audit_Log
CREATE TABLE Audit_Log (
    log_id      INTEGER PRIMARY KEY,
    table_name  TEXT NOT NULL,
    action      TEXT NOT NULL,
    record_id   INTEGER NOT NULL,
    changed_by  TEXT NOT NULL,
    change_date TEXT NOT NULL,
    notes       TEXT
);

-- =====================================================================
-- Section 5.2 — INSERTs (100 rows total, 10 per table)
-- =====================================================================

-- 1. Category
INSERT INTO Category (category_name, description) VALUES ('Electronics',     'Electronic devices and accessories');
INSERT INTO Category (category_name, description) VALUES ('Office Supplies', 'Stationary and office materials');
INSERT INTO Category (category_name, description) VALUES ('Furniture',       'Desks, chairs, and shelving');
INSERT INTO Category (category_name, description) VALUES ('Software',        'Licensed software products');
INSERT INTO Category (category_name, description) VALUES ('Networking',      'Routers, switches, cables');
INSERT INTO Category (category_name, description) VALUES ('Printing',        'Printers, ink, and paper');
INSERT INTO Category (category_name, description) VALUES ('Storage',         'USB drives, hard disks, memory cards');
INSERT INTO Category (category_name, description) VALUES ('Audio/Visual',    'Speakers, monitors, webcams');
INSERT INTO Category (category_name, description) VALUES ('Cleaning',        'Office cleaning supplies');
INSERT INTO Category (category_name, description) VALUES ('Security',        'Cameras and access control devices');

-- 2. Tax
INSERT INTO Tax (tax_name, tax_rate, effective_date) VALUES ('CA State Tax',    0.0725, '2023-01-01');
INSERT INTO Tax (tax_name, tax_rate, effective_date) VALUES ('CA County Tax',   0.0100, '2023-01-01');
INSERT INTO Tax (tax_name, tax_rate, effective_date) VALUES ('No Tax',          0.0000, '2023-01-01');
INSERT INTO Tax (tax_name, tax_rate, effective_date) VALUES ('TX State Tax',    0.0625, '2023-01-01');
INSERT INTO Tax (tax_name, tax_rate, effective_date) VALUES ('NY State Tax',    0.0800, '2023-01-01');
INSERT INTO Tax (tax_name, tax_rate, effective_date) VALUES ('FL State Tax',    0.0600, '2023-01-01');
INSERT INTO Tax (tax_name, tax_rate, effective_date) VALUES ('WA State Tax',    0.0650, '2023-01-01');
INSERT INTO Tax (tax_name, tax_rate, effective_date) VALUES ('OR No Sales Tax', 0.0000, '2023-01-01');
INSERT INTO Tax (tax_name, tax_rate, effective_date) VALUES ('NV State Tax',    0.0685, '2023-01-01');
INSERT INTO Tax (tax_name, tax_rate, effective_date) VALUES ('AZ State Tax',    0.0560, '2023-01-01');

-- 3. Employee
INSERT INTO Employee (first_name, last_name, email, phone, hire_date, role) VALUES ('Alice', 'Johnson',  'alice.johnson@chinook.com',  '619-555-0101', '2020-03-15', 'Sales Rep');
INSERT INTO Employee (first_name, last_name, email, phone, hire_date, role) VALUES ('Brian', 'Martinez', 'brian.martinez@chinook.com', '619-555-0102', '2019-07-01', 'Sales Manager');
INSERT INTO Employee (first_name, last_name, email, phone, hire_date, role) VALUES ('Carol', 'Smith',    'carol.smith@chinook.com',    '619-555-0103', '2021-01-20', 'Accountant');
INSERT INTO Employee (first_name, last_name, email, phone, hire_date, role) VALUES ('David', 'Lee',      'david.lee@chinook.com',      '619-555-0104', '2022-06-10', 'Sales Rep');
INSERT INTO Employee (first_name, last_name, email, phone, hire_date, role) VALUES ('Elena', 'Nguyen',   'elena.nguyen@chinook.com',   '619-555-0105', '2021-09-05', 'Customer Service');
INSERT INTO Employee (first_name, last_name, email, phone, hire_date, role) VALUES ('Frank', 'Brown',    'frank.brown@chinook.com',    '619-555-0106', '2018-11-30', 'Warehouse Staff');
INSERT INTO Employee (first_name, last_name, email, phone, hire_date, role) VALUES ('Grace', 'Wilson',   'grace.wilson@chinook.com',   '619-555-0107', '2023-02-14', 'Sales Rep');
INSERT INTO Employee (first_name, last_name, email, phone, hire_date, role) VALUES ('Henry', 'Taylor',   'henry.taylor@chinook.com',   '619-555-0108', '2020-08-22', 'IT Support');
INSERT INTO Employee (first_name, last_name, email, phone, hire_date, role) VALUES ('Irene', 'Davis',    'irene.davis@chinook.com',    '619-555-0109', '2017-04-18', 'Store Manager');
INSERT INTO Employee (first_name, last_name, email, phone, hire_date, role) VALUES ('James', 'Anderson', 'james.anderson@chinook.com', '619-555-0110', '2022-12-01', 'Sales Rep');

-- 4. Customer
INSERT INTO Customer (first_name, last_name, email, phone, address, city, state, zip_code, created_at) VALUES ('Omar',    'Hassan',   'omar.hassan@email.com',    '619-444-0201', '123 Main St',    'El Cajon',      'CA', '92020', '2023-01-10');
INSERT INTO Customer (first_name, last_name, email, phone, address, city, state, zip_code, created_at) VALUES ('Priya',   'Patel',    'priya.patel@email.com',    '619-444-0202', '456 Oak Ave',    'San Diego',     'CA', '92101', '2023-02-14');
INSERT INTO Customer (first_name, last_name, email, phone, address, city, state, zip_code, created_at) VALUES ('Carlos',  'Reyes',    'carlos.reyes@email.com',   '619-444-0203', '789 Pine Rd',    'Chula Vista',   'CA', '91910', '2023-03-05');
INSERT INTO Customer (first_name, last_name, email, phone, address, city, state, zip_code, created_at) VALUES ('Sarah',   'Kim',      'sarah.kim@email.com',      '619-444-0204', '321 Elm St',     'La Mesa',       'CA', '91942', '2023-04-20');
INSERT INTO Customer (first_name, last_name, email, phone, address, city, state, zip_code, created_at) VALUES ('Marcus',  'Williams', 'marcus.w@email.com',       '619-444-0205', '654 Cedar Blvd', 'Santee',        'CA', '92071', '2023-05-11');
INSERT INTO Customer (first_name, last_name, email, phone, address, city, state, zip_code, created_at) VALUES ('Fatima',  'Al-Amin',  'fatima.alamin@email.com',  '619-444-0206', '987 Birch Ln',   'Spring Valley', 'CA', '91977', '2023-06-02');
INSERT INTO Customer (first_name, last_name, email, phone, address, city, state, zip_code, created_at) VALUES ('Daniel',  'Torres',   'daniel.torres@email.com',  '619-444-0207', '111 Maple Dr',   'El Cajon',      'CA', '92021', '2023-07-19');
INSERT INTO Customer (first_name, last_name, email, phone, address, city, state, zip_code, created_at) VALUES ('Aisha',   'Okonkwo',  'aisha.okon@email.com',     '619-444-0208', '222 Walnut Ave', 'San Diego',     'CA', '92103', '2023-08-08');
INSERT INTO Customer (first_name, last_name, email, phone, address, city, state, zip_code, created_at) VALUES ('Kevin',   'Nguyen',   'kevin.nguyen@email.com',   '619-444-0209', '333 Spruce St',  'Lemon Grove',   'CA', '91945', '2023-09-15');
INSERT INTO Customer (first_name, last_name, email, phone, address, city, state, zip_code, created_at) VALUES ('Linda',   'Cooper',   'linda.cooper@email.com',   '619-444-0210', '444 Ash Ct',     'San Diego',     'CA', '92105', '2023-10-30');

-- 5. Product
INSERT INTO Product (category_id, product_name, description, unit_price, inventory_qty) VALUES (1,  'Laptop Pro 15',        '15-inch business laptop',         1199.99, 50);
INSERT INTO Product (category_id, product_name, description, unit_price, inventory_qty) VALUES (1,  'Wireless Mouse',       'Ergonomic wireless mouse',          29.99, 200);
INSERT INTO Product (category_id, product_name, description, unit_price, inventory_qty) VALUES (2,  'Ballpoint Pens (12)',  'Box of 12 ballpoint pens',           5.99, 500);
INSERT INTO Product (category_id, product_name, description, unit_price, inventory_qty) VALUES (3,  'Office Chair',         'Adjustable ergonomic chair',       249.99, 30);
INSERT INTO Product (category_id, product_name, description, unit_price, inventory_qty) VALUES (4,  'Antivirus License',    '1-year antivirus subscription',     59.99, 999);
INSERT INTO Product (category_id, product_name, description, unit_price, inventory_qty) VALUES (5,  'Wi-Fi Router',         'Dual-band gigabit router',          89.99, 75);
INSERT INTO Product (category_id, product_name, description, unit_price, inventory_qty) VALUES (6,  'Inkjet Printer',       'Color inkjet all-in-one printer',  149.99, 40);
INSERT INTO Product (category_id, product_name, description, unit_price, inventory_qty) VALUES (7,  'USB Flash Drive 64GB', '64GB USB 3.0 flash drive',          12.99, 300);
INSERT INTO Product (category_id, product_name, description, unit_price, inventory_qty) VALUES (8,  'HD Webcam',            '1080p USB webcam with mic',         49.99, 120);
INSERT INTO Product (category_id, product_name, description, unit_price, inventory_qty) VALUES (10, 'Security Camera',      'Indoor 1080p IP security camera',  129.99, 60);

-- 6. Invoice
INSERT INTO Invoice (customer_id, employee_id, tax_id, transaction_date, due_date, subtotal, tax_amount, total_amount, status) VALUES (1,  1,  1, '2024-01-15', '2024-02-15', 1229.98, 89.17,  1319.15, 'Paid');
INSERT INTO Invoice (customer_id, employee_id, tax_id, transaction_date, due_date, subtotal, tax_amount, total_amount, status) VALUES (2,  2,  1, '2024-02-01', '2024-03-01',  299.97, 21.75,   321.72, 'Paid');
INSERT INTO Invoice (customer_id, employee_id, tax_id, transaction_date, due_date, subtotal, tax_amount, total_amount, status) VALUES (3,  4,  1, '2024-02-20', '2024-03-20',  249.99, 18.12,   268.11, 'Unpaid');
INSERT INTO Invoice (customer_id, employee_id, tax_id, transaction_date, due_date, subtotal, tax_amount, total_amount, status) VALUES (4,  1,  1, '2024-03-05', '2024-04-05',  179.98, 13.05,   193.03, 'Partial');
INSERT INTO Invoice (customer_id, employee_id, tax_id, transaction_date, due_date, subtotal, tax_amount, total_amount, status) VALUES (5,  7,  1, '2024-03-18', '2024-04-18', 1199.99, 86.99,  1286.98, 'Paid');
INSERT INTO Invoice (customer_id, employee_id, tax_id, transaction_date, due_date, subtotal, tax_amount, total_amount, status) VALUES (6,  2,  2, '2024-04-01', '2024-05-01',   89.99,  9.00,    98.99, 'Unpaid');
INSERT INTO Invoice (customer_id, employee_id, tax_id, transaction_date, due_date, subtotal, tax_amount, total_amount, status) VALUES (7,  4,  1, '2024-04-10', '2024-05-10',  399.98, 29.00,   428.98, 'Paid');
INSERT INTO Invoice (customer_id, employee_id, tax_id, transaction_date, due_date, subtotal, tax_amount, total_amount, status) VALUES (8,  10, 1, '2024-04-22', '2024-05-22',  259.97, 18.85,   278.82, 'Unpaid');
INSERT INTO Invoice (customer_id, employee_id, tax_id, transaction_date, due_date, subtotal, tax_amount, total_amount, status) VALUES (9,  7,  1, '2024-05-03', '2024-06-03',  129.99,  9.42,   139.41, 'Paid');
INSERT INTO Invoice (customer_id, employee_id, tax_id, transaction_date, due_date, subtotal, tax_amount, total_amount, status) VALUES (10, 1,  1, '2024-05-15', '2024-06-15',  649.97, 47.12,   697.09, 'Partial');

-- 7. Invoice_Line  (subtotal computed on the fly)
INSERT INTO Invoice_Line (invoice_id, product_id, quantity, unit_price, subtotal) VALUES (1, 1, 1, 1199.99, 1199.99);
INSERT INTO Invoice_Line (invoice_id, product_id, quantity, unit_price, subtotal) VALUES (1, 2, 1,   29.99,   29.99);
INSERT INTO Invoice_Line (invoice_id, product_id, quantity, unit_price, subtotal) VALUES (2, 4, 1,  249.99,  249.99);
INSERT INTO Invoice_Line (invoice_id, product_id, quantity, unit_price, subtotal) VALUES (2, 3, 5,    5.99,   29.95);
INSERT INTO Invoice_Line (invoice_id, product_id, quantity, unit_price, subtotal) VALUES (3, 4, 1,  249.99,  249.99);
INSERT INTO Invoice_Line (invoice_id, product_id, quantity, unit_price, subtotal) VALUES (4, 6, 1,   89.99,   89.99);
INSERT INTO Invoice_Line (invoice_id, product_id, quantity, unit_price, subtotal) VALUES (4, 8, 7,   12.99,   90.93);
INSERT INTO Invoice_Line (invoice_id, product_id, quantity, unit_price, subtotal) VALUES (5, 1, 1, 1199.99, 1199.99);
INSERT INTO Invoice_Line (invoice_id, product_id, quantity, unit_price, subtotal) VALUES (6, 6, 1,   89.99,   89.99);
INSERT INTO Invoice_Line (invoice_id, product_id, quantity, unit_price, subtotal) VALUES (7, 9, 2,   49.99,   99.98);

-- 8. Payment
INSERT INTO Payment (invoice_id, payment_date, amount, payment_method) VALUES (1,  '2024-01-20', 1319.15, 'Credit Card');
INSERT INTO Payment (invoice_id, payment_date, amount, payment_method) VALUES (2,  '2024-02-10',  321.72, 'Check');
INSERT INTO Payment (invoice_id, payment_date, amount, payment_method) VALUES (4,  '2024-03-10',  100.00, 'Cash');
INSERT INTO Payment (invoice_id, payment_date, amount, payment_method) VALUES (5,  '2024-03-20', 1286.98, 'Credit Card');
INSERT INTO Payment (invoice_id, payment_date, amount, payment_method) VALUES (7,  '2024-04-15',  428.98, 'Credit Card');
INSERT INTO Payment (invoice_id, payment_date, amount, payment_method) VALUES (9,  '2024-05-08',  139.41, 'Cash');
INSERT INTO Payment (invoice_id, payment_date, amount, payment_method) VALUES (10, '2024-05-20',  300.00, 'Check');
INSERT INTO Payment (invoice_id, payment_date, amount, payment_method) VALUES (10, '2024-06-01',  200.00, 'Cash');
INSERT INTO Payment (invoice_id, payment_date, amount, payment_method) VALUES (4,  '2024-04-01',   93.03, 'Cash');
INSERT INTO Payment (invoice_id, payment_date, amount, payment_method) VALUES (2,  '2024-02-28',   50.00, 'Credit Card');

-- 9. Payment_Reminder
INSERT INTO Payment_Reminder (invoice_id, reminder_date, message, sent_status) VALUES (3,  '2024-03-25', 'Invoice #3 was due on 2024-03-20. Please remit payment at your earliest convenience.', 'Sent');
INSERT INTO Payment_Reminder (invoice_id, reminder_date, message, sent_status) VALUES (6,  '2024-05-08', 'Invoice #6 is now overdue. Please contact us to arrange payment.', 'Sent');
INSERT INTO Payment_Reminder (invoice_id, reminder_date, message, sent_status) VALUES (8,  '2024-05-29', 'Invoice #8 remains unpaid. A late fee may be applied if not settled soon.', 'Sent');
INSERT INTO Payment_Reminder (invoice_id, reminder_date, message, sent_status) VALUES (3,  '2024-04-10', 'Second reminder: Invoice #3 is 21 days overdue. Please respond immediately.', 'Sent');
INSERT INTO Payment_Reminder (invoice_id, reminder_date, message, sent_status) VALUES (6,  '2024-05-20', 'Final notice for Invoice #6. Account may be referred to collections.', 'Pending');
INSERT INTO Payment_Reminder (invoice_id, reminder_date, message, sent_status) VALUES (8,  '2024-06-05', 'Invoice #8 is now 14 days past due. Please call us at 619-555-0100.', 'Pending');
INSERT INTO Payment_Reminder (invoice_id, reminder_date, message, sent_status) VALUES (4,  '2024-04-12', 'Invoice #4 has a remaining balance. Please complete your payment.', 'Sent');
INSERT INTO Payment_Reminder (invoice_id, reminder_date, message, sent_status) VALUES (10, '2024-06-20', 'Invoice #10 still has an outstanding balance. Please arrange final payment.', 'Pending');
INSERT INTO Payment_Reminder (invoice_id, reminder_date, message, sent_status) VALUES (3,  '2024-04-25', 'Third reminder: Invoice #3 — 36 days overdue. Legal action may follow.', 'Pending');
INSERT INTO Payment_Reminder (invoice_id, reminder_date, message, sent_status) VALUES (6,  '2024-06-01', 'Invoice #6: Your account is being escalated. Contact billing immediately.', 'Pending');

-- 10. Audit_Log
INSERT INTO Audit_Log (table_name, action, record_id, changed_by, change_date, notes) VALUES ('Invoice',  'INSERT', 1,  'alice.johnson',  '2024-01-15 09:00:00', 'New invoice created for customer 1');
INSERT INTO Audit_Log (table_name, action, record_id, changed_by, change_date, notes) VALUES ('Invoice',  'UPDATE', 1,  'carol.smith',    '2024-01-20 14:30:00', 'Invoice status changed to Paid');
INSERT INTO Audit_Log (table_name, action, record_id, changed_by, change_date, notes) VALUES ('Product',  'UPDATE', 1,  'frank.brown',    '2024-01-15 09:05:00', 'Inventory reduced by 1 after sale');
INSERT INTO Audit_Log (table_name, action, record_id, changed_by, change_date, notes) VALUES ('Customer', 'INSERT', 11, 'alice.johnson',  '2024-02-01 10:00:00', 'New customer registered');
INSERT INTO Audit_Log (table_name, action, record_id, changed_by, change_date, notes) VALUES ('Invoice',  'UPDATE', 4,  'carol.smith',    '2024-03-10 11:15:00', 'Partial payment received; status updated');
INSERT INTO Audit_Log (table_name, action, record_id, changed_by, change_date, notes) VALUES ('Payment',  'INSERT', 4,  'carol.smith',    '2024-03-10 11:14:00', 'Payment of $100 recorded for Invoice 4');
INSERT INTO Audit_Log (table_name, action, record_id, changed_by, change_date, notes) VALUES ('Product',  'UPDATE', 4,  'frank.brown',    '2024-03-05 09:30:00', 'Inventory updated after chair sale');
INSERT INTO Audit_Log (table_name, action, record_id, changed_by, change_date, notes) VALUES ('Invoice',  'UPDATE', 3,  'brian.martinez', '2024-03-25 08:00:00', 'Payment reminder sent for overdue invoice');
INSERT INTO Audit_Log (table_name, action, record_id, changed_by, change_date, notes) VALUES ('Payment',  'INSERT', 7,  'carol.smith',    '2024-04-15 13:00:00', 'Full payment received for Invoice 7');
INSERT INTO Audit_Log (table_name, action, record_id, changed_by, change_date, notes) VALUES ('Invoice',  'UPDATE', 10, 'carol.smith',    '2024-06-01 10:45:00', 'Second partial payment received for Invoice 10');
