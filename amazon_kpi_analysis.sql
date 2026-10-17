-- Amazon SQL Analytics Project
-- Units: USD millions unless otherwise stated.
-- Sources: Amazon FY2025 Form 10-K and Q2 2026 earnings release.
-- Engine: SQLite

DROP TABLE IF EXISTS annual_financials;
DROP TABLE IF EXISTS annual_segments;
DROP TABLE IF EXISTS annual_revenue_streams;
DROP TABLE IF EXISTS quarterly_context;

CREATE TABLE annual_financials (
    fiscal_year INTEGER PRIMARY KEY,
    net_sales REAL NOT NULL,
    operating_income REAL NOT NULL,
    net_income REAL NOT NULL,
    operating_cash_flow REAL NOT NULL,
    capex_net REAL NOT NULL,
    free_cash_flow REAL NOT NULL,
    diluted_eps REAL NOT NULL
);

INSERT INTO annual_financials VALUES
(2023, 574785, 36852, 30425, 84946, 47829, 37117, 2.90),
(2024, 637959, 68593, 59248, 115877, 77658, 38219, 5.53),
(2025, 716924, 79975, 77670, 139514, 128320, 11194, 7.17);

CREATE TABLE annual_segments (
    fiscal_year INTEGER,
    segment TEXT,
    net_sales REAL,
    operating_income REAL,
    PRIMARY KEY (fiscal_year, segment)
);

INSERT INTO annual_segments VALUES
(2023,'North America',352828,14877),
(2023,'International',131200,-2656),
(2023,'AWS',90757,24631),
(2024,'North America',387497,24967),
(2024,'International',142906,3792),
(2024,'AWS',107556,39834),
(2025,'North America',426305,29619),
(2025,'International',161894,4750),
(2025,'AWS',128725,45606);

CREATE TABLE annual_revenue_streams (
    fiscal_year INTEGER,
    revenue_stream TEXT,
    net_sales REAL,
    PRIMARY KEY (fiscal_year, revenue_stream)
);

INSERT INTO annual_revenue_streams VALUES
(2023,'Online stores',231872),(2023,'Physical stores',20030),(2023,'Third-party seller services',140053),(2023,'Advertising services',46906),(2023,'Subscription services',40209),(2023,'AWS',90757),(2023,'Other',4958),
(2024,'Online stores',247029),(2024,'Physical stores',21215),(2024,'Third-party seller services',156146),(2024,'Advertising services',56214),(2024,'Subscription services',44374),(2024,'AWS',107556),(2024,'Other',5425),
(2025,'Online stores',269287),(2025,'Physical stores',22561),(2025,'Third-party seller services',172162),(2025,'Advertising services',68635),(2025,'Subscription services',49619),(2025,'AWS',128725),(2025,'Other',5935);

CREATE TABLE quarterly_context (
    period TEXT PRIMARY KEY,
    net_sales REAL,
    operating_income REAL,
    net_income REAL,
    diluted_eps REAL,
    operating_cash_flow_ttm REAL,
    free_cash_flow_ttm REAL,
    north_america_sales REAL,
    international_sales REAL,
    aws_sales REAL,
    north_america_operating_income REAL,
    international_operating_income REAL,
    aws_operating_income REAL
);

INSERT INTO quarterly_context VALUES
('Q2 FY2026',200600,27500,62600,5.75,161400,-7600,116200,42200,42200,9100,1700,16600);

