use finance;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- CARDS

select
count(finance_1.id) Total_No_of_Accounts,
concat(round(sum(funded_amnt)/1000000, 2), 'M') Total_Funded_Amount,
concat(round(avg(funded_amnt)/1000, 2), 'K') Average_Funded_Amount,
concat(round((sum(funded_amnt_inv)/sum(funded_amnt))*100, 0), '%') Investors_Fund_Pct,
concat(round(avg(int_rate), 2), '%') Average_Interest_Rate,
concat(round((sum(term*installment) - sum(funded_amnt))/1000000, 2), 'M') Total_Interest_Amount,
concat(round(sum(term*installment)/1000000, 2), 'M') Total_Payable_Amount,
concat(round((sum(term*installment)- sum(total_rec_prncp + total_rec_int + recoveries))/1000000, 2), 'M') Total_Pending_Payments,
concat(round((sum(total_rec_late_fee + collection_recovery_fee))/1000, 2), 'K') Total_Fees_Accumulated,
round(avg(dti), 2) Average_DTI,
concat(round((sum(total_rec_prncp + total_rec_int + recoveries)/round(sum(term*installment), 0))*100, 0), '%') Loan_Repayment_Pct,
concat(round(avg(revol_util), 0), '%') Avg_Credit_Utilization_Pct
from finance_1
left join
finance_2
on finance_1.id = finance_2.id;

-- Cards Views based on Loan Issued Year
select * from cards_2007;
select * from cards_2008;
select * from cards_2009;
select * from cards_2010;
select * from cards_2011;
select * from cards_all;
-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- VISUALS / CHARTS

-- 1. Year Wise Funded Amount
select year(issue_d) Loan_Issued_Year, concat(round(sum(funded_amnt)/1000000, 2), 'M') Funded_Amount, 
concat(round(((sum(funded_amnt) - lag(sum(funded_amnt)) over(order by year(issue_d))) / lag(sum(funded_amnt)) over(order by year(issue_d)))*100, 0), '%') as YoY_Growth_Pct
from finance_1
group by Loan_Issued_Year
order by Loan_Issued_Year;


-- 2. Verification Status Vs Percentage of No. of Accounts
select @t_accounts := count(finance_1.id) Total_No_of_Accounts from finance_1;
select verification_status Verification_Status, concat(round((count(id)/@t_accounts)*100, 2), '%') Pct_of_Accounts
from finance_1
group by verification_status
order by count(id) desc;


-- 3. Home Ownership Vs Percentage of Funded Amount
select @t_funded := sum(funded_amnt) Total_Funded_Amount from finance_1;
select home_ownership Home_Ownership, concat(round((sum(funded_amnt)/@t_funded)*100, 2), '%') Funded_Amount
from finance_1
group by home_ownership
order by sum(funded_amnt) desc;


-- 4. Grade Vs Interest Amount Receivable
select grade Grade, concat(round(avg(int_rate), 0), '%') Average_Interest_Rate,
concat(round((sum(term*installment) - sum(funded_amnt))/1000000, 2), 'M') Interest_Amount
from finance_1
group by grade
order by grade;


-- 5. Term of Loan Vs Interest Amount Generated
select term Term_of_Loan, concat(round(avg(int_rate), 0), '%') Average_Interest_Rate,
concat(round((sum(term*installment) - sum(funded_amnt))/1000000, 2), 'M') Interest_Amount 
from finance_1
group by term
order by round((sum(term*installment) - sum(funded_amnt)), 0) desc;


-- 6. Employment Length Vs Average Annual Income & No. of Accounts
select emp_length Employment_Length, concat(round(avg(annual_inc)/1000, 2), 'K') Average_Annual_Income,
concat(round((count(id)/@t_accounts)*100, 2), '%') Pct_of_Accounts
from finance_1
group by emp_length
order by count(id) desc;


