-- Create schema
CREATE SCHEMA IF NOT EXISTS credit_collection_project;

-- Dimension Tables

CREATE TABLE credit_collection_project.dim_customer (
    id_customer INT PRIMARY KEY,
    customer_name VARCHAR(255),
    tax_id VARCHAR(14),
    state VARCHAR(2),
    industry VARCHAR(100),
    registration_date DATE
);

CREATE TABLE credit_collection_project.dim_credit_limit (
    id_credit_limit INT PRIMARY KEY,
    id_customer INT UNIQUE REFERENCES credit_collection_project.dim_customer(id_customer),
    insured_credit_limit DECIMAL(14,2),
    internal_credit_limit DECIMAL(14,2),
    collateral_value DECIMAL(14,2)
);

CREATE TABLE credit_collection_project.dim_date (
    full_date DATE PRIMARY KEY,
    year INT,
    month INT,
    day INT
);

-- Fact Table: Invoices

CREATE TABLE credit_collection_project.fact_invoices (
    id_invoice INT PRIMARY KEY,
    id_customer INT REFERENCES credit_collection_project.dim_customer(id_customer),
    issue_date DATE REFERENCES credit_collection_project.dim_date(full_date),
    due_date DATE REFERENCES credit_collection_project.dim_date(full_date),
    payment_method VARCHAR(50),
    invoice_amount DECIMAL(14,2),
    amount_paid DECIMAL(14,2),
    open_balance DECIMAL(14,2)
);

-- Fact Table: Payments Received

CREATE TABLE credit_collection_project.fact_payments (
    id_payment INT PRIMARY KEY,
    id_invoice INT REFERENCES credit_collection_project.fact_invoices(id_invoice),
    id_customer INT REFERENCES credit_collection_project.dim_customer(id_customer),
    payment_date DATE REFERENCES credit_collection_project.dim_date(full_date),
    payment_amount DECIMAL(14,2)
);