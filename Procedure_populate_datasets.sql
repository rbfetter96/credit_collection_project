CREATE OR REPLACE PROCEDURE credit_collection_project.populate_facts(
    target_year INT,
    invoice_count INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_invoice_id INT;
    v_payment_id INT;
    v_customer_id INT;
    v_issue_date DATE;
    v_due_date DATE;
    v_amount DECIMAL(14,2);
    v_installments INT;
    v_installment_amount DECIMAL(14,2);
    v_payment_date DATE;
    v_payment_type TEXT;
BEGIN

    SELECT COALESCE(MAX(id_invoice), 0) + 1 INTO v_invoice_id
    FROM credit_collection_project.fact_invoices;

    SELECT COALESCE(MAX(id_payment), 0) + 1 INTO v_payment_id
    FROM credit_collection_project.fact_payments;

    FOR i IN 1..invoice_count LOOP

        -- Random customer
        SELECT id_customer INTO v_customer_id
        FROM credit_collection_project.dim_customer
        ORDER BY random()
        LIMIT 1;

        -- Random issue date within target year
        SELECT full_date INTO v_issue_date
        FROM credit_collection_project.dim_date
        WHERE EXTRACT(YEAR FROM full_date) = target_year
        ORDER BY random()
        LIMIT 1;

        -- Due date: +30, +60, or +90 days
        v_due_date := v_issue_date + (ARRAY[30, 60, 90])[floor(random()*3+1)::int];

        -- Random invoice amount
        v_amount := ROUND((random()*4000 + 1000)::numeric, 2);

        -- Insert invoice with NULLs for amount_paid and open_balance
        INSERT INTO credit_collection_project.fact_invoices (
            id_invoice, id_customer, issue_date, due_date,
            payment_method, invoice_amount, amount_paid, open_balance
        ) VALUES (
            v_invoice_id, v_customer_id, v_issue_date, v_due_date,
            'Boleto', v_amount, NULL, NULL
        );

        -- Define payment behavior
        v_payment_type := CASE
            WHEN random() < 0.10 THEN 'none'
            WHEN random() < 0.85 THEN '1'
            WHEN random() < 0.97 THEN '2+'
            ELSE 'partial'
        END;

        IF v_payment_type = '1' THEN
            -- Single payment
            SELECT full_date INTO v_payment_date
            FROM credit_collection_project.dim_date
            WHERE full_date BETWEEN v_issue_date AND v_issue_date + INTERVAL '120 days'
            ORDER BY random()
            LIMIT 1;

            INSERT INTO credit_collection_project.fact_payments (
                id_payment, id_invoice, id_customer, payment_date, payment_amount
            ) VALUES (
                v_payment_id, v_invoice_id, v_customer_id, v_payment_date, v_amount
            );

            v_payment_id := v_payment_id + 1;

        ELSIF v_payment_type = '2+' THEN
            -- 2 or 3 payments
            v_installments := floor(random()*2 + 2)::INT;
            FOR j IN 1..v_installments LOOP
                SELECT full_date INTO v_payment_date
                FROM credit_collection_project.dim_date
                WHERE full_date BETWEEN v_issue_date AND v_issue_date + INTERVAL '120 days'
                ORDER BY random()
                LIMIT 1;

                v_installment_amount := ROUND((v_amount / v_installments)::numeric, 2);

                INSERT INTO credit_collection_project.fact_payments (
                    id_payment, id_invoice, id_customer, payment_date, payment_amount
                ) VALUES (
                    v_payment_id, v_invoice_id, v_customer_id, v_payment_date, v_installment_amount
                );

                v_payment_id := v_payment_id + 1;
            END LOOP;

        ELSIF v_payment_type = 'partial' THEN
            -- Partial payments with varied amounts
            v_installments := floor(random()*2 + 2)::INT;
            FOR j IN 1..v_installments LOOP
                SELECT full_date INTO v_payment_date
                FROM credit_collection_project.dim_date
                WHERE full_date BETWEEN v_issue_date AND v_issue_date + INTERVAL '120 days'
                ORDER BY random()
                LIMIT 1;

                v_installment_amount := ROUND(((v_amount / v_installments) * random())::numeric, 2);

                INSERT INTO credit_collection_project.fact_payments (
                    id_payment, id_invoice, id_customer, payment_date, payment_amount
                ) VALUES (
                    v_payment_id, v_invoice_id, v_customer_id, v_payment_date, v_installment_amount
                );

                v_payment_id := v_payment_id + 1;
            END LOOP;
        END IF;

        v_invoice_id := v_invoice_id + 1;

    END LOOP;
END;
$$;
