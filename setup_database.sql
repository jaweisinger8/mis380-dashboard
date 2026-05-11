-- =====================================================================
-- MIS 380 Team 16 - Sales & Invoicing System Database
-- Complete schema + sample data + updates + indexes
-- =====================================================================
PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS Audit_Log;
DROP TABLE IF EXISTS Payment_Reminder;
DROP TABLE IF EXISTS Offline_Payment;
DROP TABLE IF EXISTS Online_Payment;
DROP TABLE IF EXISTS Payment;
DROP TABLE IF EXISTS Invoice_Line;
DROP TABLE IF EXISTS Invoice;
DROP TABLE IF EXISTS Product;
DROP TABLE IF EXISTS CustomerPhone;
DROP TABLE IF EXISTS Customer;
DROP TABLE IF EXISTS Employee;
DROP TABLE IF EXISTS Tax;
DROP TABLE IF EXISTS Category;

-- =====================================================================
-- SECTION 5.1 - CREATE TABLES
-- =====================================================================

CREATE TABLE Category (
    category_id    INTEGER PRIMARY KEY,
    category_name  TEXT NOT NULL,
    description    TEXT DEFAULT 'No description provided',
    is_active      INTEGER NOT NULL DEFAULT 1,
    CHECK (is_active IN (0, 1))
);

CREATE TABLE Tax (
    tax_id          INTEGER PRIMARY KEY,
    tax_name        TEXT NOT NULL,
    tax_rate        REAL NOT NULL DEFAULT 0.0,
    effective_date  TEXT NOT NULL,
    notes           TEXT,
    CHECK (tax_rate >= 0)
);

CREATE TABLE Employee (
    employee_id  INTEGER PRIMARY KEY,
    first_name   TEXT NOT NULL,
    last_name    TEXT NOT NULL,
    email        TEXT UNIQUE NOT NULL,
    phone        TEXT,
    hire_date    TEXT NOT NULL,
    role         TEXT DEFAULT 'Sales Rep',
    is_active    INTEGER NOT NULL DEFAULT 1,
    CHECK (is_active IN (0, 1))
);

CREATE TABLE Customer (
    customer_id  INTEGER PRIMARY KEY,
    first_name   TEXT NOT NULL,
    last_name    TEXT NOT NULL,
    email        TEXT UNIQUE NOT NULL,
    address      TEXT,
    city         TEXT,
    state        TEXT DEFAULT 'CA',
    zip_code     TEXT,
    referred_by  INTEGER,
    created_at   TEXT NOT NULL DEFAULT (date('now')),
    is_active    INTEGER NOT NULL DEFAULT 1,
    CHECK (is_active IN (0, 1)),
    CONSTRAINT FK_Customer_Referral FOREIGN KEY (referred_by) REFERENCES Customer(customer_id)
);

CREATE TABLE CustomerPhone (
    customer_id   INTEGER NOT NULL,
    phone_number  TEXT NOT NULL,
    phone_type    TEXT DEFAULT 'mobile',
    PRIMARY KEY (customer_id, phone_number),
    CONSTRAINT FK_CustomerPhone_Customer FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
);

CREATE TABLE Product (
    product_id     INTEGER PRIMARY KEY,
    category_id    INTEGER NOT NULL,
    product_name   TEXT NOT NULL,
    description    TEXT,
    unit_price     REAL NOT NULL,
    inventory_qty  INTEGER NOT NULL DEFAULT 0,
    CHECK (inventory_qty >= 0),
    CONSTRAINT FK_Product_Category FOREIGN KEY (category_id) REFERENCES Category(category_id)
);

CREATE TABLE Invoice (
    invoice_id        INTEGER PRIMARY KEY,
    customer_id       INTEGER NOT NULL,
    employee_id       INTEGER,
    tax_id            INTEGER NOT NULL,
    transaction_date  TEXT NOT NULL,
    due_date          TEXT NOT NULL,
    subtotal          REAL NOT NULL DEFAULT 0.00,
    tax_amount        REAL NOT NULL DEFAULT 0.00,
    total_amount      REAL NOT NULL DEFAULT 0.00,
    status            TEXT NOT NULL DEFAULT 'Unpaid',
    CONSTRAINT FK_Invoice_Customer FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    CONSTRAINT FK_Invoice_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id),
    CONSTRAINT FK_Invoice_Tax      FOREIGN KEY (tax_id)      REFERENCES Tax(tax_id)
);

