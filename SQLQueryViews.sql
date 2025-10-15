--Base View
----------------
CREATE VIEW vw_Loan_Base AS
SELECT
    id,
    issue_date,
    loan_status,
    loan_amount,
    total_payment,
    int_rate,
    dti,
    term,
    purpose,
    emp_length,
    home_ownership,
    address_state
FROM bank_loan_data
WHERE issue_date IS NOT NULL;

--KPIs View
---------------
CREATE VIEW vw_KPI_Summary AS
SELECT
    YEAR(issue_date) AS Year,
    MONTH(issue_date) AS Month,
    COUNT(id) AS Total_Loans,
    SUM(loan_amount) AS Total_Funded_Amount,
    SUM(total_payment) AS Total_Amount_Received,
    AVG(CAST(int_rate AS FLOAT)) * 100 AS Avg_Int_Rate,
    AVG(CAST(dti AS FLOAT)) * 100 AS Avg_DTI,
    SUM(CASE WHEN loan_status IN ('Fully Paid', 'Current') THEN 1 ELSE 0 END) AS Good_Loans,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS Bad_Loans
FROM vw_Loan_Base
GROUP BY YEAR(issue_date), MONTH(issue_date);

--Analysis Views
------------------
CREATE VIEW vw_Loan_Status AS
SELECT
    loan_status,
    COUNT(id) AS Total_Loans,
    SUM(loan_amount) AS Total_Funded,
    SUM(total_payment) AS Total_Received,
    AVG(int_rate) * 100 AS Avg_Int_Rate,
    AVG(dti) * 100 AS Avg_DTI
FROM vw_Loan_Base
GROUP BY loan_status;


-- Monthly Trend
------------------
CREATE VIEW vw_Monthly_Trend AS
SELECT
    YEAR(issue_date) AS Year,
    MONTH(issue_date) AS Month,
    DATENAME(MONTH, issue_date) AS Month_Name,
    COUNT(id) AS Total_Loans,
    SUM(loan_amount) AS Total_Funded,
    SUM(total_payment) AS Total_Received,
    AVG(CAST(int_rate AS FLOAT)) * 100 AS Avg_Int_Rate
FROM vw_Loan_Base
GROUP BY YEAR(issue_date), MONTH(issue_date), DATENAME(MONTH, issue_date);


-- Regional Analysis
----------------------
CREATE VIEW vw_Regional_Analysis AS
SELECT
    address_state,
    COUNT(id) AS Total_Loans,
    SUM(loan_amount) AS Total_Funded,
    SUM(total_payment) AS Total_Received
FROM vw_Loan_Base
GROUP BY address_state;


-- Term Analysis
-------------------

CREATE VIEW vw_Term_Analysis AS
SELECT
    term,
    COUNT(id) AS Total_Loans,
    SUM(loan_amount) AS Total_Funded,
    SUM(total_payment) AS Total_Received
FROM vw_Loan_Base
GROUP BY term;


-- Purpose Breakdown
----------------------
CREATE VIEW vw_Purpose_Analysis AS
SELECT
    purpose,
    COUNT(id) AS Total_Loans,
    SUM(loan_amount) AS Total_Funded,
    SUM(total_payment) AS Total_Received,
    AVG(CAST(int_rate AS FLOAT)) * 100 AS Avg_Int_Rate
FROM vw_Loan_Base
GROUP BY purpose;


-- Home Ownership
----------------------
CREATE VIEW vw_Home_Ownership AS
SELECT
    home_ownership,
    COUNT(id) AS Total_Loans,
    SUM(loan_amount) AS Total_Funded,
    SUM(total_payment) AS Total_Received
FROM vw_Loan_Base
GROUP BY home_ownership;


---------------------------
-- Dimension Views (SLICERS)
---------------------------
-- Date Dimension
CREATE VIEW vw_Dim_Date AS
SELECT DISTINCT
    YEAR(issue_date) AS Year,
    MONTH(issue_date) AS Month,
    DATENAME(MONTH, issue_date) AS Month_Name
FROM vw_Loan_Base;


--Purpose Dimension
CREATE VIEW vw_Dim_Purpose AS
SELECT DISTINCT purpose FROM vw_Loan_Base;

--State Dimension
CREATE VIEW vw_Dim_State AS
SELECT DISTINCT address_state FROM vw_Loan_Base;

SELECT *
FROM vw_KPI_Summary;

CREATE VIEW vw_bank_loans_clean AS
SELECT
    id,
    issue_date,
    loan_amount,
    total_payment,
    loan_status,
    CASE 
        WHEN loan_status IN ('Fully Paid', 'Current') THEN 'Good Loan'
        WHEN loan_status = 'Charged Off' THEN 'Bad Loan'
        ELSE 'Other'
    END AS loan_category
FROM bank_loan_data;
USE BankLoanDB;