-- 7. Purpose of Loan Vs No. of Accounts, Payment Stats, Average DTI based on Loan Status
select purpose Purpose_of_Loan, count(finance_1.id) No_of_Accounts, concat(round(sum(funded_amnt)/1000000, 2), 'M') Funded_Amount,
concat(round(sum(term*installment)/1000000, 2), 'M') Total_Payable_Amount,
concat(round((sum(term*installment)- sum(total_rec_prncp + total_rec_int + recoveries))/1000000, 2), 'M') Total_Pending_Payments,
concat(round((sum(total_rec_prncp + total_rec_int + recoveries)/round(sum(term*installment), 0))*100, 0), '%') Loan_Repayment_Pct,
round(avg(dti), 2) Average_DTI, concat(round((sum(total_rec_late_fee + collection_recovery_fee))/1000, 2), 'K') Total_Fees_Accumulated
from finance_1
left join 
finance_2
on finance_1.id = finance_2.id
group by purpose
order by sum(funded_amnt) desc;

call status_loan('Charged Off');
call status_loan('Fully Paid');
call status_loan('Current');


-- 8. Grade & Sub - Grade Wise Average Revolving Balance & Credit Utilization Rate
select grade Grade, sub_grade Sub_Grade, concat(round(avg(revol_bal)/1000, 2), 'K') Sub_Grade_Wise_Average_Revolving_Balance,
concat(round(avg(revol_bal) over(partition by grade)/1000, 2), 'K') Grade_Wise_Average_Revolving_Balance,concat(round(avg(revol_util), 0), '%') Credit_Utilization_Pct
from finance_1
left join
finance_2
on finance_1.id = finance_2.id
group by finance_1.grade, finance_1.sub_grade
order by finance_1.grade, finance_1.sub_grade;


-- 9. Verification Status Vs Pending Payment Amount
select verification_status Verification_Status, 
concat(round((sum(term*installment) - sum(total_rec_prncp + total_rec_int + recoveries))/1000000, 2), 'M') Total_Pending_Payments
from finance_1
left join
finance_2
on finance_1.id = finance_2.id
group by verification_status
order by round((sum(term*installment) - sum(total_rec_prncp + total_rec_int + recoveries)), 0) desc;


-- 10. Home Ownership Vs Pending Payment Amount
select home_ownership Home_Ownership,
case when (sum(term*installment) - sum(total_rec_prncp + total_rec_int + recoveries)) >1000000 then
			concat(round((sum(term*installment) - sum(total_rec_prncp + total_rec_int + recoveries))/1000000, 2), 'M') else
			concat(round((sum(term*installment) - sum(total_rec_prncp + total_rec_int + recoveries))/1000, 2), 'K') end Total_Pending_Payments
from finance_1
left join
finance_2
on finance_1.id = finance_2.id
group by home_ownership
order by round((sum(term*installment) - sum(total_rec_prncp + total_rec_int + recoveries)), 0) desc;


-- 11. Last Payment Amount Vs Last Payment Date
select home_ownership Home_Ownership, year(last_pymnt_d) Last_Payment_Date, 
case when sum(last_pymnt_amnt) > 1000000 then
	concat(round(sum(last_pymnt_amnt)/1000000, 2), 'M') else
    concat(round(sum(last_pymnt_amnt)/1000, 2), 'K') end Last_Payment_Amount
from finance_1
left join
finance_2
on finance_1.id = finance_2.id
where last_pymnt_d is not null and last_pymnt_amnt != '0'
group by home_ownership, year(last_pymnt_d)
order by home_ownership;


-- 12. Top N States Vs No. of Accounts & Pending Payments based on Purpose of Loan
select addr_state State, count(finance_1.id) No_of_Accounts, 
case when (sum(term*installment) - sum(total_rec_prncp + total_rec_int + recoveries)) >1000000 then
			concat(round((sum(term*installment) - sum(total_rec_prncp + total_rec_int + recoveries))/1000000, 2), 'M') else
			concat(round((sum(term*installment) - sum(total_rec_prncp + total_rec_int + recoveries))/1000, 2), 'K') end Total_Pending_Payments,
concat(round((sum(total_rec_prncp + total_rec_int + recoveries)/round(sum(term*installment), 0))*100, 0), '%') Loan_Repayment_Pct
from finance_1
left join
finance_2
on finance_1.id = finance_2.id
group by addr_state
order by round((sum(term*installment) - sum(total_rec_prncp + total_rec_int + recoveries)), 0) desc
limit 5; -- Change the value of N

call top_state('3', 'car');   -- Purpose = debt_consolidation, credit_card, home_improvement, other, small_business, car, major_purchase, wedding, medical, house, moving, educational, vacation, renewable_energy