-- 1. Consolidated KPI trend with SQL-derived growth and margins.
.headers on
.mode csv
.output /home/ubuntu/amazon_sql_project/annual_kpi_output.csv
WITH trend AS (
    SELECT fiscal_year, net_sales, operating_income, net_income, operating_cash_flow,
           capex_net, free_cash_flow, diluted_eps,
           operating_income / net_sales AS operating_margin,
           free_cash_flow / net_sales AS fcf_margin,
           LAG(net_sales) OVER (ORDER BY fiscal_year) AS prior_sales,
           LAG(operating_income) OVER (ORDER BY fiscal_year) AS prior_op_income,
           LAG(net_income) OVER (ORDER BY fiscal_year) AS prior_net_income,
           LAG(free_cash_flow) OVER (ORDER BY fiscal_year) AS prior_fcf
    FROM annual_financials
)
SELECT fiscal_year, net_sales, operating_income, net_income, operating_cash_flow,
       capex_net, free_cash_flow, diluted_eps,
       ROUND(operating_margin * 100, 2) AS operating_margin_pct,
       ROUND(fcf_margin * 100, 2) AS fcf_margin_pct,
       ROUND((net_sales / prior_sales - 1) * 100, 1) AS sales_growth_pct,
       ROUND((operating_income / prior_op_income - 1) * 100, 1) AS op_income_growth_pct,
       ROUND((net_income / prior_net_income - 1) * 100, 1) AS net_income_growth_pct,
       ROUND((free_cash_flow / prior_fcf - 1) * 100, 1) AS fcf_growth_pct,
       ROUND(operating_cash_flow / capex_net, 2) AS ocf_to_capex
FROM trend;
.output stdout

-- 2. Segment growth, margin, and operating-income mix.
.output /home/ubuntu/amazon_sql_project/segment_kpi_output.csv
WITH segment_calc AS (
    SELECT fiscal_year, segment, net_sales, operating_income,
           operating_income / net_sales AS segment_margin,
           LAG(net_sales) OVER (PARTITION BY segment ORDER BY fiscal_year) AS prior_sales,
           LAG(operating_income) OVER (PARTITION BY segment ORDER BY fiscal_year) AS prior_op_income
    FROM annual_segments
)
SELECT fiscal_year, segment, net_sales, operating_income,
       ROUND(segment_margin * 100, 2) AS segment_margin_pct,
       ROUND((net_sales / prior_sales - 1) * 100, 1) AS sales_growth_pct,
       ROUND((operating_income / prior_op_income - 1) * 100, 1) AS op_income_growth_pct,
       ROUND(operating_income / SUM(operating_income) OVER (PARTITION BY fiscal_year) * 100, 1) AS op_income_mix_pct
FROM segment_calc;
.output stdout

-- 3. Revenue-stream growth and mix for 2025.
.output /home/ubuntu/amazon_sql_project/revenue_stream_output.csv
WITH stream_calc AS (
    SELECT fiscal_year, revenue_stream, net_sales,
           LAG(net_sales) OVER (PARTITION BY revenue_stream ORDER BY fiscal_year) AS prior_sales,
           SUM(net_sales) OVER (PARTITION BY fiscal_year) AS total_stream_sales
    FROM annual_revenue_streams
)
SELECT fiscal_year, revenue_stream, net_sales,
       ROUND(net_sales / total_stream_sales * 100, 1) AS mix_pct,
       ROUND((net_sales / prior_sales - 1) * 100, 1) AS growth_pct
FROM stream_calc;
.output stdout

-- 4. Q2 2026 context with segment mix and operating-income mix.
.output /home/ubuntu/amazon_sql_project/q2_2026_context_output.csv
SELECT period, net_sales, operating_income, net_income, diluted_eps,
       operating_cash_flow_ttm, free_cash_flow_ttm,
       ROUND(operating_income / net_sales * 100, 2) AS operating_margin_pct,
       ROUND(operating_cash_flow_ttm / NULLIF(ABS(free_cash_flow_ttm),0), 2) AS ocf_to_abs_fcf,
       ROUND(north_america_sales / net_sales * 100, 1) AS north_america_sales_mix_pct,
       ROUND(international_sales / net_sales * 100, 1) AS international_sales_mix_pct,
       ROUND(aws_sales / net_sales * 100, 1) AS aws_sales_mix_pct,
       ROUND(north_america_operating_income / operating_income * 100, 1) AS north_america_op_income_mix_pct,
       ROUND(international_operating_income / operating_income * 100, 1) AS international_op_income_mix_pct,
       ROUND(aws_operating_income / operating_income * 100, 1) AS aws_op_income_mix_pct
FROM quarterly_context;
.output stdout
