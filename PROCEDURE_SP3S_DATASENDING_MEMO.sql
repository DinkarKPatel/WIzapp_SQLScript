CREATE PROC SP3S_DATASENDING_MEMO--(LocId 3 digit change by Sanjay:05-11-2024)
AS   
BEGIN  
		DECLARE @DCUTOFFDATE DATETIME,@cdept_id varchar(4),@cHoDeptId VARCHAR(4)

		SELECT @cdept_id=value  FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID'
		SELECT @cHoDeptId=value FROM config (NOLOCK) WHERE config_option='ho_location_id'

		Delete From xntype_merging_errors where ABS(datediff(minute,last_update,getdate()))>5
		
		
		
		SET @DCUTOFFDATE= CONVERT(date,getdate()-2)

		DECLARE @TBLXNDETAILS TABLE (XN_TYPE VARCHAR(30),location_code VARCHAR(4),XN_ID VARCHAR(50),TABLENAME VARCHAR(100),
		LASTUPDATE DATETIME,SEND_ORDER numeric(5,0) ,COLUMNNAME VARCHAR(50))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'PO' AS XN_TYPE,location_code,PO_ID AS XN_ID,'POM01106' AS TABLENAME,LAST_UPDATE   , 20 AS SEND_ORDER,'PO_ID' AS COLUMNNAME  FROM POM01106 (NOLOCK) 
		WHERE ((PO_DT>=@DCUTOFFDATE AND HO_SYNCH_LAST_UPDATE is null) or (HO_SYNCH_LAST_UPDATE<>LAST_UPDATE and HO_SYNCH_LAST_UPDATE is not null ))

		--INSERT INTO @TBLXNDETAILS(XN_TYPE,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		--SELECT 'OPS' AS XN_TYPE,DEPT_ID AS XN_ID,'OPS01106' AS TABLENAME,LAST_UPDATE   , 20 AS SEND_ORDER ,'DEPT_ID' AS COLUMNNAME FROM OPS01106 (NOLOCK) WHERE XN_DT>=@DCUTOFFDATE AND HO_SYNCH_LAST_UPDATE<>LAST_UPDATE

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'PUR' AS XN_TYPE,A.location_code,MRR_ID AS XN_ID,'PIM01106' AS TABLENAME,a.LAST_UPDATE ,40 AS  SEND_ORDER ,'MRR_ID' AS COLUMNNAME FROM PIM01106 a (NOLOCK)  
		JOIN location b (NOLOCK) ON b.dept_id=a.dept_id
		WHERE ((a.RECEIPT_DT>=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))
		AND  (a.inv_mode<>1 OR isnull(B.allow_purchase_at_ho,0)<>1 or SUBSTRING(mrr_no,4,2)<>@cHoDeptId OR ISNULL(ALLOW_EDIT_AT,0)=2)

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)  
		SELECT 'SNC' AS XN_TYPE,A.location_code,MEMO_ID AS XN_ID,'SNC_MST' AS TABLENAME,LAST_UPDATE ,45 AS  SEND_ORDER,'MEMO_ID' AS COLUMNNAME  
		FROM SNC_MST A (NOLOCK)  
		WHERE ((a.RECEIPT_DT>=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'SCF'AS XN_TYPE,A.location_code,MEMO_ID AS XN_ID,'SCM01106' AS TABLENAME,LAST_UPDATE ,60 AS  SEND_ORDER,'MEMO_ID' AS COLUMNNAME   
		FROM SCM01106 A (NOLOCK)  
		WHERE ((a.memo_dt>=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'IRR'AS XN_TYPE,A.location_code,irm_memo_id AS XN_ID,'IRM01106' AS TABLENAME,LAST_UPDATE ,70 AS  SEND_ORDER,
		'irm_memo_id' AS COLUMNNAME   FROM IRM01106 A (NOLOCK) 
		 WHERE ((a.IRM_memo_dt>=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME) 
		SELECT 'APP'AS XN_TYPE,A.location_code,MEMO_ID AS XN_ID,'APM01106' AS TABLENAME,LAST_UPDATE ,80 AS  SEND_ORDER,'MEMO_ID' AS COLUMNNAME   
		FROM APM01106 A (NOLOCK)  
		WHERE ((a.memo_dt>=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'APR'AS XN_TYPE,A.location_code,MEMO_ID AS XN_ID,'APPROVAL_RETURN_MST' AS TABLENAME,LAST_UPDATE ,90 AS  SEND_ORDER ,'MEMO_ID' AS COLUMNNAME 
		FROM APPROVAL_RETURN_MST A (NOLOCK)  
		WHERE ((a.memo_dt>=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'SHF'AS XN_TYPE,A.location_code,shift_id AS XN_ID,'TILL_SHIFT_MST' AS TABLENAME,LAST_UPDATE ,95 AS  SEND_ORDER,'shift_id' AS COLUMNNAME 
		FROM TILL_SHIFT_MST A (NOLOCK)  
		WHERE ((a.open_date >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'RPS'AS XN_TYPE,A.location_code,CM_ID AS XN_ID,'RPS_MST' AS TABLENAME,LAST_UPDATE ,110 AS  SEND_ORDER ,'CM_ID' AS COLUMNNAME   
		FROM RPS_MST A (NOLOCK)  
		WHERE ((a.CM_DT >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)  
		SELECT 'WPS'AS XN_TYPE,A.location_code,PS_ID AS XN_ID,'WPS_MST' AS TABLENAME,LAST_UPDATE ,112 AS  SEND_ORDER ,'PS_ID' AS COLUMNNAME  
		FROM WPS_MST A (NOLOCK) 
		WHERE ((a.PS_DT >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'WSL'AS XN_TYPE,A.location_code,INV_ID AS XN_ID,'INM01106' AS TABLENAME,LAST_UPDATE ,115 AS  SEND_ORDER,'INV_ID' AS COLUMNNAME   
		FROM INM01106 A (NOLOCK)  
		WHERE ((a.INV_DT >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'XNSDTM'AS XN_TYPE,A.location_code,DT_CODE  AS XN_ID,'DTM' AS TABLENAME,LAST_UPDATE ,117 AS  SEND_ORDER ,'DT_CODE' AS COLUMNNAME  
		FROM DTM A (NOLOCK)  
		WHERE ((a.LAST_UPDATE>=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'SLS'AS XN_TYPE,A.location_code,CM_ID AS XN_ID,'CMM01106' AS TABLENAME,LAST_UPDATE ,120 AS  SEND_ORDER ,'CM_ID' AS COLUMNNAME  
		FROM CMM01106 A (NOLOCK)  
		WHERE ((a.cm_dt >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'ARC'AS XN_TYPE,A.location_code,ADV_REC_ID AS XN_ID,'ARC01106' AS TABLENAME,LAST_UPDATE ,125 AS  SEND_ORDER,'ADV_REC_ID' AS COLUMNNAME   
		FROM ARC01106 A (NOLOCK) 
		WHERE ((a.adv_rec_dt  >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'TLF'AS XN_TYPE,A.location_code,memo_id AS XN_ID,'TILL_LIFTS' AS TABLENAME,LAST_UPDATE ,127 AS  SEND_ORDER,'MEMO_ID' AS COLUMNNAME    
		FROM TILL_LIFTS a (NOLOCK)  
		WHERE ((a.memo_dt  >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'TEX'AS XN_TYPE,A.location_code,memo_id AS XN_ID,'TILL_EXPENSE_MST' AS TABLENAME,LAST_UPDATE ,130 AS  SEND_ORDER,'MEMO_ID' AS COLUMNNAME   
		FROM TILL_EXPENSE_MST A (NOLOCK) 
		WHERE ((a.memo_dt  >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'BKT'AS XN_TYPE,A.location_code,memo_id AS XN_ID,'TILL_BANK_TRANSFER' AS TABLENAME,LAST_UPDATE ,132 AS  SEND_ORDER ,'MEMO_ID' AS COLUMNNAME   
		FROM TILL_BANK_TRANSFER A (NOLOCK) 
		WHERE ((a.memo_dt  >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'PTC'AS XN_TYPE,A.location_code,pem_memo_id AS XN_ID,'PEM01106' AS TABLENAME,LAST_UPDATE ,135 AS  SEND_ORDER ,'pem_memo_id' AS COLUMNNAME  
		FROM PEM01106 A (NOLOCK)  
		WHERE ((a.pem_memo_dt   >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		--INSERT INTO @TBLXNDETAILS(XN_TYPE,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		--SELECT 'PTCAPP'AS XN_TYPE,ROW_ID AS XN_ID,'PED01106' AS TABLENAME,LAST_UPDATE ,138 AS  SEND_ORDER,'ROW_ID' AS COLUMNNAME    FROM PED01106 (NOLOCK)  WHERE  HO_SYNCH_LAST_UPDATE<>LAST_UPDATE AND approvedlevelno=99 --pending

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'WSLORD'AS XN_TYPE,A.location_code,ORDER_ID  AS XN_ID,'WSL_ORDER_MST' AS TABLENAME,LAST_UPDATE ,150 AS  SEND_ORDER,'ORDER_ID' AS COLUMNNAME   
		FROM WSL_ORDER_MST A (NOLOCK)  
		WHERE ((a.order_dt  >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'WBO',A.location_code,ORDER_ID  AS XN_ID,'BUYER_ORDER_MST' AS TABLENAME,LAST_UPDATE ,110 AS  SEND_ORDER,
		'ORDER_ID' AS COLUMNNAME    
		FROM BUYER_ORDER_MST A (NOLOCK)  
		WHERE ((a.order_dt  >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))
		AND ISNULL(SUBMIT_TO_HO,0)=1 

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME) 
		SELECT 'DNPS',A.location_code,PS_ID  AS XN_ID,'DNPS_MST' AS TABLENAME,LAST_UPDATE ,180 AS  SEND_ORDER,'PS_ID' AS COLUMNNAME   
		FROM DNPS_MST a (NOLOCK) 
		WHERE ((a.ps_dt  >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'PRT'AS XN_TYPE,A.location_code,RM_ID  AS XN_ID,'RMM01106' AS TABLENAME,LAST_UPDATE ,185 AS  SEND_ORDER,'RM_ID' AS COLUMNNAME   
		FROM RMM01106 A (NOLOCK)  
		WHERE ((a.rm_dt  >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'WSR'AS XN_TYPE,A.location_code,CN_ID  AS XN_ID,'CNM01106' AS TABLENAME,LAST_UPDATE ,190 AS  SEND_ORDER,'CN_ID' AS COLUMNNAME   
		FROM CNM01106 A (NOLOCK)  
		WHERE ((a.receipt_dt   >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'BCO'AS XN_TYPE,A.location_code,MEMO_ID  AS XN_ID,'FLOOR_ST_MST' AS TABLENAME,LAST_UPDATE ,195 AS  SEND_ORDER,'MEMO_ID' AS COLUMNNAME   
		FROM FLOOR_ST_MST A (NOLOCK)  
		WHERE ((a.memo_dt  >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'JWI'AS XN_TYPE,A.location_code,ISSUE_ID   AS XN_ID,'JOBWORK_ISSUE_MST' AS TABLENAME,LAST_UPDATE ,200 AS  SEND_ORDER ,'ISSUE_ID' AS COLUMNNAME 
		FROM JOBWORK_ISSUE_MST A (NOLOCK)  
		WHERE ((a.issue_dt   >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'JWR'AS XN_TYPE,A.location_code,receipt_id   AS XN_ID,'JOBWORK_RECEIPT_MST' AS TABLENAME,LAST_UPDATE ,210 AS  SEND_ORDER,'receipt_id' AS COLUMNNAME 
		FROM JOBWORK_RECEIPT_MST a (NOLOCK)  
		WHERE ((a.receipt_dt  >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'ATD'AS XN_TYPE,A.location_code,ROW_ID   AS XN_ID,'EMP_WPAYATT' AS TABLENAME,LAST_UPDATE ,230 AS  SEND_ORDER,'ROW_ID' AS COLUMNNAME   
		FROM EMP_WPAYATT A (NOLOCK) 
		WHERE ((a.ist_time  >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'CNC'AS XN_TYPE,A.location_code,cnc_memo_ID   AS XN_ID,'ICM01106' AS TABLENAME,LAST_UPDATE ,240 AS  SEND_ORDER ,'cnc_memo_ID' AS COLUMNNAME   
		FROM ICM01106 A (NOLOCK)  
		WHERE ((a.cnc_memo_dt  >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null )) 

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'POADJ'AS XN_TYPE,A.location_code,memo_ID   AS XN_ID,'PO_ADJ_MST' AS TABLENAME,LAST_UPDATE ,250 AS  SEND_ORDER ,'MEMO_ID' AS COLUMNNAME   
		FROM PO_ADJ_MST A (NOLOCK) 
		WHERE ((a.memo_DT   >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)--NO SAVETRAN
		SELECT 'DEND'AS XN_TYPE,A.Dept_id,CONVERT(VARCHAR(10),Log_Date,121)  AS XN_ID,'DAYCLOSE_LOG' AS TABLENAME,LAST_UPDATE ,260 AS  SEND_ORDER,'Log_Date' AS COLUMNNAME     
		FROM DAYCLOSE_LOG A (NOLOCK)  
		WHERE ((a.Log_Date    >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'PSHBD'AS XN_TYPE,A.location_code,memo_id  AS XN_ID,'HOLD_BACK_DELIVER_MST' AS TABLENAME,LAST_UPDATE ,310 AS  SEND_ORDER ,'MEMO_ID' AS COLUMNNAME   
		FROM HOLD_BACK_DELIVER_MST A (NOLOCK) 
		WHERE ((a.memo_DT   >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'PSJWI'AS XN_TYPE,A.location_code,issue_id  AS XN_ID,'POST_SALES_JOBWORK_ISSUE_MST' AS TABLENAME,LAST_UPDATE ,320 AS  SEND_ORDER,'issue_id' AS COLUMNNAME  
		FROM POST_SALES_JOBWORK_ISSUE_MST a (NOLOCK) 
		WHERE ((a.issue_dt   >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'PSJWR'AS XN_TYPE,A.location_code,RECEIPT_ID   AS XN_ID,'POST_SALES_JOBWORK_RECEIPT_MST' AS TABLENAME,LAST_UPDATE ,330 AS  SEND_ORDER,'RECEIPT_ID' AS COLUMNNAME
		FROM POST_SALES_JOBWORK_RECEIPT_MST a (NOLOCK)  
		WHERE ((a.receipt_dt   >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'PSDLV'AS XN_TYPE,A.location_code,MEMO_ID   AS XN_ID,'SLS_DELIVERY_MST' AS TABLENAME,LAST_UPDATE ,340 AS  SEND_ORDER ,'MEMO_ID' AS COLUMNNAME  
		FROM SLS_DELIVERY_MST A (NOLOCK)  
		WHERE ((a.memo_DT   >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)  
		SELECT 'STREC' AS XN_TYPE,A.location_code,Memo_Id    AS XN_ID,'STMH01106' AS TABLENAME,LAST_UPDATE ,380 AS  SEND_ORDER,'memo_id' AS COLUMNNAME
		FROM STMH01106 A (NOLOCK)  
		WHERE ((a.stm_start_dt   >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'PCI' AS XN_TYPE,A.location_code,MEMO_ID    AS XN_ID,'PCI_MST' AS TABLENAME,LAST_UPDATE ,500 AS  SEND_ORDER,'MEMO_ID' AS COLUMNNAME   
		FROM PCI_MST A (NOLOCK)  
		WHERE ((a.memo_DT   >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))
		and SUBSTRING(memo_no,3,2)=@cdept_id
		
		

		INSERT INTO @TBLXNDETAILS(XN_TYPE,A.location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'PCO' AS XN_TYPE,A.location_code,MEMO_ID    AS XN_ID,'PCO_MST' AS TABLENAME,LAST_UPDATE ,500 AS  SEND_ORDER ,'MEMO_ID' AS COLUMNNAME  
		FROM PCO_MST A (NOLOCK)  
		WHERE ((a.memo_DT   >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'PRCL' AS XN_TYPE,A.location_code,parcel_memo_id    AS XN_ID,'PARCEL_MST' AS TABLENAME,a.LAST_UPDATE ,120 AS  SEND_ORDER ,
		'parcel_memo_id' AS COLUMNNAME    FROM PARCEL_MST a (NOLOCK)
		LEFT JOIN rmm01106 b (NOLOCK) ON a.parcel_memo_id=b.docprt_parcel_memo_id AND b.cancelled=0 AND b.mode=2
		LEFT JOIN inm01106 c (NOLOCK) ON a.parcel_memo_id=c.docwsl_parcel_memo_id AND c.cancelled=0 AND c.inv_mode=2
		WHERE  b.rm_id IS NULL AND c.inv_id IS NULL
		and ((a.parcel_memo_dt   >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		--INSERT INTO @TBLXNDETAILS(XN_TYPE,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		--SELECT 'CUS' AS XN_TYPE,CUSTOMER_CODE  AS XN_ID,'CUSTDYM' AS TABLENAME,LAST_UPDATE ,570 AS  SEND_ORDER ,'CUSTOMER_CODE' AS COLUMNNAME     FROM CUSTDYM (NOLOCK)  WHERE  HO_SYNCH_LAST_UPDATE<>LAST_UPDATE

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'PFI' AS XN_TYPE,A.location_code,MEMO_ID  AS XN_ID,'ORD_PLAN_MST' AS TABLENAME,LAST_UPDATE ,590 AS  SEND_ORDER ,'MEMO_ID' AS COLUMNNAME   
		FROM ORD_PLAN_MST A (NOLOCK)  
		WHERE ((a.memo_DT   >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'MIS' AS XN_TYPE,A.location_code,ISSUE_ID  AS XN_ID,'BOM_ISSUE_MST' AS TABLENAME,LAST_UPDATE ,600 AS  SEND_ORDER ,'ISSUE_ID' AS COLUMNNAME    
		FROM BOM_ISSUE_MST A (NOLOCK)  
		WHERE ((a.issue_dt   >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'TTM' AS XN_TYPE,A.location_code,MEMO_ID   AS XN_ID,'TRANSFER_TO_TRADING_MST' AS TABLENAME,LAST_UPDATE ,610 AS  SEND_ORDER,'MEMO_ID' AS COLUMNNAME 
		FROM TRANSFER_TO_TRADING_MST A (NOLOCK)  
		WHERE ((a.memo_DT   >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null )) 

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'SLRRECON' AS XN_TYPE,A.location_code,MEMO_ID   AS XN_ID,'SLR_RECON_MST' AS TABLENAME,LAST_UPDATE ,620 AS  SEND_ORDER ,'MEMO_ID' AS COLUMNNAME   
		FROM SLR_RECON_MST a (NOLOCK)  
		WHERE ((a.memo_DT   >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'GRNPS'AS XN_TYPE,A.location_code,MEMO_ID   AS XN_ID,'GRN_PS_MST' AS TABLENAME,LAST_UPDATE ,
		640 AS  SEND_ORDER ,'MEMO_ID' AS COLUMNNAME  
		FROM GRN_PS_MST A (NOLOCK)  
		WHERE ((a.memo_DT   >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'STKCNT' AS XN_TYPE,A.location_code,MEMO_ID   AS XN_ID,'MANUAL_STOCK_COUNT_XN_mst' AS TABLENAME,
		LAST_UPDATE ,645 AS  SEND_ORDER,'MEMO_ID' AS COLUMNNAME    
		FROM MANUAL_STOCK_COUNT_XN_mst A (NOLOCK)  
		WHERE ((a.memo_DT   >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))

		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'gvxfr' AS XN_TYPE,A.location_code,MEMO_ID   AS XN_ID,'GV_STKXFER_MST' AS TABLENAME,
		LAST_UPDATE ,650 AS  SEND_ORDER,'MEMO_ID' AS COLUMNNAME    
		FROM GV_STKXFER_MST A (NOLOCK)  
		WHERE ((a.memo_DT   >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))
		and  (target_dept_id =@cHoDeptId OR receipt_dt<>'')

		 
		INSERT INTO @TBLXNDETAILS(XN_TYPE,location_code,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'XNRECON' AS XN_TYPE,A.location_code,recon_id   AS XN_ID,'XNRECON_HIST_MST' AS TABLENAME,
		LAST_UPDATE ,650 AS  SEND_ORDER,'Recon_ID' AS COLUMNNAME    
		FROM XNRECON_HIST_MST A (NOLOCK)  
		WHERE ((a.recon_dt   >=@DCUTOFFDATE AND a.HO_SYNCH_LAST_UPDATE is null) or (a.HO_SYNCH_LAST_UPDATE<>a.LAST_UPDATE and a.HO_SYNCH_LAST_UPDATE is not null ))
		 and a.location_code=@cdept_id 



		SELECT A.XN_TYPE,XN_ID,TABLENAME,convert(varchar,LASTUPDATE,121) as lastupdate,SEND_ORDER,COLUMNNAME 
		FROM @TBLXNDETAILS A
		LEFT JOIN xntype_merging_errors B ON A.XN_TYPE=B.XN_TYPE 
		WHERE isnull(B.XN_TYPE,'') = '' and (location_code=@cdept_id OR A.XN_TYPE IN('PUR','PCI','gvxfr'))
		AND DATEDIFF (SS,LASTUPDATE,GETDATE())>15
		ORDER BY SEND_ORDER,a.xn_id

END  


