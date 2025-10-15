USE BankLoanDB;

SELECT *
FROM dbo.bank_loan_data;
-----------------------------
-- 1-Total loan applications
-----------------------------
SELECT COUNT(id) AS total_loan_applications
FROM dbo.bank_loan_data;

--MTD total loan applications
SELECT COUNT(id) AS MTD_total_loan_applications
FROM bank_loan_data
WHERE 
	MONTH(issue_date) = (SELECT MAX(MONTH(issue_date))
						FROM bank_loan_data)
	AND 
	YEAR(issue_date) = (SELECT MAX(YEAR(issue_date))
						FROM bank_loan_data);
------------------------------------
--PMTD
------------------------------------
SELECT COUNT(id) AS MTD_total_loan_applications
FROM bank_loan_data
WHERE 
	MONTH(issue_date) = (SELECT MAX(MONTH(issue_date)-1)
						FROM bank_loan_data)
	AND 
	YEAR(issue_date) = (SELECT MAX(YEAR(issue_date))
						FROM bank_loan_data);
------------------------------------
--MOM => (MTD-PMTD) / PMTD
------------------------------------
WITH mtd AS (
    SELECT 
        COUNT(id) AS MTD_total_loan_applications
    FROM bank_loan_data
    WHERE 
        MONTH(issue_date) = (SELECT MAX(MONTH(issue_date)) FROM bank_loan_data)
        AND YEAR(issue_date) = (SELECT MAX(YEAR(issue_date)) FROM bank_loan_data)
),
pmtd AS (
    SELECT 
        COUNT(id) AS PMTD_total_loan_applications
    FROM bank_loan_data
    WHERE 
        -- Get the previous month from the latest issue_date
        MONTH(issue_date) = (
            CASE 
                WHEN (SELECT MAX(MONTH(issue_date)) FROM bank_loan_data) = 1 
                THEN 12  -- if current month is January → previous is December
                ELSE (SELECT MAX(MONTH(issue_date)) - 1 FROM bank_loan_data)
            END
        )
        AND YEAR(issue_date) = (
            CASE 
                WHEN (SELECT MAX(MONTH(issue_date)) FROM bank_loan_data) = 1 
                THEN (SELECT MAX(YEAR(issue_date)) - 1 FROM bank_loan_data)
                ELSE (SELECT MAX(YEAR(issue_date)) FROM bank_loan_data)
            END
        )
)
SELECT 
    m.MTD_total_loan_applications,
    p.PMTD_total_loan_applications,
	CONCAT(
	ROUND(
    CASE 
        WHEN p.PMTD_total_loan_applications = 0 THEN NULL
        ELSE (CAST((m.MTD_total_loan_applications - p.PMTD_total_loan_applications) AS FLOAT) 
             / p.PMTD_total_loan_applications)*100
    END
	,2),'%'
	) AS MOM_Growth_Rate
FROM mtd m
CROSS JOIN pmtd p;

------------------------------------
-- 2- Total Funded Amount
------------------------------------
SELECT SUM(loan_amount) AS total_funded_amount
FROM bank_loan_data;

--MTD
SELECT SUM(loan_amount) AS MTD_total_funded_amount
FROM bank_loan_data
WHERE MONTH(issue_date) = (
					SELECT MAX(MONTH(issue_date))
					FROM bank_loan_data)

	AND
	YEAR(issue_date) = (SELECT MAX(YEAR(issue_date))
					FROM bank_loan_data);
------------------------------------
--PMTD
SELECT SUM(loan_amount) AS PMTD_total_funded_amount
FROM bank_loan_data
WHERE MONTH(issue_date) = (
					SELECT MAX(MONTH(issue_date))-1
					FROM bank_loan_data)

	AND
	YEAR(issue_date) = (SELECT MAX(YEAR(issue_date))
					FROM bank_loan_data);

----------------------------------------
--MOM for KPI
----------------------------------------
WITH mtd AS(
		SELECT SUM(loan_amount) AS MTD_total_funded_amount
		FROM bank_loan_data
		WHERE MONTH(issue_date) = (
					SELECT MAX(MONTH(issue_date))
					FROM bank_loan_data)

			AND
		YEAR(issue_date) = (SELECT MAX(YEAR(issue_date))
					FROM bank_loan_data)

),pmtd AS(
	SELECT SUM(loan_amount) AS PMTD_total_funded_amount
	FROM bank_loan_data
	WHERE MONTH(issue_date) = (
						SELECT MAX(MONTH(issue_date))-1
						FROM bank_loan_data)

		AND
	YEAR(issue_date) = (SELECT MAX(YEAR(issue_date))
					FROM bank_loan_data)
)
SELECT
	m.MTD_total_funded_amount as current_month,
	p.PMTD_total_funded_amount as prev_month,
	CONCAT(
	ROUND
	(CAST(m.MTD_total_funded_amount-p.PMTD_total_funded_amount AS FLOAT)
	/(p.PMTD_total_funded_amount) *100,2),'%') AS MOM_change