CREATE TABLE Invoice_Line (
    line_id     INTEGER PRIMARY KEY,
    invoice_id  INTEGER NOT NULL,
    product_id  INTEGER NOT NULL,
    quantity    INTEGER NOT NULL DEFAULT 1,
    unit_price  REAL NOT NULL,
    subtotal    REAL NOT NULL,
    discount    REAL DEFAULT 0.00,
    CHECK (quantity > 0),
    CONSTRAINT FK_InvLine_Invoice FOREIGN KEY (invoice_id) REFERENCES Invoice(invoice_id),
    CONSTRAINT FK_InvLine_Product FOREIGN KEY (product_id) REFERENCES Product(product_id)
);

CREATE TABLE Payment (
    payment_id     INTEGER PRIMARY KEY,
    invoice_id     INTEGER NOT NULL,
    payment_date   TEXT NOT NULL DEFAULT (date('now')),
    amount         REAL NOT NULL,
    payment_type   TEXT NOT NULL DEFAULT 'Offline',
    reference_num  TEXT,
    CHECK (amount > 0),
    CHECK (payment_type IN ('Online', 'Offline')),
    CONSTRAINT FK_Payment_Invoice FOREIGN KEY (invoice_id) REFERENCES Invoice(invoice_id)
);

CREATE TABLE Online_Payment (
    payment_id             INTEGER PRIMARY KEY,
    gateway_provider       TEXT NOT NULL DEFAULT 'Stripe',
    transaction_reference  TEXT,
    CONSTRAINT FK_OnlinePay_Payment FOREIGN KEY (payment_id) REFERENCES Payment(payment_id)
);

CREATE TABLE Offline_Payment (
    payment_id   INTEGER PRIMARY KEY,
    location     TEXT NOT NULL DEFAULT 'Main Store',
    received_by  TEXT,
    CONSTRAINT FK_OfflinePay_Payment FOREIGN KEY (payment_id) REFERENCES Payment(payment_id)
);

CREATE TABLE Payment_Reminder (
    reminder_id    INTEGER PRIMARY KEY,
    invoice_id     INTEGER NOT NULL,
    reminder_date  TEXT NOT NULL DEFAULT (date('now')),
    message        TEXT NOT NULL,
    sent_status    TEXT NOT NULL DEFAULT 'Pending',
    response_date  TEXT,
    CONSTRAINT FK_Reminder_Invoice FOREIGN KEY (invoice_id) REFERENCES Invoice(invoice_id)
);

CREATE TABLE Audit_Log (
    log_id       INTEGER PRIMARY KEY,
    table_name   TEXT NOT NULL,
    action       TEXT NOT NULL,
    record_id    INTEGER NOT NULL,
    changed_by   TEXT,
    change_date  TEXT NOT NULL DEFAULT (datetime('now')),
    notes        TEXT,
    customer_id  INTEGER,
    CONSTRAINT FK_AuditLog_Customer FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
);

-- =====================================================================
-- SECTION 5.2 - SAMPLE DATA
-- =====================================================================

INSERT INTO Category (category_name, description, is_active) VALUES ('Electronics',     'Electronic devices and accessories', 1);
INSERT INTO Category (category_name, description, is_active) VALUES ('Office Supplies', 'Stationary and office materials', 1);
INSERT INTO Category (category_name, description, is_active) VALUES ('Furniture',       'Desks, chairs, and shelving', 1);
INSERT INTO Category (category_name, description, is_active) VALUES ('Software',        'Licensed software products', 1);
INSERT INTO Category (category_name, description, is_active) VALUES ('Networking',      'Routers, switches, cables', 1);
INSERT INTO Category (category_name, description, is_active) VALUES ('Printing',        'Printers, ink, and paper', 1);
INSERT INTO Category (category_name, description, is_active) VALUES ('Storage',         'USB drives, hard disks, memory cards', 1);
INSERT INTO Category (category_name, description, is_active) VALUES ('Audio/Visual',    'Speakers, monitors, webcams', 1);
INSERT INTO Category (category_name, description, is_active) VALUES ('Cleaning',        'Office cleaning supplies', 1);
INSERT INTO Category (category_name, description, is_active) VALUES ('Security',        'Cameras and access control devices', 1);

