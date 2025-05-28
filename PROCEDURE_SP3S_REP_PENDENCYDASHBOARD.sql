CREATE PROCEDURE SP3S_REP_PENDENCYDASHBOARD
AS
BEGIN
	DECLARE @tRep TABLE (xn_desc VARCHAR(40),total_memos NUMERIC(10,0),total_qty NUMERIC(14,2),
						 total_overdue_memos NUMERIC(10,0),total_overdue_qty NUMERIC(14,2),
						 age_days1_memos NUMERIC(10,0),age_days2_memos NUMERIC(10,0),age_days3_memos NUMERIC(10,0),
						 age_days4_memos NUMERIC(10,0))

	DECLARE @tRepOD TABLE (xn_desc VARCHAR(40),memo_id VARCHAR(50),quantity NUMERIC(14,2),age_days NUMERIC(10,0),
						   age_category NUMERIC(1,0))
						 	
	INSERT @tRep (xn_desc,total_memos,total_qty,total_overdue_memos,total_overdue_qty)
	SELECT 'Purchase Orders' as xn_desc,count(*) as total_memos,SUM(quantity) as total_qty,
	0 as total_overdue_memos,0 as total_overdue_qty
	FROM PENDING_PO_SMRY
	UNION 
	SELECT 'Stock on Approval' as xn_desc,count(*) as total_memos,SUM(quantity) as total_qty,
	0 as total_overdue_memos,0 as total_overdue_qty
	FROM PENDING_APPROVALS_SMRY
	UNION ALL
	SELECT 'GIT' as xn_desc,count(*) as total_memos,SUM(quantity) as total_qty,
	0 as total_overdue_memos,0 as total_overdue_qty
	FROM PENDING_GIT_SMRY	
	UNION ALL
	SELECT 'Retail Pack Slips' as xn_desc,count(*) as total_memos,SUM(quantity) as total_qty,
	0 as total_overdue_memos,0 as total_overdue_qty
	FROM PENDING_RPS_SMRY
	UNION ALL
	SELECT 'Wholesale Pack Slips' as xn_desc,count(*) as total_memos,SUM(quantity) as total_qty,
	0 as total_overdue_memos,0 as total_overdue_qty
	FROM PENDING_WPS_SMRY
	UNION ALL
	SELECT 'Debit Note Pack Slips' as xn_desc,count(*) as total_memos,SUM(quantity) as total_qty,
	0 as total_overdue_memos,0 as total_overdue_qty
	FROM PENDING_DNPS_SMRY
	UNION ALL
	SELECT 'JobWork Issue' as xn_desc,count(*) as total_memos,SUM(quantity) as total_qty,
	0 as total_overdue_memos,0 as total_overdue_qty
	FROM PENDING_JOBWORK_TRADING_SMRY
	UNION ALL
	SELECT 'Wholesale Buyer Order' as xn_desc,count(*) as total_memos,SUM(quantity) as total_qty,
	0 as total_overdue_memos,0 as total_overdue_qty
	FROM PENDING_WBO_SMRY
	UNION ALL
	SELECT 'Retail Buyer Order' as xn_desc,count(*) as total_memos,SUM(quantity) as total_qty,
	0 as total_overdue_memos,0 as total_overdue_qty
	FROM PENDING_RBO_SMRY
	UNION ALL
	SELECT 'ASN' as xn_desc,count(*) as total_memos,SUM(quantity) as total_qty,
	0 as total_overdue_memos,0 as total_overdue_qty
	FROM PENDING_ASN_SMRY
	UNION ALL
	SELECT 'GRN' as xn_desc,count(*) as total_memos,SUM(quantity) as total_qty,
	0 as total_overdue_memos,0 as total_overdue_qty
	FROM PENDING_GRN_SMRY

	INSERT INTO @tRepOD (xn_desc,memo_id,age_days,quantity)
	SELECT 'Purchase Orders' as xn_desc,memo_id,(DATEDIFF(DD,memo_dt,getdate())-(CASE WHEN tat_days=0 THEN 7 
	ELSE tat_days END)) as age_days,quantity
	FROM PENDING_PO_SMRY
	WHERE DATEDIFF(DD,memo_dt,getdate())>(CASE WHEN tat_days=0 THEN 7 ELSE tat_days END)
	UNION ALL
	SELECT 'Stock on Approval' as xn_desc,memo_id,(DATEDIFF(DD,memo_dt,getdate())-(CASE WHEN tat_days=0 THEN 7 
	ELSE tat_days END)) as age_days,quantity
	FROM PENDING_APPROVALS_SMRY
	WHERE DATEDIFF(DD,memo_dt,getdate())>(CASE WHEN tat_days=0 THEN 7 ELSE tat_days END)
	UNION ALL
	SELECT 'GIT' as xn_desc,memo_id,(DATEDIFF(DD,memo_dt,getdate())-(CASE WHEN tat_days=0 THEN 7 
	ELSE tat_days END)) as age_days,quantity
	FROM PENDING_GIT_SMRY	
	WHERE DATEDIFF(DD,memo_dt,getdate())>(CASE WHEN tat_days=0 THEN 7 ELSE tat_days END)
	UNION ALL
	SELECT 'Retail Pack Slips' as xn_desc,memo_id,(DATEDIFF(DD,memo_dt,getdate())-(CASE WHEN tat_days=0 THEN 7 
	ELSE tat_days END)) as age_days,quantity
	FROM PENDING_RPS_SMRY
	WHERE DATEDIFF(DD,memo_dt,getdate())>(CASE WHEN tat_days=0 THEN 7 ELSE tat_days END)
	UNION ALL
	SELECT 'Wholesale Pack Slips' as xn_desc,memo_id,(DATEDIFF(DD,memo_dt,getdate())-(CASE WHEN tat_days=0 THEN 7 
	ELSE tat_days END)) as age_days,quantity
	FROM PENDING_WPS_SMRY
	WHERE DATEDIFF(DD,memo_dt,getdate())>(CASE WHEN tat_days=0 THEN 7 ELSE tat_days END)
	UNION ALL
	SELECT 'Debit Note Pack Slips' as xn_desc,memo_id,(DATEDIFF(DD,memo_dt,getdate())-(CASE WHEN tat_days=0 THEN 7 
	ELSE tat_days END)) as age_days,quantity
	FROM PENDING_DNPS_SMRY
	WHERE DATEDIFF(DD,memo_dt,getdate())>(CASE WHEN tat_days=0 THEN 7 ELSE tat_days END)
	UNION ALL
	SELECT 'JobWork Issue' as xn_desc,memo_id,(DATEDIFF(DD,memo_dt,getdate())-(CASE WHEN tat_days=0 THEN 7 
	ELSE tat_days END)) as age_days,quantity
	FROM PENDING_JOBWORK_TRADING_SMRY
	WHERE DATEDIFF(DD,memo_dt,getdate())>(CASE WHEN tat_days=0 THEN 7 ELSE tat_days END)
	UNION ALL
	SELECT 'Wholesale Buyer Order' as xn_desc,memo_id,(DATEDIFF(DD,memo_dt,getdate())-(CASE WHEN tat_days=0 THEN 7 
	ELSE tat_days END)) as age_days,quantity
	FROM PENDING_WBO_SMRY
	WHERE DATEDIFF(DD,memo_dt,getdate())>(CASE WHEN tat_days=0 THEN 7 ELSE tat_days END)
	UNION ALL
	SELECT 'Retail Buyer Order' as xn_desc,memo_id,(DATEDIFF(DD,memo_dt,getdate())-(CASE WHEN tat_days=0 THEN 7 
	ELSE tat_days END)) as age_days,quantity
	FROM PENDING_RBO_SMRY
	WHERE DATEDIFF(DD,memo_dt,getdate())>(CASE WHEN tat_days=0 THEN 7 ELSE tat_days END)
	UNION ALL
	SELECT 'ASN' as xn_desc,memo_id,(DATEDIFF(DD,memo_dt,getdate())-(CASE WHEN tat_days=0 THEN 7 
	ELSE tat_days END)) as age_days,quantity
	FROM PENDING_ASN_SMRY
	WHERE DATEDIFF(DD,memo_dt,getdate())>(CASE WHEN tat_days=0 THEN 7 ELSE tat_days END)
	UNION ALL
	SELECT 'GRN' as xn_desc,memo_id,(DATEDIFF(DD,memo_dt,getdate())-(CASE WHEN tat_days=0 THEN 7 
	ELSE tat_days END)) as age_days,quantity
	FROM PENDING_GRN_SMRY
	WHERE DATEDIFF(DD,memo_dt,getdate())>(CASE WHEN tat_days=0 THEN 7 ELSE tat_days END)

	DECLARE @nAge1 NUMERIC(5,0),@nAge2 NUMERIC(5,0),@nAge3 NUMERIC(5,0)

	SELECT @nAge1=value FROM config (NOLOCK) WHERE config_option='age_days1' 
	SELECT @nAge2=value FROM config (NOLOCK) WHERE config_option='age_days2' 
	SELECT @nAge3=value FROM config (NOLOCK) WHERE config_option='age_days3'

	SELECT @nAge1=(CASE WHEN ISNULL(@nAge1,0)=0 THEN 30 ELSE @nAge1 END),
		   @nAge2=(CASE WHEN ISNULL(@nAge2,0)=0 THEN 30 ELSE @nAge2 END),
		   @nAge3=(CASE WHEN ISNULL(@nAge3,0)=0 THEN 30 ELSE @nAge3 END)
	
	UPDATE @tRepOD SET age_category=(CASE WHEN age_days<@nAge1 THEN 1 
										  WHEN age_days BETWEEN @nAge1 AND @nAge2 THEN 2
										  WHEN age_days BETWEEN @nAge2+1 AND @nAge3 THEN 3 ELSE 4 END)

	UPDATE a SET total_overdue_memos=b.total_overdue_memos,total_overdue_qty=b.total_overdue_qty,
	age_days1_memos=b.age_days1_memos,age_days2_memos=b.age_days2_memos,age_days3_memos=b.age_days3_memos,
	age_days4_memos=b.age_days4_memos
	FROM @tRep a JOIN (SELECT xn_desc,sum(quantity) as total_overdue_qty,COUNT(*) AS total_overdue_memos,
					   SUM(CASE WHEN age_category=1 THEN 1 ELSE 0 END) AS age_days1_memos,
					   SUM(CASE WHEN age_category=2 THEN 1 ELSE 0 END) AS age_days2_memos,	
					   SUM(CASE WHEN age_category=3 THEN 1 ELSE 0 END) AS age_days3_memos,	
					   SUM(CASE WHEN age_category=4 THEN 1 ELSE 0 END) AS age_days4_memos
					   FROM @tRepOD GROUP BY xn_desc) b ON a.xn_desc=b.xn_desc
	
	SELECT * FROM @tREp WHERE total_qty IS NOT NULL
	
	SELECT * FROM @tRepOD
END