FROM mtd m
CROSS JOIN pmtd p;

----------------------------------------
--MOM for Trend
----------------------------------------
WITH summary_month AS (
	SELECT 
		MONTH(issue_date) AS month_num,
		SUM(loan_amount) AS total_amount
	FROM bank_loan_data
	GROUP BY MONTH(issue_date)
)
,mom_change AS(
	SELECT 
		month_num,
		total_amount as current_month,
		LAG(total_amount) OVER(ORDER BY month_num) AS prev_month
	FROM summary_month
)
SELECT 
	month_num,
	current_month,
	prev_month,
	CONCAT(
	ROUND
		(CAST(current_month-prev_month AS FLOAT)/prev_month * 100,2 ),'%') AS MOM_change
FROM mom_change
ORDER BY 1 DESC;


--------------------------------------
-- 3- Total Amount Recieved
--------------------------------------
SELECT 
	SUM(total_payment) AS total_amount_recieved
FROM bank_loan_data;

--------------------------------------
--MTD
SELECT 
	SUM(total_payment) AS MTD_total_amount_recieved
FROM bank_loan_data
WHERE MONTH(issue_date)=(SELECT MAX(MONTH(issue_date))
						FROM bank_loan_data)
	AND
	YEAR(issue_date) = (SELECT MAX(YEAR(issue_date))
						FROM bank_loan_data);

------------------------------
--PMTD
------------------------------
SELECT 
	SUM(total_payment) AS PMTD_total_amount_recieved
FROM bank_loan_data
WHERE MONTH(issue_date)=(SELECT MAX(MONTH(issue_date))-1
						FROM bank_loan_data)
	AND
	YEAR(issue_date) = (SELECT MAX(YEAR(issue_date))
						FROM bank_loan_data);

------------------------------
--MOM for KPI
------------------------------
WITH mtd AS(
		SELECT 
	SUM(total_payment) AS MTD_total_amount_recieved
	FROM bank_loan_data
	WHERE MONTH(issue_date)=(SELECT MAX(MONTH(issue_date))
						FROM bank_loan_data)
	AND
	YEAR(issue_date) = (SELECT MAX(YEAR(issue_date))
						FROM bank_loan_data)
),pmtd AS(
	SELECT 
	SUM(total_payment) AS PMTD_total_amount_recieved
	FROM bank_loan_data
	WHERE MONTH(issue_date)=(SELECT MAX(MONTH(issue_date))-1
						FROM bank_loan_data)
		AND
	YEAR(issue_date) = (SELECT MAX(YEAR(issue_date))
						FROM bank_loan_data)
)
SELECT
	m.MTD_total_amount_recieved as current_month,
	p.PMTD_total_amount_recieved as prev_month,
	CONCAT(
	ROUND
	(CAST(m.MTD_total_amount_recieved-p.PMTD_total_amount_recieved AS FLOAT)
	/(p.PMTD_total_amount_recieved) *100,2),'%') AS MOM_change
FROM mtd m
CROSS JOIN pmtd p;

------------------------------
--MOM for Trend
------------------------------
WITH monthly_summary AS (
    SELECT
        YEAR(issue_date) AS year_num,
        MONTH(issue_date) AS month_num,
        SUM(total_payment) AS total_amount_received
    FROM bank_loan_data
    GROUP BY YEAR(issue_date), MONTH(issue_date)
),
mom_calc AS (
    SELECT
        year_num,
        month_num,
        total_amount_received AS current_month,
        LAG(total_amount_received) OVER (ORDER BY year_num, month_num) AS prev_month
    FROM monthly_summary
)
SELECT 
    month_num,
    current_month,
    prev_month,
    CONCAT(
        ROUND(
            CAST((current_month - prev_month) AS FLOAT) / prev_month * 100, 
            2
        ),
        '%'
    ) AS MOM_change
FROM mom_calc
ORDER BY month_num DESC;

------------------------------------------
-- 4- Average Intrest rate
------------------------------------------
SELECT
	CONCAT(
		ROUND(
			AVG(CAST(int_rate AS FLOAT))*100,2)
			,'%') AS average_rate
FROM bank_loan_data;