INSERT INTO Tax (tax_name, tax_rate, effective_date, notes) VALUES ('CA State Tax',    0.0725, '2023-01-01', 'California state sales tax');
INSERT INTO Tax (tax_name, tax_rate, effective_date, notes) VALUES ('CA County Tax',   0.0100, '2023-01-01', 'California county tax');
INSERT INTO Tax (tax_name, tax_rate, effective_date, notes) VALUES ('No Tax',          0.0000, '2023-01-01', 'Tax-exempt transactions');
INSERT INTO Tax (tax_name, tax_rate, effective_date, notes) VALUES ('TX State Tax',    0.0625, '2023-01-01', 'Texas state sales tax');
INSERT INTO Tax (tax_name, tax_rate, effective_date, notes) VALUES ('NY State Tax',    0.0800, '2023-01-01', 'New York state sales tax');
INSERT INTO Tax (tax_name, tax_rate, effective_date, notes) VALUES ('FL State Tax',    0.0600, '2023-01-01', 'Florida state sales tax');
INSERT INTO Tax (tax_name, tax_rate, effective_date, notes) VALUES ('WA State Tax',    0.0650, '2023-01-01', 'Washington state sales tax');
INSERT INTO Tax (tax_name, tax_rate, effective_date, notes) VALUES ('OR No Sales Tax', 0.0000, '2023-01-01', 'Oregon has no sales tax');
INSERT INTO Tax (tax_name, tax_rate, effective_date, notes) VALUES ('NV State Tax',    0.0685, '2023-01-01', 'Nevada state sales tax');
INSERT INTO Tax (tax_name, tax_rate, effective_date, notes) VALUES ('AZ State Tax',    0.0560, '2023-01-01', 'Arizona state sales tax');

INSERT INTO Employee (first_name, last_name, email, phone, hire_date, role, is_active) VALUES ('Alice', 'Johnson',  'alice.johnson@chinook.com',  '619-555-0101', '2020-03-15', 'Sales Rep', 1);
INSERT INTO Employee (first_name, last_name, email, phone, hire_date, role, is_active) VALUES ('Brian', 'Martinez', 'brian.martinez@chinook.com', '619-555-0102', '2019-07-01', 'Sales Manager', 1);
INSERT INTO Employee (first_name, last_name, email, phone, hire_date, role, is_active) VALUES ('Carol', 'Smith',    'carol.smith@chinook.com',    '619-555-0103', '2021-01-20', 'Accountant', 1);
INSERT INTO Employee (first_name, last_name, email, phone, hire_date, role, is_active) VALUES ('David', 'Lee',      'david.lee@chinook.com',      '619-555-0104', '2022-06-10', 'Sales Rep', 1);
INSERT INTO Employee (first_name, last_name, email, phone, hire_date, role, is_active) VALUES ('Elena', 'Nguyen',   'elena.nguyen@chinook.com',   '619-555-0105', '2021-09-05', 'Customer Service', 1);
INSERT INTO Employee (first_name, last_name, email, phone, hire_date, role, is_active) VALUES ('Frank', 'Brown',    'frank.brown@chinook.com',    '619-555-0106', '2018-11-30', 'Warehouse Staff', 1);
INSERT INTO Employee (first_name, last_name, email, phone, hire_date, role, is_active) VALUES ('Grace', 'Wilson',   'grace.wilson@chinook.com',   '619-555-0107', '2023-02-14', 'Sales Rep', 1);
INSERT INTO Employee (first_name, last_name, email, phone, hire_date, role, is_active) VALUES ('Henry', 'Taylor',   'henry.taylor@chinook.com',   '619-555-0108', '2020-08-22', 'IT Support', 1);
INSERT INTO Employee (first_name, last_name, email, phone, hire_date, role, is_active) VALUES ('Irene', 'Davis',    'irene.davis@chinook.com',    '619-555-0109', '2017-04-18', 'Store Manager', 1);
INSERT INTO Employee (first_name, last_name, email, phone, hire_date, role, is_active) VALUES ('James', 'Anderson', 'james.anderson@chinook.com', '619-555-0110', '2022-12-01', 'Sales Rep', 1);

