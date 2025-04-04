# credit_collection_project

A data warehouse project designed to simulate and analyze **accounts receivable**, **credit exposure**, **aging**, and **default risk**. Built entirely with PostgreSQL and ready for Power BI integration, this project is ideal for portfolio presentation or internal simulations.

---

## Project Goals

- Simulate realistic credit and collections data (invoices, payments, credit limits)
- Enable KPIs and dashboards such as:
  - Days Sales Outstanding (DSO)
  - Credit utilization by customer
  - Invoices in default (>90 days overdue)
  - Aging buckets (0–15, 16–30, 31–60, …)
  - Unsecured receivables
  - Provisioning (PDD)

---

## Database Structure

### Schemas

- `credit_collection_project`

### Tables

#### Dimensions
| Table              | Description                     |
|-------------------|---------------------------------|
| `dim_customer`     | Customer data                   |
| `dim_credit_limit` | Credit and guarantee limits     |
| `dim_date`         | Full date dimension             |

#### Facts
| Table              | Description                              |
|-------------------|------------------------------------------|
| `fact_invoices`    | Issued invoices                          |
| `fact_payments`    | Payments received linked to invoices     |

---

## ⚙️ Features

### Procedures

- `populate_facts(year, invoice_count)`:  
  Generates simulated invoices and payments with configurable year and volume.

### Views

| View                                | Description                                               |
|-------------------------------------|-----------------------------------------------------------|
| `vw_aging_list`                     | Open invoices with aging days                             |
| `vw_default_by_year_month`         | Defaulted balances grouped by year/month                  |
| `vw_cr_limit_by_customer`          | Credit limits vs open receivables per customer            |

---

## Dashboard-ready KPIs

- **Open Receivables**
- **Invoices in Default**
- **Available Credit**
- **Average Collection Period**
- **Unsecured Receivables**
- **Provision for Doubtful Debts (PDD)**

---

## Getting Started

1. Clone the repo
2. Create the schema and tables using `model_physical.sql`
3. Load the `dim_date` table (script provided)
4. Run `CALL credit_collection_project.populate_facts(2023, 500);` to generate sample data
5. Use Power BI or your BI tool of choice to connect and visualize

---

## 📎 License

MIT – Free to use and modify. Attribution is appreciated.

---

## ✉️ Contact

Created by **Rafael Fetter**
E-mail - rafaelfetter96@outlook.com