-----------------------------------------
--MTD
-----------------------------------------
SELECT
	CONCAT(
		ROUND(
			AVG(CAST(int_rate AS FLOAT))*100,2)
			,'%') AS MTD_average_rate
FROM bank_loan_data
WHERE MONTH(issue_date) = (SELECT MAX(MONTH(issue_date))
							FROM bank_loan_data)
	AND
	YEAR(issue_date) = (SELECT MAX(YEAR(issue_date))
							FROM bank_loan_data);


-----------------------------------------
--PMTD
-----------------------------------------
SELECT
	CONCAT(
		ROUND(
			AVG(CAST(int_rate AS FLOAT))*100,2)
			,'%') AS PMTD_average_rate
FROM bank_loan_data
WHERE MONTH(issue_date) = (SELECT MAX(MONTH(issue_date))-1
							FROM bank_loan_data)
	AND
	YEAR(issue_date) = (SELECT MAX(YEAR(issue_date))
							FROM bank_loan_data);

-----------------------------------------
--MOM
-----------------------------------------
WITH MTD AS (
    SELECT 
        AVG(CAST(int_rate AS FLOAT)) AS avg_mtd
    FROM bank_loan_data
    WHERE 
        MONTH(issue_date) = (SELECT MAX(MONTH(issue_date)) FROM bank_loan_data)
        AND YEAR(issue_date) = (SELECT MAX(YEAR(issue_date)) FROM bank_loan_data)
),
PMTD AS (
    SELECT 
        AVG(CAST(int_rate AS FLOAT)) AS avg_pmtd
    FROM bank_loan_data
    WHERE 
        MONTH(issue_date) = (
            CASE 
                WHEN (SELECT MAX(MONTH(issue_date)) FROM bank_loan_data) = 1 THEN 12
                ELSE (SELECT MAX(MONTH(issue_date)) - 1 FROM bank_loan_data)
            END
        )
        AND YEAR(issue_date) = (
            CASE 
                WHEN (SELECT MAX(MONTH(issue_date)) FROM bank_loan_data) = 1 
                THEN (SELECT MAX(YEAR(issue_date)) - 1 FROM bank_loan_data)
                ELSE (SELECT MAX(YEAR(issue_date)) FROM bank_loan_data)
            END
        )
)
SELECT 
    CONCAT(ROUND(m.avg_mtd * 100, 2), '%') AS MTD_Average_Rate,
    CONCAT(ROUND(p.avg_pmtd * 100, 2), '%') AS PMTD_Average_Rate,
    CONCAT(
        ROUND(
            CASE 
                WHEN p.avg_pmtd = 0 THEN NULL
                ELSE ((m.avg_mtd - p.avg_pmtd) / p.avg_pmtd) * 100
            END
        , 2),
        '%'
    ) AS MOM_Growth
FROM MTD m
CROSS JOIN PMTD p;


-----------------------------------------
--MOM for Trend
-----------------------------------------
WITH monthly_avg AS (
    SELECT
        YEAR(issue_date) AS year_num,
        MONTH(issue_date) AS month_num,
        AVG(CAST(int_rate AS FLOAT)) AS avg_rate
    FROM bank_loan_data
    GROUP BY YEAR(issue_date), MONTH(issue_date)
),
trend AS (
    SELECT
        year_num,
        month_num,
        avg_rate,
        LAG(avg_rate) OVER (ORDER BY year_num, month_num) AS prev_avg_rate,
        ROUND(
            CASE 
                WHEN LAG(avg_rate) OVER (ORDER BY year_num, month_num) = 0 THEN NULL
                ELSE ((avg_rate - LAG(avg_rate) OVER (ORDER BY year_num, month_num)) 
                        / LAG(avg_rate) OVER (ORDER BY year_num, month_num)) * 100
            END,
        2) AS MOM_Growth
    FROM monthly_avg
)
SELECT
    CONCAT(year_num, '-', RIGHT('0' + CAST(month_num AS VARCHAR(2)), 2)) AS period,
    ROUND(avg_rate * 100, 2) AS MTD_Average_Rate,
    ROUND(prev_avg_rate * 100, 2) AS PMTD_Average_Rate,
    MOM_Growth
FROM trend
ORDER BY month_num DESC;


------------------------------------
-- 5- Average Debt-to-Income Ratio (DTI)
------------------------------------
SELECT
	CONCAT(
		ROUND(
			AVG(CAST(dti AS FLOAT))*100,2)
			,'%') AS average_DTI
