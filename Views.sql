

CREATE OR REPLACE VIEW credit_collection_project.vw_default_by_year_month AS
WITH invoice_payments AS (
    SELECT
        i.id_invoice,
        i.id_customer,
        i.issue_date,
        i.due_date,
        EXTRACT(YEAR FROM i.due_date) AS due_year,
        EXTRACT(MONTH FROM i.due_date) AS due_month,
        EXTRACT(YEAR FROM i.due_date) * 100 + EXTRACT(MONTH FROM i.due_date) AS year_month,
        i.invoice_amount,
        COALESCE(SUM(p.payment_amount), 0) AS total_paid,
        MAX(p.payment_date) AS last_payment_date
    FROM credit_collection_project.fact_invoices i
    LEFT JOIN credit_collection_project.fact_payments p
        ON i.id_invoice = p.id_invoice
    GROUP BY i.id_invoice
),
defaulted_invoices AS (
    SELECT
        *,
        ('2024-12-31'::DATE - due_date)::INT AS days_past_due,
        (invoice_amount - total_paid) AS open_balance,
        CASE
            WHEN ('2024-12-31'::DATE - due_date)::INT > 90 AND (invoice_amount - total_paid) > 0 THEN 1
            ELSE 0
        END AS is_default
    FROM invoice_payments
)
SELECT
    year_month,
    due_year,
    due_month,
    SUM(invoice_amount) AS total_due_amount,
    SUM(CASE WHEN is_default = 1 THEN open_balance ELSE 0 END) AS default_amount
FROM defaulted_invoices
GROUP BY
    year_month,
    due_year,
    due_month;





CREATE OR REPLACE VIEW credit_collection_project.vw_aging_list AS
WITH invoice_payments AS (
    SELECT
        i.id_invoice,
        i.id_customer,
        i.issue_date,
        i.due_date,
        i.invoice_amount,
        COALESCE(SUM(p.payment_amount), 0) AS total_paid
    FROM credit_collection_project.fact_invoices i
    LEFT JOIN credit_collection_project.fact_payments p
        ON i.id_invoice = p.id_invoice
    GROUP BY i.id_invoice
),
open_invoices_with_aging AS (
    SELECT
        *,
        ('2024-12-31'::DATE - due_date)::INT AS days_past_due,
        (invoice_amount - total_paid) AS open_balance,
        CASE
            WHEN ('2024-12-31'::DATE - due_date)::INT > 90 AND (invoice_amount - total_paid) > 0 THEN 1
            ELSE 0
        END AS is_default
    FROM invoice_payments
)
SELECT * 
FROM open_invoices_with_aging
WHERE open_balance > 0.01;





CREATE OR REPLACE VIEW credit_collection_project.vw_cr_limit_by_customer AS
WITH invoice_balances AS (
    SELECT
        i.id_invoice,
        i.id_customer,
        i.issue_date,
        i.due_date,
        i.invoice_amount,
        COALESCE(SUM(p.payment_amount), 0) AS total_paid
    FROM credit_collection_project.fact_invoices i
    LEFT JOIN credit_collection_project.fact_payments p
        ON i.id_invoice = p.id_invoice
    GROUP BY i.id_invoice
),
customer_limits AS (
    SELECT
        c.id_customer,
        c.customer_name,
        c.state,
        cl.collateral_value,
        cl.insured_credit_limit,
        cl.internal_credit_limit
    FROM credit_collection_project.dim_customer c
    JOIN credit_collection_project.dim_credit_limit cl
        ON c.id_customer = cl.id_customer
)
SELECT
    cl.id_customer,
    cl.customer_name,
    cl.state,
    cl.collateral_value,
    cl.insured_credit_limit,
    cl.internal_credit_limit,
    cl.insured_credit_limit + cl.internal_credit_limit AS total_credit_limit,
    SUM(ib.invoice_amount) - SUM(ib.total_paid) AS open_receivables_balance,
    (cl.insured_credit_limit + cl.internal_credit_limit) - (SUM(ib.invoice_amount) - SUM(ib.total_paid)) AS available_credit_balance
FROM customer_limits cl 
LEFT JOIN invoice_balances ib ON cl.id_customer = ib.id_customer
GROUP BY 
    cl.id_customer,
    cl.customer_name,
    cl.state,
    cl.collateral_value,
    cl.insured_credit_limit,
    cl.internal_credit_limit;