INSERT INTO Customer (first_name, last_name, email, address, city, state, zip_code, referred_by, created_at, is_active) VALUES ('Omar',    'Hassan',   'omar.hassan@email.com',    '123 Main St',    'El Cajon',      'CA', '92020', NULL, '2023-01-10', 1);
INSERT INTO Customer (first_name, last_name, email, address, city, state, zip_code, referred_by, created_at, is_active) VALUES ('Priya',   'Patel',    'priya.patel@email.com',    '456 Oak Ave',    'San Diego',     'CA', '92101', 1,    '2023-02-14', 1);
INSERT INTO Customer (first_name, last_name, email, address, city, state, zip_code, referred_by, created_at, is_active) VALUES ('Carlos',  'Reyes',    'carlos.reyes@email.com',   '789 Pine Rd',    'Chula Vista',   'CA', '91910', NULL, '2023-03-05', 1);
INSERT INTO Customer (first_name, last_name, email, address, city, state, zip_code, referred_by, created_at, is_active) VALUES ('Sarah',   'Kim',      'sarah.kim@email.com',      '321 Elm St',     'La Mesa',       'CA', '91942', 3,    '2023-04-20', 1);
INSERT INTO Customer (first_name, last_name, email, address, city, state, zip_code, referred_by, created_at, is_active) VALUES ('Marcus',  'Williams', 'marcus.w@email.com',       '654 Cedar Blvd', 'Santee',        'CA', '92071', NULL, '2023-05-11', 1);
INSERT INTO Customer (first_name, last_name, email, address, city, state, zip_code, referred_by, created_at, is_active) VALUES ('Fatima',  'Al-Amin',  'fatima.alamin@email.com',  '987 Birch Ln',   'Spring Valley', 'CA', '91977', 1,    '2023-06-02', 1);
INSERT INTO Customer (first_name, last_name, email, address, city, state, zip_code, referred_by, created_at, is_active) VALUES ('Daniel',  'Torres',   'daniel.torres@email.com',  '111 Maple Dr',   'El Cajon',      'CA', '92021', NULL, '2023-07-19', 1);
INSERT INTO Customer (first_name, last_name, email, address, city, state, zip_code, referred_by, created_at, is_active) VALUES ('Aisha',   'Okonkwo',  'aisha.okon@email.com',     '222 Walnut Ave', 'San Diego',     'CA', '92103', 5,    '2023-08-08', 1);
INSERT INTO Customer (first_name, last_name, email, address, city, state, zip_code, referred_by, created_at, is_active) VALUES ('Kevin',   'Nguyen',   'kevin.nguyen@email.com',   '333 Spruce St',  'Lemon Grove',   'CA', '91945', NULL, '2023-09-15', 1);
INSERT INTO Customer (first_name, last_name, email, address, city, state, zip_code, referred_by, created_at, is_active) VALUES ('Linda',   'Cooper',   'linda.cooper@email.com',   '444 Ash Ct',     'San Diego',     'CA', '92105', 3,    '2023-10-30', 1);

INSERT INTO CustomerPhone (customer_id, phone_number, phone_type) VALUES (1,  '619-444-0201', 'Mobile');
INSERT INTO CustomerPhone (customer_id, phone_number, phone_type) VALUES (2,  '619-444-0202', 'Mobile');
INSERT INTO CustomerPhone (customer_id, phone_number, phone_type) VALUES (3,  '619-444-0203', 'Home');
INSERT INTO CustomerPhone (customer_id, phone_number, phone_type) VALUES (4,  '619-444-0204', 'Mobile');
INSERT INTO CustomerPhone (customer_id, phone_number, phone_type) VALUES (5,  '619-444-0205', 'Work');
INSERT INTO CustomerPhone (customer_id, phone_number, phone_type) VALUES (6,  '619-444-0206', 'Mobile');
INSERT INTO CustomerPhone (customer_id, phone_number, phone_type) VALUES (7,  '619-444-0207', 'Home');
INSERT INTO CustomerPhone (customer_id, phone_number, phone_type) VALUES (8,  '619-444-0208', 'Mobile');
INSERT INTO CustomerPhone (customer_id, phone_number, phone_type) VALUES (9,  '619-444-0209', 'Work');
INSERT INTO CustomerPhone (customer_id, phone_number, phone_type) VALUES (10, '619-444-0210', 'Mobile');

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