FROM bank_loan_data;
------------------------------------
--MTD
------------------------------------
SELECT
	CONCAT(
		ROUND(
			AVG(CAST(dti AS FLOAT))*100,2)
			,'%') AS MTD_average_DTI
FROM bank_loan_data
WHERE MONTH(issue_date) = (SELECT MAX(MONTH(issue_date))
							FROM bank_loan_data)
	AND
	YEAR(issue_date) = (SELECT MAX(YEAR(issue_date))
							FROM bank_loan_data);


------------------------------------
--PMTD
------------------------------------
SELECT
	CONCAT(
		ROUND(
			AVG(CAST(dti AS FLOAT))*100,2)
			,'%') AS PMTD_average_DTI
FROM bank_loan_data
WHERE MONTH(issue_date) = (SELECT MAX(MONTH(issue_date))-1
							FROM bank_loan_data)
	AND
	YEAR(issue_date) = (SELECT MAX(YEAR(issue_date))
							FROM bank_loan_data);

------------------------------------
--MOM for KPI
------------------------------------
WITH MTD AS (
    SELECT 
        AVG(CAST(dti AS FLOAT)) AS avg_mtd
    FROM bank_loan_data
    WHERE 
        MONTH(issue_date) = (SELECT MAX(MONTH(issue_date)) FROM bank_loan_data)
        AND YEAR(issue_date) = (SELECT MAX(YEAR(issue_date)) FROM bank_loan_data)
),
PMTD AS (
    SELECT 
        AVG(CAST(dti AS FLOAT)) AS avg_pmtd
    FROM bank_loan_data
    WHERE 
        MONTH(issue_date) = (
            CASE 
                WHEN (SELECT MAX(MONTH(issue_date)) FROM bank_loan_data) = 1 THEN 12
                ELSE (SELECT MAX(MONTH(issue_date)) - 1 FROM bank_loan_data)
            END
        )
        AND YEAR(issue_date) = (
            CASE 
                WHEN (SELECT MAX(MONTH(issue_date)) FROM bank_loan_data) = 1 
                THEN (SELECT MAX(YEAR(issue_date)) - 1 FROM bank_loan_data)
                ELSE (SELECT MAX(YEAR(issue_date)) FROM bank_loan_data)
            END
        )
)
SELECT 
    CONCAT(ROUND(m.avg_mtd * 100, 2), '%') AS MTD_Average_Rate,
    CONCAT(ROUND(p.avg_pmtd * 100, 2), '%') AS PMTD_Average_Rate,
    CONCAT(
        ROUND(
            CASE 
                WHEN p.avg_pmtd = 0 THEN NULL
                ELSE ((m.avg_mtd - p.avg_pmtd) / p.avg_pmtd) * 100
            END
        , 2),
        '%'
    ) AS MOM_Growth
FROM MTD m
CROSS JOIN PMTD p;

 ---------------------------------------------
 -- 6- Good Loan Applications
 ---------------------------------------------
 SELECT COUNT(id) AS Good_loan_applications
 FROM bank_loan_data
 WHERE loan_status IN('Fully Paid','Current');

 /* ---------------------------------------------
 7- Good Loan Applications
		-Total good loans
		-Good loan application percentage
		-Good loan funded Amount
		-Good loan Total recieved amount
 ---------------------------------------------*/
 WITH good_loan AS(
	 SELECT COUNT(id) AS Good_loan_applications
	 FROM bank_loan_data
	 WHERE loan_status IN('Fully Paid','Current')
 )
,total_loans AS(
	SELECT COUNT(id) AS total_loan
	FROM bank_loan_data
)
,good_funded AS(
	SELECT SUM(loan_amount) AS good_loan_funded_amount
	FROM bank_loan_data
	WHERE loan_status IN('Fully Paid','Current')

),
good_recieved AS(
	SELECT SUM(total_payment) AS good_loan_recieved_amount
	FROM bank_loan_data
	WHERE loan_status IN('Fully Paid','Current')

)
SELECT 
	Good_loan_applications AS total_good_loans,
	CONCAT(
		ROUND(
			CAST(g.Good_loan_applications AS FLOAT)/t.total_loan *100,2),'%')
			AS good_loan_percentage,
	f.good_loan_funded_amount,
	r.good_loan_recieved_amount
FROM good_loan g
CROSS JOIN total_loans t
CROSS JOIN good_funded f
CROSS JOIN good_recieved r;


 /* ---------------------------------------------
 8- Bad Loan Applications
		-Total Bad loans
		-Bad loan application percentage
		-Bad loan funded Amount
		-Bad loan Total recieved amount
 ---------------------------------------------*/
 WITH bad_loan AS(
	 SELECT COUNT(id) AS Bad_loan_applications
	 FROM bank_loan_data
	 WHERE loan_status ='Charged Off'
 )
