
-- SQL Challenge
-- Setup source: Employees, Sales, and Products tables

use SQL_Challenge;

-- Q1 — Salary Ranking With Ties

SELECT
    dept,
    name,
    salary,
    DENSE_RANK() OVER (
        PARTITION BY dept
        ORDER BY salary DESC
    ) AS salary_rank,
    MAX(salary) OVER (
        PARTITION BY dept
    ) - salary AS below_top_earner
FROM Employees
ORDER BY dept, salary_rank, name;


-- Q2 — Month-Over-Month Growth


WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(sale_date, '%Y-%m') AS sales_month,
        SUM(amount) AS total_sales
    FROM Sales
    GROUP BY DATE_FORMAT(sale_date, '%Y-%m')
),
with_previous AS (
    SELECT
        sales_month,
        total_sales,
        LAG(total_sales) OVER (
            ORDER BY sales_month
        ) AS previous_month_total
    FROM monthly_sales
)
SELECT
    sales_month,
    total_sales,
    previous_month_total,
    CASE
        WHEN previous_month_total IS NULL
             OR previous_month_total = 0
        THEN NULL
        ELSE ROUND(
            (total_sales - previous_month_total)
            * 100.0 / previous_month_total,
            2
        )
    END AS percentage_change
FROM with_previous
ORDER BY sales_month;

-- Q3 — Top Performer Per Region

WITH employee_region_sales AS (
    SELECT
        s.region,
        e.emp_id,
        e.name,
        SUM(s.amount) AS total_sales,
        RANK() OVER (
            PARTITION BY s.region
            ORDER BY SUM(s.amount) DESC
        ) AS region_rank
    FROM Sales s
    JOIN Employees e
        ON e.emp_id = s.emp_id
    GROUP BY s.region, e.emp_id, e.name
)
SELECT
    region,
    emp_id,
    name,
    total_sales
FROM employee_region_sales
WHERE region_rank = 1
ORDER BY region, name;


-- Q4 — Employees With No Sales

SELECT
    e.emp_id,
    e.name,
    e.dept
FROM Employees e
LEFT JOIN Sales s
    ON s.emp_id = e.emp_id
WHERE s.emp_id IS NULL
ORDER BY e.dept, e.name;


-- Q5 — Management Hierarchy Depth

WITH RECURSIVE hierarchy AS (
    SELECT
        emp_id,
        name,
        mgr_id,
        0 AS level
    FROM Employees
    WHERE mgr_id IS NULL

    UNION ALL

    SELECT
        e.emp_id,
        e.name,
        e.mgr_id,
        h.level + 1
    FROM Employees e
    JOIN hierarchy h
        ON e.mgr_id = h.emp_id
)
SELECT
    level,
    COUNT(*) AS employee_count,
    GROUP_CONCAT(name, ', ') AS employee_names
FROM hierarchy
GROUP BY level
ORDER BY level;


-- Q6 — Products Against Category Average

SELECT
    product_id,
    category,
    price,
    ROUND(
        AVG(price) OVER (PARTITION BY category),
        2
    ) AS category_average_price,
    ROUND(
        (price - AVG(price) OVER (PARTITION BY category))
        * 100.0
        / NULLIF(AVG(price) OVER (PARTITION BY category), 0),
        2
    ) AS percentage_from_category_average
FROM Products
ORDER BY category, product_id;


-- Q7 — Running Total and Moving Average

WITH employee_sales AS (
    SELECT
        s.sale_id,
        s.sale_date,
        s.amount
    FROM Sales s
    JOIN Employees e
        ON e.emp_id = s.emp_id
    WHERE e.name = 'Priya'
)
SELECT
    sale_id,
    sale_date,
    amount,
    SUM(amount) OVER (
        ORDER BY sale_date, sale_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total,
    ROUND(
        AVG(amount) OVER (
            ORDER BY sale_date, sale_id
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moving_average_3_sales
FROM employee_sales
ORDER BY sale_date, sale_id;


-- Q8 — Tenure Bands

WITH tenure_bands AS (
    SELECT
        CASE
            WHEN hire_date < '2021-01-01'
                THEN 'Before 2021'
            WHEN hire_date < '2023-01-01'
                THEN '2021 to 2022'
            ELSE '2023 onward'
        END AS tenure_band,
        salary
    FROM Employees
)
SELECT
    tenure_band,
    COUNT(*) AS headcount,
    ROUND(AVG(salary), 2) AS average_salary
FROM tenure_bands
GROUP BY tenure_band
ORDER BY average_salary DESC;