INSERT INTO Invoice_Line (invoice_id, product_id, quantity, unit_price, subtotal, discount) VALUES (1, 1, 1, 1199.99, 1199.99, 0.00);
INSERT INTO Invoice_Line (invoice_id, product_id, quantity, unit_price, subtotal, discount) VALUES (1, 2, 1,   29.99,   29.99, 0.00);
INSERT INTO Invoice_Line (invoice_id, product_id, quantity, unit_price, subtotal, discount) VALUES (2, 4, 1,  249.99,  249.99, 0.00);
INSERT INTO Invoice_Line (invoice_id, product_id, quantity, unit_price, subtotal, discount) VALUES (2, 3, 5,    5.99,   29.95, 0.00);
INSERT INTO Invoice_Line (invoice_id, product_id, quantity, unit_price, subtotal, discount) VALUES (3, 4, 1,  249.99,  249.99, 0.00);
INSERT INTO Invoice_Line (invoice_id, product_id, quantity, unit_price, subtotal, discount) VALUES (4, 6, 1,   89.99,   89.99, 0.00);
INSERT INTO Invoice_Line (invoice_id, product_id, quantity, unit_price, subtotal, discount) VALUES (4, 7, 7,   12.99,   90.93, 0.00);
INSERT INTO Invoice_Line (invoice_id, product_id, quantity, unit_price, subtotal, discount) VALUES (5, 1, 1, 1199.99, 1199.99, 0.00);
INSERT INTO Invoice_Line (invoice_id, product_id, quantity, unit_price, subtotal, discount) VALUES (6, 6, 1,   89.99,   89.99, 0.00);
INSERT INTO Invoice_Line (invoice_id, product_id, quantity, unit_price, subtotal, discount) VALUES (7, 9, 2,   49.99,   99.98, 0.00);

INSERT INTO Payment (invoice_id, payment_date, amount, payment_type, reference_num) VALUES (1,  '2024-01-20', 1319.15, 'Online',  'REF-001-2024');
INSERT INTO Payment (invoice_id, payment_date, amount, payment_type, reference_num) VALUES (2,  '2024-02-10',  321.72, 'Offline', 'REF-002-2024');
INSERT INTO Payment (invoice_id, payment_date, amount, payment_type, reference_num) VALUES (4,  '2024-03-10',  100.00, 'Offline', 'REF-003-2024');
INSERT INTO Payment (invoice_id, payment_date, amount, payment_type, reference_num) VALUES (5,  '2024-03-20', 1286.98, 'Online',  'REF-004-2024');
INSERT INTO Payment (invoice_id, payment_date, amount, payment_type, reference_num) VALUES (7,  '2024-04-15',  428.98, 'Online',  'REF-005-2024');
INSERT INTO Payment (invoice_id, payment_date, amount, payment_type, reference_num) VALUES (9,  '2024-05-08',  139.41, 'Offline', 'REF-006-2024');
INSERT INTO Payment (invoice_id, payment_date, amount, payment_type, reference_num) VALUES (10, '2024-05-20',  300.00, 'Offline', 'REF-007-2024');
INSERT INTO Payment (invoice_id, payment_date, amount, payment_type, reference_num) VALUES (10, '2024-06-01',  200.00, 'Offline', 'REF-008-2024');
INSERT INTO Payment (invoice_id, payment_date, amount, payment_type, reference_num) VALUES (4,  '2024-04-01',   93.03, 'Offline', 'REF-009-2024');
INSERT INTO Payment (invoice_id, payment_date, amount, payment_type, reference_num) VALUES (2,  '2024-02-28',   50.00, 'Online',  'REF-010-2024');

INSERT INTO Online_Payment (payment_id, gateway_provider, transaction_reference) VALUES (1,  'Stripe', 'ch_3OxKL2A9v2Bv1001');
INSERT INTO Online_Payment (payment_id, gateway_provider, transaction_reference) VALUES (4,  'PayPal', 'PAYID-2024MAR-8823');
INSERT INTO Online_Payment (payment_id, gateway_provider, transaction_reference) VALUES (5,  'Stripe', 'ch_3OxKL2A9v2Bv1005');
INSERT INTO Online_Payment (payment_id, gateway_provider, transaction_reference) VALUES (8,  'Square', 'sq_pmt_9912abc');
INSERT INTO Online_Payment (payment_id, gateway_provider, transaction_reference) VALUES (10, 'Stripe', 'ch_3OxKL2A9v2Bv1010');

