from pathlib import Path
import pandas as pd

BASE=Path('/home/ubuntu/amazon_sql_project')
a=pd.read_csv(BASE/'annual_kpi_output.csv')
s=pd.read_csv(BASE/'segment_kpi_output.csv')
q=pd.read_csv(BASE/'q2_2026_context_output.csv').iloc[0]
fy25=a[a.fiscal_year==2025].iloc[0]; fy24=a[a.fiscal_year==2024].iloc[0]
aws=s[(s.fiscal_year==2025)&(s.segment=='AWS')].iloc[0]
checks={
 'FY2025 net sales': (fy25.net_sales,716924),
 'FY2025 operating income': (fy25.operating_income,79975),
 'FY2025 operating margin': (round(fy25.operating_margin_pct,2),11.16),
 'FY2025 free cash flow': (fy25.free_cash_flow,11194),
 'FY2025 AWS sales': (aws.net_sales,128725),
 'FY2025 AWS growth': (round(aws.sales_growth_pct,1),19.7),
 'Q2 FY2026 net sales': (q.net_sales,200600),
 'Q2 FY2026 operating income': (q.operating_income,27500),
}
failed=[]
for name,(actual,expected) in checks.items():
 if actual != expected: failed.append((name,actual,expected))
assert not failed, failed
assert fy25.net_sales > fy24.net_sales
assert fy25.operating_income > fy24.operating_income
assert fy25.operating_margin_pct > fy24.operating_margin_pct
print('QA PASS')
for name,(actual,_) in checks.items(): print(f'{name}: {actual}')