,total_loans AS(
	SELECT COUNT(id) AS total_loan
	FROM bank_loan_data
)
,bad_funded AS(
	SELECT SUM(loan_amount) AS bad_loan_funded_amount
	FROM bank_loan_data
	WHERE loan_status ='Charged Off'

),
bad_recieved AS(
	SELECT SUM(total_payment) AS bad_loan_recieved_amount
	FROM bank_loan_data
	WHERE loan_status ='Charged Off'

)
SELECT 
	Bad_loan_applications AS total_bad_loans,
	CONCAT(
		ROUND(
			CAST(b.Bad_loan_applications AS FLOAT)/t.total_loan *100,2),'%')
			AS good_loan_percentage,
	f.bad_loan_funded_amount,
	r.bad_loan_recieved_amount
FROM bad_loan b
CROSS JOIN total_loans t
CROSS JOIN bad_funded f
CROSS JOIN bad_recieved r;


----------------------------------------
-- 9- Loan Status Grid View
----------------------------------------
WITH latest_month_year AS (
    SELECT 
        MONTH(MAX(issue_date)) AS latest_month,
        YEAR(MAX(issue_date)) AS latest_year
    FROM bank_loan_data
)
SELECT
    b.loan_status,
    COUNT(b.id) AS total_loan,
    SUM(b.loan_amount) AS total_funded_amount,
    SUM(b.total_payment) AS total_amount_recieved,

    -- MTD Funded Amount
    SUM(
        CASE 
            WHEN MONTH(b.issue_date) = l.latest_month 
                 AND YEAR(b.issue_date) = l.latest_year 
            THEN b.loan_amount 
            ELSE 0 
        END
    ) AS MTD_funded_amount,

    -- MTD Received Amount
    SUM(
        CASE 
            WHEN MONTH(b.issue_date) = l.latest_month 
                 AND YEAR(b.issue_date) = l.latest_year 
            THEN b.total_payment 
            ELSE 0 
        END
    ) AS MTD_recieved_amount,

    AVG(b.int_rate)*100 AS average_interest_rate,
    AVG(b.dti)*100 AS average_DTI

FROM bank_loan_data b
CROSS JOIN latest_month_year l
GROUP BY b.loan_status;

----------------------------------------
--10- Monthly trends by issue date
----------------------------------------
SELECT 
	MONTH(issue_date) AS Month_number,
	DATENAME(MONTH,issue_date)As Month_name,
	COUNT(id) AS total_loans,
	SUM(loan_amount) AS total_amounts,
	SUM(total_payment) AS total_recieved
FROM bank_loan_data
GROUP BY MONTH(issue_date),DATENAME(MONTH,issue_date)
ORDER BY MONTH(issue_date);


----------------------------------------
--11- Regional Analysis by State
----------------------------------------
SELECT 
	address_state,
	COUNT(id) AS total_loans,
	SUM(loan_amount) AS total_amounts,
	SUM(total_payment) AS total_recieved
FROM bank_loan_data
GROUP BY address_state
ORDER BY COUNT(id) DESC;

----------------------------------------
--12-Loan Term Analysis
----------------------------------------
SELECT 
	term,
	COUNT(id) AS total_loans,
	SUM(loan_amount) AS total_amounts,
	SUM(total_payment) AS total_recieved
FROM bank_loan_data
GROUP BY term
ORDER BY COUNT(id) DESC;

----------------------------------------
--13-Employee Length Analysis
----------------------------------------
SELECT 
	emp_length,
	COUNT(id) AS total_loans,
	SUM(loan_amount) AS total_amounts,
	SUM(total_payment) AS total_recieved
FROM bank_loan_data
GROUP BY emp_length
ORDER BY COUNT(id) DESC;

----------------------------------------
--14-Loan Purpose Breakdown
----------------------------------------
SELECT 
	purpose,
	COUNT(id) AS total_loans,
	SUM(loan_amount) AS total_amounts,
	SUM(total_payment) AS total_recieved
FROM bank_loan_data
GROUP BY purpose
ORDER BY COUNT(id) DESC;

----------------------------------------
--15-Home Ownership Analysis
----------------------------------------
SELECT 
	home_ownership,
	COUNT(id) AS total_loans,
	SUM(loan_amount) AS total_amounts,
	SUM(total_payment) AS total_recieved
FROM bank_loan_data
GROUP BY home_ownership
ORDER BY COUNT(id) DESC;