INSERT INTO Offline_Payment (payment_id, location, received_by) VALUES (2, 'Chinook Store - El Cajon',   'carol.smith');
INSERT INTO Offline_Payment (payment_id, location, received_by) VALUES (3, 'Chinook Store - El Cajon',   'alice.johnson');
INSERT INTO Offline_Payment (payment_id, location, received_by) VALUES (6, 'Chinook Store - San Diego',  'carol.smith');
INSERT INTO Offline_Payment (payment_id, location, received_by) VALUES (7, 'Chinook Store - El Cajon',   'carol.smith');
INSERT INTO Offline_Payment (payment_id, location, received_by) VALUES (9, 'Chinook Store - El Cajon',   'alice.johnson');

INSERT INTO Payment_Reminder (invoice_id, reminder_date, message, sent_status) VALUES (3,  '2024-03-25', 'Invoice #3 was due on 2024-03-20.', 'Sent');
INSERT INTO Payment_Reminder (invoice_id, reminder_date, message, sent_status) VALUES (6,  '2024-05-08', 'Invoice #6 is now overdue.', 'Sent');
INSERT INTO Payment_Reminder (invoice_id, reminder_date, message, sent_status) VALUES (8,  '2024-05-29', 'Invoice #8 remains unpaid.', 'Sent');
INSERT INTO Payment_Reminder (invoice_id, reminder_date, message, sent_status) VALUES (3,  '2024-04-10', 'Second reminder: Invoice #3 is 21 days overdue.', 'Sent');
INSERT INTO Payment_Reminder (invoice_id, reminder_date, message, sent_status) VALUES (6,  '2024-05-20', 'Final notice for Invoice #6.', 'Pending');
INSERT INTO Payment_Reminder (invoice_id, reminder_date, message, sent_status) VALUES (8,  '2024-06-05', 'Invoice #8 is now 14 days past due.', 'Pending');
INSERT INTO Payment_Reminder (invoice_id, reminder_date, message, sent_status) VALUES (4,  '2024-04-12', 'Invoice #4 has a remaining balance.', 'Sent');
INSERT INTO Payment_Reminder (invoice_id, reminder_date, message, sent_status) VALUES (10, '2024-06-20', 'Invoice #10 still has outstanding balance.', 'Pending');
INSERT INTO Payment_Reminder (invoice_id, reminder_date, message, sent_status) VALUES (3,  '2024-04-25', 'Third reminder: Invoice #3 - 36 days overdue.', 'Pending');
INSERT INTO Payment_Reminder (invoice_id, reminder_date, message, sent_status) VALUES (6,  '2024-06-01', 'Invoice #6: Account being escalated.', 'Pending');

INSERT INTO Audit_Log (table_name, action, record_id, changed_by, change_date, notes, customer_id) VALUES ('Invoice',  'INSERT', 1,  'alice.johnson',  '2024-01-15 09:00:00', 'New invoice created for customer 1', 1);
INSERT INTO Audit_Log (table_name, action, record_id, changed_by, change_date, notes, customer_id) VALUES ('Invoice',  'UPDATE', 1,  'carol.smith',    '2024-01-20 14:30:00', 'Invoice status changed to Paid', 1);
INSERT INTO Audit_Log (table_name, action, record_id, changed_by, change_date, notes, customer_id) VALUES ('Product',  'UPDATE', 1,  'frank.brown',    '2024-01-15 09:05:00', 'Inventory reduced by 1', NULL);
INSERT INTO Audit_Log (table_name, action, record_id, changed_by, change_date, notes, customer_id) VALUES ('Customer', 'INSERT', 11, 'alice.johnson',  '2024-02-01 10:00:00', 'New customer registered', NULL);
INSERT INTO Audit_Log (table_name, action, record_id, changed_by, change_date, notes, customer_id) VALUES ('Invoice',  'UPDATE', 4,  'carol.smith',    '2024-03-10 11:15:00', 'Partial payment received', 4);
INSERT INTO Audit_Log (table_name, action, record_id, changed_by, change_date, notes, customer_id) VALUES ('Payment',  'INSERT', 4,  'carol.smith',    '2024-03-10 11:14:00', 'Payment of $100 recorded', 4);
INSERT INTO Audit_Log (table_name, action, record_id, changed_by, change_date, notes, customer_id) VALUES ('Product',  'UPDATE', 4,  'frank.brown',    '2024-03-05 09:30:00', 'Inventory updated after chair sale', NULL);
INSERT INTO Audit_Log (table_name, action, record_id, changed_by, change_date, notes, customer_id) VALUES ('Invoice',  'UPDATE', 3,  'brian.martinez', '2024-03-25 08:00:00', 'Reminder sent for overdue invoice', 3);
INSERT INTO Audit_Log (table_name, action, record_id, changed_by, change_date, notes, customer_id) VALUES ('Payment',  'INSERT', 7,  'carol.smith',    '2024-04-15 13:00:00', 'Full payment received for Invoice 7', 7);
INSERT INTO Audit_Log (table_name, action, record_id, changed_by, change_date, notes, customer_id) VALUES ('Invoice',  'UPDATE', 10, 'carol.smith',    '2024-06-01 10:45:00', 'Second partial payment received', 10);

