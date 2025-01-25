Create Database BA;
Use BA;
select * from finance_1;
select * from finance_2;

##### KPI 1 (YEAR WISE LOAN AMOUNT STATS) #####
select year(issue_d) as Year, sum(loan_amnt) as Total_Loan_amnt from finance_1 group by year order by year;

##### KPI 2 (GRADE AND SUB GRADE WISE REVOL_BAL) #####
select grade, sub_grade, sum(revol_bal) as total_revol_bal
from finance_1 as f1 inner join finance_2 as f2
on(f1.id = f2.id) 
group by grade,sub_grade
order by grade;


##### KPI 3 (Total Payment for Verified Status Vs Total Payment for Non Verified Status) #####
select Verification_status, round(sum(total_pymnt),2) as Total_payment
from finance_1 as f1 inner join finance_2 f2 
on(f1.id = f2.id) 
where verification_status in('Verified', 'Not Verified')
group by verification_status;


##### KPI 4 (State wise and last_credit_pull_d wise loan status) #####
select addr_state, last_credit_pull_d, loan_status, count(loan_status)
from finance_1 f1 inner join finance_2 f2 
on (f1.id = f2.id) 
group by addr_state, last_credit_pull_d, loan_status
order by addr_state;


##### KPI 5 (Home ownership Vs last payment date stats) #####
select home_ownership as Home_Ownership, year(last_pymnt_d) Last_Payment_Date, round(sum(last_pymnt_amnt),2) Last_Payment_Amount
from finance_1 left join finance_2
on finance_1.id = finance_2.id
where last_pymnt_d is not null and last_pymnt_amnt != '0'
group by home_ownership, year(last_pymnt_d)
order by home_ownership;