-- =====================================================================
-- SECTION 5.3 - UPDATE STATEMENTS (25)
-- =====================================================================
UPDATE Invoice SET status = 'Paid' WHERE invoice_id = 3;
UPDATE Invoice SET status = 'Paid' WHERE invoice_id = 6;
UPDATE Invoice SET status = 'Paid' WHERE invoice_id = 8;
UPDATE Invoice SET total_amount = total_amount + 15.00 WHERE invoice_id = 6;
UPDATE Invoice SET status = 'Paid' WHERE invoice_id = 10;
UPDATE Product SET inventory_qty = inventory_qty - 1 WHERE product_id = 1;
UPDATE Product SET inventory_qty = inventory_qty - 1 WHERE product_id = 4;
UPDATE Product SET inventory_qty = inventory_qty - 1 WHERE product_id = 6;
UPDATE Product SET inventory_qty = inventory_qty - 7 WHERE product_id = 7;
UPDATE Product SET inventory_qty = inventory_qty - 2 WHERE product_id = 9;
UPDATE Product SET unit_price = 34.99 WHERE product_id = 2;
UPDATE Product SET unit_price = 64.99 WHERE product_id = 5;
UPDATE Product SET inventory_qty = inventory_qty + 50 WHERE product_id = 9;
UPDATE Product SET inventory_qty = inventory_qty + 20 WHERE product_id = 4;
UPDATE Customer SET email = 'omar.hassan.updated@email.com' WHERE customer_id = 1;
UPDATE CustomerPhone SET phone_number = '619-444-9999' WHERE customer_id = 2;
UPDATE Customer SET address = '500 New Street', city = 'El Cajon', zip_code = '92022' WHERE customer_id = 7;
UPDATE Employee SET role = 'Senior Sales Rep' WHERE employee_id = 4;
UPDATE Employee SET email = 'grace.wilson.new@chinook.com' WHERE employee_id = 7;
UPDATE Payment_Reminder SET sent_status = 'Sent' WHERE reminder_id = 6;
UPDATE Payment_Reminder SET sent_status = 'Sent' WHERE reminder_id = 8;
UPDATE Tax SET tax_rate = 0.0125 WHERE tax_id = 2;
UPDATE Invoice SET due_date = '2024-05-05' WHERE invoice_id = 4;
UPDATE Invoice_Line SET unit_price = 12.99 WHERE line_id = 7;
UPDATE Audit_Log SET notes = 'Partial payment of $100 received; status updated to Partial. Balance: $93.03 remaining.' WHERE log_id = 5;

-- =====================================================================
-- SECTION 7 - INDEXES
-- =====================================================================
CREATE INDEX idx_customer_email           ON Customer       (email);
CREATE INDEX idx_customer_referred_by     ON Customer       (referred_by);
CREATE INDEX idx_customerphone_customer   ON CustomerPhone  (customer_id);
CREATE INDEX idx_invoice_status           ON Invoice        (status);
CREATE INDEX idx_invoice_due_date         ON Invoice        (due_date);
CREATE INDEX idx_invoiceline_invoice      ON Invoice_Line   (invoice_id);
CREATE INDEX idx_invoiceline_product      ON Invoice_Line   (product_id);
CREATE INDEX idx_payment_invoice          ON Payment        (invoice_id);
CREATE INDEX idx_reminder_invoice         ON Payment_Reminder (invoice_id);
CREATE INDEX idx_auditlog_table_action    ON Audit_Log      (table_name, action);
