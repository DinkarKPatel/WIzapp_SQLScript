
create PROCEDURE SP3S_GENLOCDATA          
(          
 @CLOCID VARCHAR(5),
 @CDBPath varchar(1000)=''

)          
AS          
BEGIN          
      
	  set nocount on
    DECLARE @NSTEP VARCHAR(10),@CCMD NVARCHAR(MAX),@CERRORMSG VARCHAR(200),          
            @DBNAME VARCHAR(100),@SR INT,@CDB_PATH VARCHAR(100),          
            @CTABLENAME VARCHAR(100),@CKEYFIELD VARCHAR(100),@CWHERECLAUSE VARCHAR(100),          
            @CLOCDB VARCHAR(100),@JOINSTR VARCHAR(MAX) ,@CCUTOFCOLUMN VARCHAR(100)  ,
            @CCURDEPT_ID varchar(5),@CHODEPT_ID VARCHAR(5),@NSLSMEMOLEN NUMERIC(2,0)  ,
			@CIMAGEDBNAME varchar(1000),@CNEWDBNAME varchar(100),@CDBPATHOUT VARCHAR(1000),
			@CBACKUPDB VARCHAR(1000)
                   
    SET @SR=0          
                     
    SET @NSTEP=10  
	
	         
         SELECT TOP 1 @CCURDEPT_ID= VALUE  FROM CONFIG WHERE CONFIG_OPTION ='LOCATION_ID'   
         SELECT TOP 1 @CHODEPT_ID=VALUE  FROM CONFIG WHERE CONFIG_OPTION ='HO_LOCATION_ID' 

		 if object_id ('tempdb..#tmpdbname','u' ) is not null
		   drop table #tmpdbname

		SELECT cast('' as varchar(1000)) AS DBName,
			   cast('' as varchar(1000)) AS FileLocation
		into #tmpdbname where 1=2


	IF OBJECT_ID ('TEMPDB..#TMPCURDBNAME','U' ) IS NOT NULL
		DROP TABLE #TMPCURDBNAME

	SELECT CAST('' AS VARCHAR(1000)) NEWDBNAME,CAST('' AS VARCHAR(1000)) ERRMSG,
	       CAST('' AS VARCHAR(1000)) AS DBPATH
	   INTO #TMPCURDBNAME
	WHERE 1=2

	    EXEC SP_NEWLOCDB @CLOCID=@CLOCID,@BCALLEDFROMAPI=1,@CDB_PATH=@CDBPath

		IF EXISTS (SELECT TOP 1 'U' FROM #TMPCURDBNAME WHERE ISNULL(ERRMSG,'')<>'')
		BEGIN
		  
			 SELECT TOP 1 @CERRORMSG=ERRMSG FROM #TMPCURDBNAME WHERE ISNULL(ERRMSG,'')<>''
			 GOTO END_PROC
		END
	
		SELECT TOP 1 @CNEWDBNAME=NEWDBNAME,@CDBPATHOUT=DBPATH FROM #TMPCURDBNAME

		IF ISNULL(@CNEWDBNAME,'')=''
		BEGIN
		    SET @CERRORMSG=' ERROR IN CREATING NEW DATABASE'
			 GOTO END_PROC

		END


         
        
    BEGIN TRAN          
    BEGIN TRY          
      

	  --IF EXISTS (SELECT TOP 1 'U'  FROM MASTER .INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='CLOUD_DBINFO')
	  --BEGIN
	       
		 --  IF CONVERT(varchar, GETDATE (), 108) BETWEEN '16:00:00' AND '21:00:00'
		 --  BEGIN
		 --       SET @CERRORMSG=' Reconstruct not allowed between 4 pm to 9 pm '
		 --  END
		

	  --END
	 
     


    SET @DBNAME=DB_NAME ()          
    SET @CLOCDB=@CNEWDBNAME+'.DBO.'          
    IF OBJECT_ID ('TEMPDB..#TABELIST','U') IS NOT NULL          
       DROP TABLE #TABELIST          
    SELECT TABLENAME=CAST('' AS  VARCHAR(100)),KEYFIELD=CAST('' AS  VARCHAR(100)),CUTOFFDATE=CAST('' AS VARCHAR(100)),    
    JOINSTR=CAST('' AS VARCHAR(MAX))    
    INTO #TABELIST          
    WHERE 1=2          
    SET @NSTEP=30          
    --INSERTION ALL TRANSACTION TABLES          
     INSERT INTO #TABELIST (TABLENAME,KEYFIELD,CUTOFFDATE,JOINSTR)          
     SELECT 'ARC01106','ADV_REC_ID','ADV_REC_DT',''          
        UNION            
     SELECT 'HBD_RECEIPT','ADV_REC_ID','',''          
        UNION        
     SELECT 'APM01106','MEMO_ID','MEMO_DT',''     
        UNION    
     SELECT 'APD01106','MEMO_ID','A.MEMO_DT',''         
        UNION      
     SELECT 'DAYCLOSE_LOG','DEPT_ID','Log_Date',''          
        UNION              
     SELECT 'APPROVAL_RETURN_MST','MEMO_ID' ,'MEMO_DT',''        
        UNION     
     SELECT 'APPROVAL_RETURN_DET','MEMO_ID',' MEMO_DT',''             
        UNION               
     SELECT 'CMM01106','CM_ID','CM_DT',''          
        UNION          
     SELECT 'CMD01106','CM_ID','A.CM_DT',''  
	   UNION          
     SELECT 'cmd_cons','CM_ID','A.CM_DT',''  
        UNION          
     SELECT 'CNM01106','CN_ID','RECEIPT_DT' ,''        
        UNION          
     SELECT 'CND01106','CN_ID' ,'A.RECEIPT_DT',''       
        UNION             
     SELECT 'DNPS_MST','PS_ID','PS_DT',''         
        UNION          
     SELECT 'DNPS_DET','PS_ID','A.PS_DT',''         
		UNION           
     SELECT 'FIXITEM_RATE_REVISION_MST','b.DEPT_ID' ,'MEMO_DT',' join ( SELECT a.DEPT_ID ,b.MEMO_ID FROM FIXITEM_RATE_REVISION_DET B JOIN FIXITEM_RATE_REVISION_LOC_DET A ON A.REF_ROW_ID=B.ROW_ID GROUP BY a.DEPT_ID ,b.MEMO_ID ) a on a.memo_id =b.memo_id '         
		UNION          
     SELECT 'FIXITEM_RATE_REVISION_DET','a.DEPT_ID','A.MEMO_DT',' JOIN FIXITEM_RATE_REVISION_LOC_DET A ON A.REF_ROW_ID=B.ROW_ID '          
		UNION          
     SELECT 'FIXITEM_RATE_REVISION_LOC_DET','b.DEPT_ID','C.MEMO_DT',''           
		UNION          
     SELECT 'FLOOR_ST_MST','MEMO_ID','MEMO_DT',''          
		UNION          
     SELECT 'FLOOR_ST_DET','MEMO_ID' ,'A.MEMO_DT',''        
		UNION          
     SELECT 'HOLD_BACK_DELIVER_MST','MEMO_ID','memo_dt',''          
		UNION          
     SELECT 'HOLD_BACK_DELIVER_DET','MEMO_ID' ,'A.memo_dt',''        
		UNION          
     SELECT 'ICM01106','CNC_MEMO_ID','CNC_MEMO_DT',''         
		UNION          
     SELECT 'ICD01106','CNC_MEMO_ID','A.CNC_MEMO_DT',''          
		UNION          
     SELECT 'INM01106','INV_ID','INV_DT',''          
		UNION          
     SELECT 'IND01106','INV_ID','a.INV_DT',''          
		UNION          
     SELECT 'IRM01106','IRM_MEMO_ID','IRM_MEMO_DT',''          
		UNION          
     SELECT 'IRD01106','a.IRM_MEMO_ID', 'A.IRM_MEMO_DT','JOIN IRM01106 A ON A.IRM_MEMO_ID=B.IRM_MEMO_ID'         
		UNION           
     SELECT 'JOBWORK_ISSUE_MST','ISSUE_ID' ,'ISSUE_DT',''        
		UNION          
     SELECT 'JOBWORK_ISSUE_DET','ISSUE_ID' ,'A.ISSUE_DT', ''        
		UNION           
     SELECT 'JOBWORK_RECEIPT_MST','RECEIPT_ID','receipt_dt',''        
		UNION          
     SELECT 'JOBWORK_RECEIPT_DET','RECEIPT_ID','A.RECEIPT_DT',''          
  UNION           
    SELECT 'PEM01106','PEM_MEMO_ID','pem_memo_dt',''          
  UNION          
     SELECT 'PED01106','PEM_MEMO_ID','PEM_MEMO_DT',''         
  UNION        
  SELECT 'PIM01106','DEPT_ID','RECEIPT_DT',''          
  --UNION          
  --   SELECT 'PID01106','MRR_ID','RECEIPT_DT','JOIN PIM01106 A ON A.MRR_ID=B.MRR_ID'          
  UNION           
      SELECT 'PO_ADJ_MST','MEMO_ID','memo_DT',''          
  UNION          
     SELECT 'PO_ADJ_DET','MEMO_ID','A.memo_DT',''         
  UNION          
     SELECT 'POM01106','b.DEPT_ID','PO_DT',''         
  UNION          
     SELECT 'POD01106','a.DEPT_ID','A.PO_DT',' JOIN POM01106 A ON A.PO_ID=B.PO_ID '          
  UNION          
     SELECT 'PRD_AGENCY_MATERIAL_RECEIPT_MST','MEMO_ID','MEMO_DT',''         
  UNION           
     SELECT 'PRD_AGENCY_MATERIAL_RECEIPT_DET','MEMO_ID','A.MEMO_DT',''          
  UNION           
     SELECT 'PRD_DEPARTMENT_OUTPUT_MST','MEMO_ID','MEMO_DT',''          
  UNION          
     SELECT 'PRD_DEPARTMENT_OUTPUT_DET','MEMO_ID','A.MEMO_DT',''          
  UNION           
     SELECT 'PRD_ISSUE_MATERIAL_MST','MEMO_ID','MEMO_DT',''         
  UNION          
     SELECT 'PRD_ISSUE_MATERIAL_DET','MEMO_ID','A.MEMO_DT',''                
  UNION           
     SELECT 'PRD_MATERIAL_RECEIPT_MST','MEMO_ID','MEMO_DT',''          
  UNION          
     SELECT 'PRD_MATERIAL_RECEIPT_DET','MEMO_ID','A.MEMO_DT',''         
  UNION           
     SELECT 'RMM01106','RM_ID','RM_DT',''           
  UNION          
     SELECT 'RMD01106','a.RM_ID','A.RM_DT',' JOIN RMM01106 A ON A.RM_ID=B.RM_ID '           
  UNION           
     SELECT 'SLS_DELIVERY_MST','MEMO_ID','MEMO_DT',''           
  UNION           
     SELECT 'SLS_DELIVERY_DET','MEMO_ID','A.MEMO_DT',''           
  UNION          
       SELECT 'sls_delivery_cons','MEMO_ID','A.MEMO_DT',''           
  UNION     
     SELECT 'SNC_MST','MEMO_ID','RECEIPT_DT',''           
  UNION          
     SELECT 'SNC_DET','MEMO_ID','A.RECEIPT_DT',''                     
  UNION           
     SELECT 'SNC_CONSUMABLE_DET','a.MEMO_ID','RECEIPT_DT',' JOIN SNC_DET A ON A.ROW_ID=B.REF_ROW_ID JOIN SNC_MST C ON C.MEMO_ID=B.MEMO_ID'                   
  UNION          
     SELECT 'SCC01106','MEMO_ID','memo_dt',''           
  UNION           
     SELECT 'SCF01106','MEMO_ID','memo_dt',''           
  UNION           
     SELECT 'SCM01106','MEMO_ID','memo_dt',''           
  UNION    
     SELECT 'WPS_MST','PS_ID','ps_dt',''               
  UNION           
     SELECT 'WEBSUPPORT_TKTM','TICKET_ID','ticket_dt',''           
  UNION          
     SELECT 'WEBSUPPORT_TKTD','TICKET_ID','A.ticket_dt',''           
  UNION              
    SELECT 'WPS_DET','PS_ID','A.ps_dt',''           
  UNION          
     SELECT 'WSL_ORDER_MST','ORDER_ID','order_dt',''           
  UNION          
     SELECT 'WSL_ORDER_DET','ORDER_ID','A.order_dt',''           
  UNION          
     SELECT 'WSL_ORDER_ADV_RECEIPT','ORDER_ID' ,'order_dt',''          
  UNION          
     SELECT 'RPS_MST','CM_ID','CM_DT',''           
  UNION          
     SELECT 'RPS_DET','CM_ID','A.CM_DT',''  
  UNION          
     SELECT 'CMR01106','CM_ID', ' CM_DT',''               
  UNION          
     SELECT 'CMM_CREDIT_RECEIPT','CM_ID' ,' CM_DT',''          
  UNION          
     SELECT 'BWD_MST','MEMO_ID','MEMO_DT',''           
  UNION          
     SELECT 'BWD_DET','MEMO_ID','A.memo_dt',''           
  UNION          
     SELECT 'PCO_MST','MEMO_ID',' memo_dt','' 
  UNION          
     SELECT 'PCI_MST','memo_no',' memo_dt','' 
  UNION          
     SELECT 'memo_no','MEMO_ID',' memo_dt',''           
  UNION          
     SELECT 'COUPON_REDEMPTION_INFO','CM_ID',' CM_DT ',''              
  UNION          
     SELECT 'CON_ST_MST','MEMO_ID',' MEMO_DT',''           
  UNION          
     SELECT 'ADV_REP_FILTER','DEPT_ID','',''           
  UNION          
     SELECT 'ARC_GVSALE_DETAILS','ADV_REC_ID','adv_rec_dt',''           
  UNION     
     SELECT 'BUYER_ORDER_MST','wbo_for_dept_id' ,'order_dt',''          
  UNION          
     SELECT 'BUYER_ORDER_DET','wbo_for_dept_id','A.order_dt',' JOIN BUYER_ORDER_MST A ON A.ORDER_ID=B.ORDER_ID '           
  UNION          
     SELECT 'CARDISSUE','ADV_REC_ID','',''           
  UNION     
     SELECT 'CHQBOOK_M','CHQ_BOOK_ID' ,'receive_dt',''          
  UNION           
     SELECT 'CHQBOOK_D','CHQ_BOOK_ID' ,'A.receive_dt',''          
  UNION          
     SELECT 'CMD_SCHEME_DET','CMD_ROW_ID' ,'',''          
     UNION          
     SELECT 'CREDITBILLS','CM_ID','CM_DT ',''           
  UNION          
     SELECT 'CREDITBILLS','CM_ID','CM_DT',''     
  UNION          
   SELECT 'DAYENDLOG','DEPT_ID','',''           
  UNION    
     SELECT 'DEBIT_NOTE_RECON_MST','MEMO_ID','memo_dt',''           
  UNION           
     SELECT 'DEBIT_NOTE_RECON_DET','MEMO_ID' ,'A.memo_dt',''          
  UNION          
     SELECT 'DSM01106','DS_ID','ds_dt',''           
        UNION          
     SELECT 'DSD01106','DS_ID','A.ds_dt',''                  
        UNION          
     SELECT 'EOSSDISABLEDSLS','CM_ID',' CM_DT',' '           
        UNION          
     SELECT 'EOSSDND','MEMO_ID','A.MEMO_DT',''           
  UNION          
     SELECT 'EOSSDNM','MEMO_ID','MEMO_DT',''           
        UNION          
     SELECT 'EOSSSORD','MEMO_ID','A.MEMO_DT',''           
        UNION          
     SELECT 'EOSSSORM','MEMO_ID','MEMO_DT',''           
  UNION    
     SELECT 'GV_CNC_MST','MEMO_ID','memo_dt',''           
        UNION           
     SELECT 'GV_CNC_DET','MEMO_ID','A.memo_dt',''                      
        UNION          
     SELECT 'GV_LOC','DEPT_ID','',''           
        UNION      
		
     SELECT 'PARCEL_MST','PARCEL_MEMO_ID','parcel_memo_dt',''           
  UNION         
     SELECT 'PARCEL_DET','PARCEL_MEMO_ID','A.parcel_memo_dt',''                    
  UNION     
     SELECT 'POST_SALES_JOBWORK_ISSUE_MST','ISSUE_ID','issue_dt',''           
  UNION          
     SELECT 'POST_SALES_JOBWORK_ISSUE_DET','ISSUE_ID' ,'A.issue_dt',''          
  UNION          
     SELECT 'POST_SALES_JOBWORK_RECEIPT_MST','RECEIPT_ID','receipt_dt',''           
  UNION         
     SELECT 'POST_SALES_JOBWORK_RECEIPT_DET','RECEIPT_ID','A.receipt_dt',''           
  UNION          
     SELECT 'SLR_RECON_MST','MEMO_ID','memo_dt',''           
  UNION          
     SELECT 'SLR_RECON_DET','MEMO_ID','A.memo_dt',''           
  UNION          
     SELECT 'SLS_STOCK_NA_REP_MST','MEMO_ID','memo_dt',''           
        UNION           
     SELECT 'SLS_STOCK_NA_REP_DET','MEMO_ID','A.memo_dt',''           
        UNION          
     SELECT 'STK_RECON_HIST_MST','RECON_ID','',''           
        UNION         
     SELECT 'STK_RECON_HIST_DET','RECON_ID','',''           
        UNION          
     SELECT 'STLM01106','DEPT_ID' ,'',''          
        UNION           
     SELECT 'STLD01106','DEPT_ID','',''           
  UNION          
     SELECT 'STM_PMT','MEMO_ID' ,'',''          
        UNION          
     SELECT 'STM_XNS','MEMO_ID','',''           
        UNION          
     SELECT 'STMD01106','MEMO_ID' ,'',''          
        UNION          
     SELECT 'STMH01106','MEMO_ID' ,'',''          
        UNION          
     SELECT 'TILL_BANK_TRANSFER','MEMO_ID','',''           
  UNION    
     SELECT 'TILL_EXPENSE_MST','MEMO_ID','MEMO_DT',''           
        UNION           
     SELECT 'TILL_EXPENSE_DET','MEMO_ID','A.MEMO_DT',''    
        UNION              
     SELECT 'TILL_LIFTS','MEMO_ID','',''           
        UNION          
     SELECT 'TILL_LOCKER','DEPT_ID','',''           
        UNION    
     SELECT 'TILL_SHIFT_MST','SHIFT_ID','open_date',''           
     UNION           
     SELECT 'TILL_SHIFT_DET','SHIFT_ID','A.open_date',''     
    UNION          
     SELECT 'TILL_SMS_LOG','SMS_ID','',''           
        UNION          
     SELECT 'TOM01106','ORDER_ID','order_dt',''           
        UNION           
     SELECT 'TOD01106','ORDER_ID','A.order_dt',''           
        UNION    
     SELECT 'WOM01106','ORDER_ID' ,'order_dt',''          
        UNION           
     SELECT 'WOD01106','ORDER_ID','A.order_dt',''           
        UNION          
     SELECT 'WSL_BO_REF','ORDER_ID','',''           
        UNION          
     SELECT 'WSL_ORDER_REF','INV_ID' ,'',''          
        UNION    
     SELECT 'TMD01106','ORDER_ID','',''           
        UNION     
     SELECT 'WSL_PICKLIST_MST','PICK_LIST_ID','PICK_LIST_DT',''     
        UNION         
     SELECT 'WSL_PICKLIST_DET','PICK_LIST_ID','A.PICK_LIST_DT',''               
         UNION          
     SELECT 'EMP_SHIFT_LOC','DEPT_ID','',''    
	 UNION
	 SELECT 'EMP_ATTENDANCE','DEPT_ID','','' 
     UNION
	 SELECT 'SalesOrderProcessing','MEMOID','','' 
	
               
     PRINT 'INSERT ALL TABLES'          
               
     IF OBJECT_ID ('TEMPDB..#TMPTRANS','U') IS NOT NULL          
        DROP TABLE #TMPTRANS          
     SELECT * INTO #TMPTRANS FROM #TABELIST          
               
     SET @NSTEP=40     
   


			 WHILE EXISTS (SELECT TOP 1 * FROM #TABELIST WHERE ISNULL(KEYFIELD,'') <> '')          
			 BEGIN          
              
				  SELECT TOP 1 @CTABLENAME=TABLENAME,@CKEYFIELD=KEYFIELD ,@JOINSTR =JOINSTR  FROM #TABELIST          
				  WHERE ISNULL(KEYFIELD,'') <> '' 
				 
				         
				  SET @CWHERECLAUSE=' LEFT('+@CKEYFIELD+',len('''+@CLOCID+'''))='''+@CLOCID+''''               
					  SET @NSTEP=42           
		 
				  IF @CTABLENAME='IRM01106'
				   SET @CWHERECLAUSE=' ((LEFT(B.'+@CKEYFIELD+',len('''+@CLOCID+'''))='''+@CLOCID+''') or (LEFT(B.'+@CKEYFIELD+',len('''+@CHODEPT_ID+'''))='''+@CHODEPT_ID+''' and Type<>2) ) '
		 
				  IF @CTABLENAME='PCI_MST'
				   SET @CWHERECLAUSE=' source_location_code='''+@CLOCID+'''' 
				   
				   IF @CTABLENAME IN('PIM01106','RMM01106','RMD01106')
				      SET @CWHERECLAUSE=@CWHERECLAUSE+' and  isnull(XN_ITEM_TYPE,0)<>4 '
				      

				    PRINT 'START FOR TABLE '+@CTABLENAME    
				    
                
					SET @CCMD=N'IF OBJECT_ID ('''+@CTABLENAME+''',''U'') IS NOT NULL          
					  BEGIN          
					   SELECT b.* INTO '+@CLOCDB+@CTABLENAME+' FROM '+@CTABLENAME+' b (nolock) '+@JOINSTR+'  WHERE '+@CWHERECLAUSE+ '          
					  END'          
		                
				   PRINT @CCMD+'END FOR TABLE '+@CTABLENAME          
				   EXEC SP_EXECUTESQL @CCMD          
                
				   DELETE FROM #TABELIST WHERE TABLENAME=@CTABLENAME           
             
			 END     
           
   
		
     
	
 if exists (select top 1 'u' from GV_STKXFER_MST (NOLOCK) WHERE target_dept_id=@CLOCID)  
 begin  
        
   SET @CTABLENAME='GV_STKXFER_MST'            
   SET @CCMD=N'SELECT DISTINCT  GV_STKXFER_MST.* INTO '+@CLOCDB+@CTABLENAME+' FROM GV_STKXFER_MST    
    where ( LEFT(MEMO_ID,len('''+@CLOCID+'''))='''+@CLOCID+''' or target_dept_id='''+@CLOCID+''' ) '            
                
  PRINT @CCMD            
  EXEC SP_EXECUTESQL @CCMD       
  
   SET @CTABLENAME='GV_STKXFER_DET'            
   SET @CCMD=N'SELECT DISTINCT  GV_STKXFER_DET.* INTO '+@CLOCDB+@CTABLENAME+' FROM GV_STKXFER_DET   
   join '+@CLOCDB+ 'GV_STKXFER_MST b on  GV_STKXFER_DET.memo_id= b.memo_id  
    '            
  PRINT @CCMD            
  EXEC SP_EXECUTESQL @CCMD    
  
  
   SET @CTABLENAME='SKU_GV_MST'            
   SET @CCMD=N'SELECT DISTINCT  SKU_GV_MST.* INTO '+@CLOCDB+@CTABLENAME+' FROM SKU_GV_MST   
   join '+@CLOCDB+ 'GV_STKXFER_DET b on  SKU_GV_MST.gv_srno= b.gv_srno  
    '            
  PRINT @CCMD            
  EXEC SP_EXECUTESQL @CCMD    
  
      SET @CTABLENAME='GV_MST_INFO'            
   SET @CCMD=N'SELECT DISTINCT  GV_MST_INFO.* INTO '+@CLOCDB+@CTABLENAME+' FROM GV_MST_INFO   
   join '+@CLOCDB+ 'GV_STKXFER_DET b on  GV_MST_INFO.gv_srno= b.gv_srno  
    '            
  PRINT @CCMD            
  EXEC SP_EXECUTESQL @CCMD    
  
      SET @CTABLENAME='GV_GEN_DET'            
   SET @CCMD=N'SELECT DISTINCT  GV_GEN_DET.* INTO '+@CLOCDB+@CTABLENAME+' FROM GV_GEN_DET   
   join '+@CLOCDB+ 'GV_STKXFER_DET b on  GV_GEN_DET.gv_srno= b.gv_srno  
    '            
  PRINT @CCMD            
  EXEC SP_EXECUTESQL @CCMD    
  
  SET @CTABLENAME='GV_GEN_MST'            
   SET @CCMD=N'SELECT DISTINCT  a.* INTO '+@CLOCDB+@CTABLENAME+' FROM GV_GEN_MST a  
    JOIN '+@CLOCDB+ 'GV_GEN_DET c (NOLOCK) ON c.memo_id=a.memo_id  
    JOIN '+@CLOCDB+ 'GV_STKXFER_DET b (NOLOCK) ON c.gv_srno=b.gv_srno  
    '            
  PRINT @CCMD            
  EXEC SP_EXECUTESQL @CCMD  
  

     SET @CTABLENAME='PMT_GV_MST'  

	 SET @CCMD=N' select cast(GV_SRNO as varchar(50)) as GV_SRNO,
		cast(sum(Quantity) as int) as quantity_in_stock
		INTO '+@CLOCDB+@CTABLENAME+'
		from (
	SELECT A.GV_SRNO , 
		   sum((CASE WHEN B.TARGET_DEPT_ID='''+@CLOCID+''' THEN 1 ELSE -1 END) *  A.QUANTITY) as Quantity 
	FROM '+@CLOCDB+ 'GV_STKXFER_DET A (NOLOCK)
	JOIN '+@CLOCDB+ 'GV_STKXFER_MST B (NOLOCK) ON A.MEMO_ID =B.MEMO_ID 
	WHERE B.CANCELLED =0 
	and (B.TARGET_DEPT_ID='''+@CLOCID+''' or left(a.memo_id,len('''+@CLOCID+'''))='''+@CLOCID+''')
	group by A.GV_SRNO 
	union all
	SELECT A.GV_SRNO , 
		   sum(-1 *  A.QUANTITY) as Quantity 
	FROM '+@CLOCDB+ 'ARC_GVSALE_DETAILS A (NOLOCK)
	JOIN '+@CLOCDB+ 'arc01106 B (NOLOCK) ON A.adv_rec_id =B.adv_rec_id 
	WHERE B.CANCELLED =0 
	AND LEFT(B.ADV_REC_ID,len('''+@CLOCID+'''))='''+@CLOCID+'''
	group by A.GV_SRNO 
	union all
	SELECT A.gv_srno , 
		   sum(-1 *  A.QUANTITY) as Quantity 
	FROM '+@CLOCDB+ 'gv_cnc_det A (NOLOCK)
	JOIN '+@CLOCDB+ 'gv_cnc_mst B (NOLOCK) ON A.memo_id =B.memo_id 
	where LEFT(B.memo_id,len('''+@CLOCID+'''))='''+@CLOCID+'''
	group by A.gv_srno 
	union all
	SELECT A.gv_srno , 
		   sum(  A.QUANTITY) as Quantity 
	FROM '+@CLOCDB+ 'GV_GEN_DET A (NOLOCK)
	JOIN '+@CLOCDB+ 'GV_GEN_mst B (NOLOCK) ON A.memo_id =B.memo_id 
	where LEFT(B.memo_id,len('''+@CLOCID+'''))='''+@CLOCID+'''
	group by A.gv_srno 
	union all
	SELECT B.GV_SRNO,-1 *COUNT (*) AS QUANTITY 
	FROM PAYMODE_XN_DET B
	join cmm01106 cmm (nolock) on b.memo_id=cmm.cm_id
	JOIN sku_gv_mst C ON c.gv_srno=b.gv_srno
	WHERE  XN_TYPE=''SLS'' and cmm.cancelled=0 
	and LEFT(B.memo_id,len('''+@CLOCID+'''))='''+@CLOCID+'''
	GROUP BY B.GV_SRNO

	) a
	group by GV_SRNO
	'
	PRINT @CCMD
	EXEC SP_EXECUTESQL @CCMD


   
  
  
 end  

     
   SET @NSTEP=48     
   
   SET @CTABLENAME='PID01106'

   SET @CCMD=N'IF OBJECT_ID ('''+@CTABLENAME+''',''U'') IS NOT NULL          
	    BEGIN          
			   SELECT b.* INTO '+@CLOCDB+@CTABLENAME+' FROM '+@CTABLENAME+' (NOLOCK) B 
			   join pim01106 pim (nolock) on pim.mrr_id =b.mrr_id 
			   where pim.dept_id ='''+@CLOCID+''' and inv_mode=1  and isnull(pim.XN_ITEM_TYPE,0)<>4      
		  END'          
		                
    PRINT @CCMD+'END FOR TABLE '+@CTABLENAME          
	EXEC SP_EXECUTESQL @CCMD          


	SET @NStep=59
	
    SET @cCmd=N'INSERT '+@ClOCdB+'PID01106	( area_length, area_rate_pp, area_sqare, area_uom_code, area_width, article_code, AUTO_SRNO, BATCH_NO, BIN_ID, BOX_ID, box_no, CashDiscountAmount, CESS_AMOUNT, cgst_amount, discount_amount, discount_percentage, expiry_dt, Fix_mrp, FORM_ID, GRN_QTY, gross_purchase_price, gst_percentage, hsn_code, igst_amount, invoice_quantity, item_excise_duty_amount, item_excise_duty_percentage, LABEL_COPIES, last_update, manual_discount, manual_dpp, manual_fix_mrp, manual_gpp, manual_mdp, manual_mpp, manual_mpp_wsp, manual_mrp, manual_wsp, manual_wspp, material_cost, MD_PERCENTAGE, MP_PER_WSP, mp_percentage, mrp, mrr_id, para1_code, para2_code, para3_code, para4_code, para5_code, para6_code, PIMDiscountAmount, PIMExciseDutyAmount, PIMPostTaxDiscountAmount, po_id, po_row_id, print_label, product_code, PRTAmount, prtamount_credited,
     purchase_price, quantity, RATE_AREA_SQUARE, rcm_cgst_amount, rcm_gst_percentage, rcm_igst_amount, rcm_sgst_amount, rcm_taxable_value, rfnet, rfnet_wotax, row_id, scheme_quantity, sgst_amount, SRNO, srv_narration, TAX_AMOUNT, TAX_PERCENTAGE, tax_round_off, USER_SRNO, VENDOR_EAN_NO, w8_challan_id, WD_PERCENTAGE, wholesale_price, 
     wsp_percentage, xn_value_with_gst, xn_value_without_gst,ps_id )  
	SELECT 0 AREA_LENGTH,0 AREA_RATE_PP,0 AREA_SQARE,00 AREA_UOM_CODE,0 AREA_WIDTH, S.ARTICLE_CODE, AUTO_SRNO, BATCH_NO, B.target_bin_id BIN_ID, BOX_ID, BOX_NO,0 CASHDISCOUNTAMOUNT, CESS_AMOUNT, CGST_AMOUNT, 
	ISNULL(IND.DISCOUNT_AMOUNT,0) AS DISCOUNT_AMOUNT,ISNULL(IND. DISCOUNT_PERCENTAGE,0) AS DISCOUNT_PERCENTAGE, EXPIRY_DT, FIX_MRP, isnull(FORM_ID,'''') ,0 GRN_QTY,RATE GROSS_PURCHASE_PRICE,IND. GST_PERCENTAGE, IND.HSN_CODE, IGST_AMOUNT, INVOICE_QUANTITY, ITEM_EXCISE_DUTY_AMOUNT, ITEM_EXCISE_DUTY_PERCENTAGE,0 LABEL_COPIES,IND. LAST_UPDATE,IND. MANUAL_DISCOUNT,0 MANUAL_DPP,
	0 MANUAL_FIX_MRP,0 MANUAL_GPP,0 MANUAL_MDP,0 MANUAL_MPP,0 MANUAL_MPP_WSP,
	0 MANUAL_MRP,0 MANUAL_WSP,0 MANUAL_WSPP,0 MATERIAL_COST,0 MD_PERCENTAGE,
	0 MP_PER_WSP,0 MP_PERCENTAGE,IND. MRP, A.MRR_ID, PARA1_CODE, PARA2_CODE, PARA3_CODE, PARA4_CODE, PARA5_CODE, PARA6_CODE, 
	isnull(INMDISCOUNTAMOUNT,0)  PIMDISCOUNTAMOUNT,0 PIMEXCISEDUTYAMOUNT,0 PIMPOSTTAXDISCOUNTAMOUNT,'''' PO_ID,'''' PO_ROW_ID, PRINT_LABEL, 
	ind.PRODUCT_CODE,0 PRTAMOUNT,0 PRTAMOUNT_CREDITED, net_rate  PURCHASE_PRICE, 
	ind.QUANTITY,0 RATE_AREA_SQUARE,0 RCM_CGST_AMOUNT,0 RCM_GST_PERCENTAGE,0 RCM_IGST_AMOUNT,0 RCM_SGST_AMOUNT,0 RCM_TAXABLE_VALUE, 
	RFNET, RFNET_WOTAX,newid() as ROW_ID, SCHEME_QUANTITY, SGST_AMOUNT, 
	0 SRNO,NULL SRV_NARRATION, IND.ITEM_TAX_AMOUNT, 
	IND.ITEM_TAX_PERCENTAGE, IND.TAX_ROUND_OFF,0 USER_SRNO, 
	VENDOR_EAN_NO, W8_CHALLAN_ID, 0 WD_PERCENTAGE, 
	ISNULL(IND.ws_price,0)  WHOLESALE_PRICE,0 WSP_PERCENTAGE, XN_VALUE_WITH_GST, XN_VALUE_WITHOUT_GST ,ind.ps_id 
	FROM PIM01106 A (NOLOCK)
	JOIN INM01106 B (NOLOCK) ON A.INV_ID =B.INV_ID 
	JOIN IND01106 IND (NOLOCK) ON B.INV_ID =IND.INV_ID 
	JOIN SKU S (NOLOCK) ON S.product_code =IND.PRODUCT_CODE 
	WHERE A.DEPT_ID ='''+@CLOCID+''' AND  A.INV_MODE=2 AND A.CANCELLED=0 '
	EXEC SP_EXECUTESQL @CcMD

	SET @CTABLENAME='SNC_BARCODE_DET'

   SET @CCMD=N' SELECT b.* INTO '+@CLOCDB+@CTABLENAME+' FROM '+@CTABLENAME+' (NOLOCK) B 
			   join SNC_DET DET (nolock) on DET.ROW_ID =b.REFROW_ID 
			   where LEFT(DET.MEMO_ID,len('''+@CLOCID+''')) ='''+@CLOCID+''' '          
		                
    PRINT @CCMD+'END FOR TABLE '+@CTABLENAME          
	EXEC SP_EXECUTESQL @CCMD          

     
               
  SET @NSTEP=50              
 
    SET @NSTEP=60    
     SET @CTABLENAME='SKU'   
     
        declare @CCMDSKU nvarchar(max)    
          
		SET @CCMD=N'SELECT DISTINCT  SKU.* INTO '+@CLOCDB+@CTABLENAME+' FROM SKU          
		JOIN           
		(          
		SELECT PRODUCT_CODE FROM OPS01106 WHERE ('''+@CLOCID+'''='''' or DEPT_ID ='''+@CLOCID+''' )  
		UNION           
		SELECT a.PRODUCT_CODE FROM '+@CLOCDB+ 'SNC_barcode_det  a
		UNION           
		SELECT PRODUCT_CODE FROM '+@CLOCDB+ 'WSL_order_det  WHERE ('''+@CLOCID+'''='''' or left(order_id,len('''+@CLOCID+''')) ='''+@CLOCID+''' )  
		UNION           
		SELECT PRODUCT_CODE FROM '+@CLOCDB+ 'hold_back_deliver_det  WHERE ('''+@CLOCID+'''='''' or left(memo_id,len('''+@CLOCID+''')) ='''+@CLOCID+''' )  
		UNION  
		SELECT PRODUCT_CODE FROM PID01106  WHERE  ('''+@CLOCID+'''='''' or LEFT (MRR_ID,len('''+@CLOCID+''')) ='''+@CLOCID+''' )  
		UNION           
		SELECT PRODUCT_CODE FROM CND01106  WHERE  ('''+@CLOCID+'''='''' or LEFT (CN_ID,len('''+@CLOCID+''')) ='''+@CLOCID+''') 
		UNION           
		SELECT PRODUCT_CODE FROM apd01106  WHERE  ('''+@CLOCID+'''='''' or LEFT (memo_id,len('''+@CLOCID+''')) ='''+@CLOCID+''')          
		UNION           
		SELECT PRODUCT_CODE FROM SNC_CONSUMABLE_DET   WHERE ('''+@CLOCID+'''='''' or LEFT (MEMO_ID,len('''+@CLOCID+''')) ='''+@CLOCID+''' )         
		UNION           
		SELECT PRODUCT_CODE FROM CMD01106    WHERE ('''+@CLOCID+'''='''' or  LEFT (CM_ID,len('''+@CLOCID+''')) ='''+@CLOCID+''') 
		UNION           
		SELECT PRODUCT_CODE FROM icd01106    WHERE ('''+@CLOCID+'''='''' or  LEFT (cnc_memo_id,len('''+@CLOCID+''')) ='''+@CLOCID+''') 
		UNION           
		SELECT PRODUCT_CODE FROM WPS_DET    WHERE ('''+@CLOCID+'''='''' or  LEFT (PS_ID,len('''+@CLOCID+''')) ='''+@CLOCID+''') 
		UNION           
		SELECT NEW_PRODUCT_CODE FROM Ird01106   WHERE new_PRODUCT_CODE<>'''' and  ('''+@CLOCID+'''='''' or  dept_id ='''+@CLOCID+''') 
		UNION           
		SELECT PRODUCT_CODE FROM Ird01106   WHERE new_PRODUCT_CODE<>'''' and  ('''+@CLOCID+'''='''' or  dept_id ='''+@CLOCID+''') 
		UNION '
		
		SET @CCMDSKU=' SELECT PRODUCT_CODE FROM IND01106 a (nolock) join inm01106 b on a.inv_id=b.inv_id  WHERE ('''+@CLOCID+'''='''' or  (LEFT (a.INV_ID,len('''+@CLOCID+''')) ='''+@CLOCID+''' or b.party_dept_id='''+@CLOCID+''')) 
		union
		SELECT LEFT(PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',PRODUCT_CODE)-1,-1),LEN(PRODUCT_CODE ))) AS PRODUCT_CODE FROM OPS01106 WHERE ('''+@CLOCID+'''='''' or DEPT_ID ='''+@CLOCID+''' )  and charindex(''@'',product_code)<>0
		UNION           
		SELECT LEFT(PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',PRODUCT_CODE)-1,-1),LEN(PRODUCT_CODE ))) FROM PID01106  WHERE  ('''+@CLOCID+'''='''' or LEFT (MRR_ID,len('''+@CLOCID+''')) ='''+@CLOCID+''' )   and charindex(''@'',product_code)<>0
		UNION           
		SELECT LEFT(PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',PRODUCT_CODE)-1,-1),LEN(PRODUCT_CODE ))) FROM CND01106  WHERE  ('''+@CLOCID+'''='''' or LEFT (CN_ID,len('''+@CLOCID+''')) ='''+@CLOCID+''')  and charindex(''@'',product_code)<>0         
		UNION           
		SELECT LEFT(PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',PRODUCT_CODE)-1,-1),LEN(PRODUCT_CODE ))) FROM apd01106  WHERE  ('''+@CLOCID+'''='''' or LEFT (memo_id,len('''+@CLOCID+''')) ='''+@CLOCID+''')  and charindex(''@'',product_code)<>0         
		UNION           
		SELECT LEFT(PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',PRODUCT_CODE)-1,-1),LEN(PRODUCT_CODE ))) FROM SNC_CONSUMABLE_DET   WHERE ('''+@CLOCID+'''='''' or LEFT (MEMO_ID,len('''+@CLOCID+''')) ='''+@CLOCID+''' )     and charindex(''@'',product_code)<>0     
		UNION           
		SELECT LEFT(PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',PRODUCT_CODE)-1,-1),LEN(PRODUCT_CODE ))) FROM CMD01106    WHERE ('''+@CLOCID+'''='''' or  LEFT (CM_ID,len('''+@CLOCID+''')) ='''+@CLOCID+''')  and charindex(''@'',product_code)<>0
		UNION           
		SELECT LEFT(PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',PRODUCT_CODE)-1,-1),LEN(PRODUCT_CODE ))) FROM icd01106    WHERE ('''+@CLOCID+'''='''' or  LEFT (cnc_memo_id,len('''+@CLOCID+''')) ='''+@CLOCID+''')  and charindex(''@'',product_code)<>0
		UNION
		SELECT LEFT(PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',PRODUCT_CODE)-1,-1),LEN(PRODUCT_CODE ))) FROM '+@CLOCDB+ 'SNC_barcode_det  where  charindex(''@'',product_code)<>0
        union
        SELECT LEFT(NEW_PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',NEW_PRODUCT_CODE)-1,-1),LEN(NEW_PRODUCT_CODE ))) FROM '+@CLOCDB+ 'Ird01106   WHERE new_PRODUCT_CODE<>'''' and charindex(''@'',new_PRODUCT_CODE)<>0
        union
		SELECT LEFT(PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',PRODUCT_CODE)-1,-1),LEN(PRODUCT_CODE ))) FROM WPS_DET    WHERE ('''+@CLOCID+'''='''' or  LEFT (PS_ID,len('''+@CLOCID+''')) ='''+@CLOCID+''')  and charindex(''@'',product_code)<>0
		UNION           
		SELECT LEFT(PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',PRODUCT_CODE)-1,-1),LEN(PRODUCT_CODE ))) FROM IND01106 a join inm01106 b on a.inv_id=b.inv_id   
		 WHERE ('''+@CLOCID+'''='''' or  (LEFT (a.INV_ID,len('''+@CLOCID+''')) ='''+@CLOCID+''' or b.party_dept_id='''+@CLOCID+'''))   and charindex(''@'',product_code)<>0
		) B ON SKU.PRODUCT_CODE=B.PRODUCT_CODE  '          
              
       
  

    PRINT (@CCMD+@CCMDSKU)      
    set @CCMD=@CCMD+@CCMDSKU    
    EXEC SP_EXECUTESQL @CCMD

	
	 SET @CTABLENAME='SKU_NAMES'          
     SET @CCMD=N'SELECT DISTINCT  SKU_NAMES.* INTO '+@CLOCDB+@CTABLENAME+' FROM SKU_NAMES          
    JOIN           
    (          
     SELECT PRODUCT_CODE FROM '+@CLOCDB+ 'SKU          
    ) B ON SKU_NAMES.PRODUCT_CODE=B.PRODUCT_CODE '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD   


	 SET @CTABLENAME='SKU_Active_titles'          
     SET @CCMD=N'SELECT DISTINCT  SKU_Active_titles.* INTO '+@CLOCDB+@CTABLENAME+' FROM SKU_Active_titles          
    JOIN           
    (          
     SELECT PRODUCT_CODE FROM '+@CLOCDB+ 'SKU          
    ) B ON SKU_Active_titles.PRODUCT_CODE=B.PRODUCT_CODE '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD   



	SET @CCMD=N'update b set ref_cm_id =a.cm_id 
	from '+@CLOCDB+ ' cmd01106 a
	join '+@CLOCDB+ ' cmm01106 cmm on a.cm_id=cmm.cm_id 
	join '+@CLOCDB+ ' rps_mst b on a.pack_slip_id=b.cm_id 
	where pack_slip_id<>'''' and cmm.CANCELLED=0
	and isnull(b.ref_cm_id,'''') ='''' 
	 '
	 PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD 
          
    SET @CTABLENAME='CUSTDYM'          
    SET @CCMD=N'SELECT DISTINCT  custdym.* INTO '+@CLOCDB+@CTABLENAME+' FROM custdym          
    JOIN            
    (          
    SELECT customer_code FROM cmm01106 WHERE ('''+@CLOCID+'''='''' or left (cm_id,len('''+@CLOCID+''')) ='''+@CLOCID+''')          
    UNION           
    SELECT customer_code FROM arc01106  WHERE ('''+@CLOCID+'''='''' or LEFT (adv_rec_id,len('''+@CLOCID+''')) ='''+@CLOCID+''')  
    UNION           
    SELECT customer_code FROM wsl_order_mst  WHERE ('''+@CLOCID+'''='''' or LEFT (order_ID,len('''+@CLOCID+''')) ='''+@CLOCID+''')     
	UNION           
    SELECT customer_code FROM apm01106  WHERE ('''+@CLOCID+'''='''' or LEFT (memo_id,len('''+@CLOCID+''')) ='''+@CLOCID+''')   
	UNION           
    SELECT customer_code FROM HOLD_BACK_DELIVER_MST  WHERE ('''+@CLOCID+'''='''' or LEFT (memo_id,len('''+@CLOCID+''')) ='''+@CLOCID+''')   
	
    ) B ON custdym.customer_code=B.customer_code '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD        
       
            
         
                  
              
    SET @NSTEP=62          
    SET @CTABLENAME='LOCATION'          
     SET @CCMD=N'SELECT DISTINCT  LOCATION.* INTO '+@CLOCDB+@CTABLENAME+' FROM LOCATION '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
              
    SET @NSTEP=65          
    SET @CTABLENAME='USERS'          
     SET @CCMD=N'SELECT DISTINCT  USERS.* INTO '+@CLOCDB+@CTABLENAME+' FROM USERS           
     left JOIN  LOCUSERS ON USERS.USER_CODE=LOCUSERS.USER_CODE           
     WHERE ('''+@CLOCID+'''='''' or LOCUSERS.DEPT_ID='''+@CLOCID+''') '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
              
    SET @NSTEP=66          
    SET @CTABLENAME='USER_ROLE_DET'          
    SET @CCMD=N'SELECT DISTINCT  USER_ROLE_DET.* INTO '+@CLOCDB+@CTABLENAME+' FROM USER_ROLE_DET '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
              
    SET @NSTEP=67          
    SET @CTABLENAME='USER_ROLE_MST'          
    SET @CCMD=N'SELECT DISTINCT  USER_ROLE_MST.* INTO '+@CLOCDB+@CTABLENAME+' FROM USER_ROLE_MST          
    JOIN  USER_ROLE_DET ON USER_ROLE_DET.ROLE_ID=USER_ROLE_MST.ROLE_ID  '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
              
              
    SET @NSTEP=68          
    SET @CTABLENAME='BIN_LOC'          
    SET @CCMD=N'SELECT DISTINCT  BIN_LOC.* INTO '+@CLOCDB+@CTABLENAME+' FROM BIN_LOC          
    WHERE ('''+@CLOCID+'''='''' or BIN_LOC.DEPT_ID='''+@CLOCID+''' )'          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
              
     SET @NSTEP=69          
    SET @CTABLENAME='LOCUSERS'          
    SET @CCMD=N'SELECT DISTINCT  LOCUSERS.* INTO '+@CLOCDB+@CTABLENAME+' FROM LOCUSERS          
    WHERE ('''+@CLOCID+'''='''' or LOCUSERS.DEPT_ID='''+@CLOCID+''') '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
              
    SET @NSTEP=70          
    SET @CTABLENAME='ARTICLE'          
     SET @CCMD=N'SELECT DISTINCT  ARTICLE.* INTO '+@CLOCDB+@CTABLENAME+' FROM ARTICLE          
    JOIN           
    (          
     SELECT ARTICLE_CODE FROM '+@CLOCDB+ 'SKU union     
     SELECT ARTICLE_CODE FROM '+@CLOCDB+ 'buyer_order_det      
    ) B ON ARTICLE.ARTICLE_CODE=B.ARTICLE_CODE '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
              
              
    SET @NSTEP=80          
    SET @CTABLENAME='SECTIOND'          
    SET @CCMD=N'SELECT DISTINCT  SECTIOND.* INTO '+@CLOCDB+@CTABLENAME+' FROM SECTIOND          
    JOIN           
    (          
     SELECT SUB_SECTION_CODE FROM '+@CLOCDB+ 'ARTICLE          
    ) B ON SECTIOND.SUB_SECTION_CODE=B.SUB_SECTION_CODE 
    UNION
    SELECT * FROM SECTIOND WHERE SUB_SECTION_CODE LIKE ''0000%'''          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD     
    
     SET @NSTEP=80          
    SET @CTABLENAME='paymode_xn_det'          
    SET @CCMD=N'SELECT DISTINCT  paymode_xn_det.* INTO '+@CLOCDB+@CTABLENAME+' FROM paymode_xn_det          
    JOIN           
    (          
      SELECT ''SLS'' AS XN_TYPE,CM_ID AS MEMO_ID FROM '+@CLOCDB+ 'CMM01106 A
      UNION ALL
      SELECT ''WSL'' AS XN_TYPE,INV_ID AS MEMO_ID FROM '+@CLOCDB+ 'INM01106 A
      UNION ALL
      SELECT ''ARC'' AS XN_TYPE,ADV_REC_ID AS MEMO_ID FROM '+@CLOCDB+ 'ARC01106 A
             
    ) B ON paymode_xn_det.memo_id=B.memo_id and paymode_xn_det.xn_type=b.xn_type '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
                   
              
    --
  --   SELECT 'PAYMODE_XN_DET','MEMO_ID','A.CM_DT',' JOIN CMM01106 A ON A.CM_ID=B.MEMO_ID'          
  --UNION 
              
    SET @NSTEP=90          
    SET @CTABLENAME='SECTIONM'          
    SET @CCMD=N'SELECT DISTINCT  SECTIONM.* INTO '+@CLOCDB+@CTABLENAME+' FROM SECTIONM          
    JOIN           
    (          
     SELECT SECTION_CODE FROM '+@CLOCDB+ 'SECTIOND          
    ) B ON SECTIONM.SECTION_CODE=B.SECTION_CODE 
    UNION
    SELECT * FROM SECTIONM WHERE SECTION_CODE LIKE ''0000%'''          

    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
              
              
    SET @NSTEP=100          
    SET @CTABLENAME='PARA1'          
     SET @CCMD=N'SELECT DISTINCT  PARA1.* INTO '+@CLOCDB+@CTABLENAME+' FROM PARA1          
    JOIN           
    (          
     SELECT PARA1_CODE FROM '+@CLOCDB+ 'SKU union
     SELECT Para1_code FROM '+@CLOCDB+ 'buyer_order_det union 
     SELECT Para1_code FROM '+@CLOCDB+ 'wsl_order_det          
    ) B ON PARA1.PARA1_CODE=B.PARA1_CODE 
    UNION
    SELECT * FROM PARA1 WHERE PARA1_CODE LIKE ''00000%'''
    
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
             
              
    SET @NSTEP=110          
    SET @CTABLENAME='PARA2'          
    SET @CCMD=N'SELECT DISTINCT  PARA2.* INTO '+@CLOCDB+@CTABLENAME+' FROM PARA2          
    JOIN           
    (          
     SELECT PARA2_CODE FROM '+@CLOCDB+ 'SKU union
     SELECT Para2_code FROM '+@CLOCDB+ 'buyer_order_det union 
     SELECT Para2_code FROM '+@CLOCDB+ 'wsl_order_det             
    ) B ON PARA2.PARA2_CODE=B.PARA2_CODE 
    UNION
    SELECT * FROM PARA2 WHERE PARA2_CODE LIKE ''00000%'''
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
              
              
    SET @NSTEP=120          
    SET @CTABLENAME='PARA3'          
    SET @CCMD=N'SELECT DISTINCT  PARA3.* INTO '+@CLOCDB+@CTABLENAME+' FROM PARA3          
    JOIN           
    (          
     SELECT PARA3_CODE FROM '+@CLOCDB+ 'SKU union
     SELECT Para3_code FROM '+@CLOCDB+ 'buyer_order_det union 
     SELECT Para3_code FROM '+@CLOCDB+ 'wsl_order_det            
    ) B ON PARA3.PARA3_CODE=B.PARA3_CODE 
    UNION
    SELECT * FROM PARA3 WHERE PARA3_CODE LIKE ''00000%'''              
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
              
              
 SET @NSTEP=130          
    SET @CTABLENAME='PARA4'          
    SET @CCMD=N'SELECT DISTINCT  PARA4.* INTO '+@CLOCDB+@CTABLENAME+' FROM PARA4          
    JOIN           
    (          
     SELECT PARA4_CODE FROM '+@CLOCDB+ 'SKU          
    ) B ON PARA4.PARA4_CODE=B.PARA4_CODE 
    UNION
    SELECT * FROM PARA4 WHERE PARA4_CODE LIKE ''00000%'''
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
              
    SET @NSTEP=140          
    SET @CTABLENAME='PARA5'          
    SET @CCMD=N'SELECT DISTINCT  PARA5.* INTO '+@CLOCDB+@CTABLENAME+' FROM PARA5          
    JOIN           
    (          
     SELECT PARA5_CODE FROM '+@CLOCDB+ 'SKU          
    ) B ON PARA5.PARA5_CODE=B.PARA5_CODE 
    UNION
    SELECT * FROM PARA5 WHERE PARA5_CODE LIKE ''00000%'''
             
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
              
              
    SET @NSTEP=140          
    SET @CTABLENAME='PARA6'          
    SET @CCMD=N'SELECT DISTINCT  PARA6.* INTO '+@CLOCDB+@CTABLENAME+' FROM PARA6          
    JOIN           
    (          
     SELECT PARA6_CODE FROM '+@CLOCDB+ 'SKU          
    ) B ON PARA6.PARA6_CODE=B.PARA6_CODE 
    UNION
    SELECT * FROM PARA6 WHERE PARA6_CODE LIKE ''00000%'''
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
              
              
    SET @NSTEP=150          
    SET @CTABLENAME='LM01106'          
    SET @CCMD=N'SELECT DISTINCT  LM01106.* INTO '+@CLOCDB+@CTABLENAME+' FROM LM01106          
    JOIN           
    (          
     SELECT AC_CODE FROM '+@CLOCDB+ 'SKU          
     UNION          
     SELECT DEPT_AC_CODE FROM LOCATION  
     UNION
     SELECT AC_CODE FROM LM01106 WHERE AC_CODE between ''0000000000''  and ''0000000013''  
     UNION 
     SELECT tax_ac_code FROM LOCSST  
     UNION 
     SELECT SALE_ac_code FROM LOCSST 
     UNION 
     SELECT purchase_ac_code FROM LOCSST 
     UNION 
     SELECT ac_code FROM '+@CLOCDB+ 'PED01106 
	 union 
	 SELECT ac_code FROM '+@CLOCDB+ 'INM01106 A
	 union 
	 SELECT ac_code FROM '+@CLOCDB+ 'pim01106 A
       
    ) B ON LM01106.AC_CODE=B.AC_CODE '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
              
             
           
    SET @NSTEP=160          
    SET @CTABLENAME='LMP01106'          
    SET @CCMD=N'SELECT DISTINCT  LMP01106.* INTO '+@CLOCDB+@CTABLENAME+' FROM LMP01106          
    JOIN           
    (          
     SELECT AC_CODE FROM '+@CLOCDB+ 'LM01106          
    ) B ON LMP01106.AC_CODE=B.AC_CODE '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
              
    SET @NSTEP=180          
    SET @CTABLENAME='EMPLOYEE'          
    SET @CCMD=N'SELECT DISTINCT  EMPLOYEE.* INTO '+@CLOCDB+@CTABLENAME+' FROM EMPLOYEE          
    JOIN           
    (          
     SELECT EMP_CODE FROM '+@CLOCDB+ 'SKU          
    ) B ON EMPLOYEE.EMP_CODE=B.EMP_CODE '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
              

              
    SET @NSTEP=190          
    SET @CTABLENAME='HD01106'          
    SET @CCMD=N'SELECT DISTINCT  HD01106.* INTO '+@CLOCDB+@CTABLENAME+' FROM HD01106          
    JOIN           
    (          
     SELECT HEAD_CODE FROM '+@CLOCDB+ 'LM01106 
     union
     SELECT HEAD_CODE FROM HD01106 WHERE HEAD_CODE BETWEEN ''0000000001'' AND ''0000000031''   
    ) B ON HD01106.HEAD_CODE=B.HEAD_CODE '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
              
    SET @NSTEP=200          
    SET @CTABLENAME='ANGM'          
    SET @CCMD=N'SELECT DISTINCT  ANGM.* INTO '+@CLOCDB+@CTABLENAME+' FROM ANGM '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
              
    SET @NSTEP=210          
    SET @CTABLENAME='JOBS'          
    SET @CCMD=N'SELECT DISTINCT  JOBS.* INTO '+@CLOCDB+@CTABLENAME+' FROM JOBS '          
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD  
    
    
                  
    SET @NSTEP=211          
    SET @CTABLENAME='ATTRM'          
    SET @CCMD=N'SELECT DISTINCT  ATTRM.* INTO '+@CLOCDB+@CTABLENAME+' FROM ATTRM '                  
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD  
    
               
    SET @NSTEP=212         
    SET @CTABLENAME='locsst'          
    SET @CCMD=N'SELECT DISTINCT  locsst.* INTO '+@CLOCDB+@CTABLENAME+' FROM locsst '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD  
    
    
     SET @NSTEP=212         
    SET @CTABLENAME='locsst_mst'          
    SET @CCMD=N'SELECT DISTINCT  locsst_mst.* INTO '+@CLOCDB+@CTABLENAME+' FROM locsst_mst '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD  
    
    
     SET @NSTEP=212         
    SET @CTABLENAME='locsstAdd'          
    SET @CCMD=N'SELECT DISTINCT  locsstAdd.* INTO '+@CLOCDB+@CTABLENAME+' FROM locsstAdd '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD  
    
              
    SET @NSTEP=220          
    SET @CTABLENAME='AREA'          
    SET @CCMD=N'SELECT DISTINCT  AREA.* INTO '+@CLOCDB+@CTABLENAME+' FROM AREA '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
              
              
    SET @NSTEP=230          
    SET @CTABLENAME='CITY'          
    SET @CCMD=N'SELECT DISTINCT  CITY.* INTO '+@CLOCDB+@CTABLENAME+' FROM CITY '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
      
    SET @NSTEP=235          
    SET @CTABLENAME='form'          
    SET @CCMD=N'SELECT DISTINCT  form.* INTO '+@CLOCDB+@CTABLENAME+' FROM form '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD             
        
               
    SET @NSTEP=240          
    SET @CTABLENAME='STATE'          
    SET @CCMD=N'SELECT DISTINCT  STATE.* INTO '+@CLOCDB+@CTABLENAME+' FROM STATE '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
              
    SET @NSTEP=250          
    SET @CTABLENAME='REGIONM'          
    SET @CCMD=N'SELECT DISTINCT  REGIONM.* INTO '+@CLOCDB+@CTABLENAME+' FROM REGIONM '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
              
       
    SET @NSTEP=251          
    SET @CTABLENAME='modules'          
    SET @CCMD=N'SELECT DISTINCT  modules.* INTO '+@CLOCDB+@CTABLENAME+' FROM modules '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD        
    
    SET @NSTEP=260          
    SET @CTABLENAME='COMPANY'          
    SET @CCMD=N'SELECT DISTINCT  COMPANY.* INTO '+@CLOCDB+@CTABLENAME+' FROM COMPANY '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD        
      
      
      
      
    SET @NSTEP=252          
    SET @CTABLENAME='REPORTS'          
    SET @CCMD=N'SELECT DISTINCT  REPORTS.* INTO '+@CLOCDB+@CTABLENAME+' FROM REPORTS '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD    
      
    SET @NSTEP=252          
    SET @CTABLENAME='PAYMODE_MST'          
    SET @CCMD=N'SELECT DISTINCT  PAYMODE_MST.* INTO '+@CLOCDB+@CTABLENAME+' FROM PAYMODE_MST '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD  
      
      
    SET @NSTEP=254          
    SET @CTABLENAME='PAYMODE_GRP_MST'          
    SET @CCMD=N'SELECT DISTINCT  PAYMODE_GRP_MST.* INTO '+@CLOCDB+@CTABLENAME+' FROM PAYMODE_GRP_MST '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD            
              
     SET @NSTEP=270          
     SET @CTABLENAME='SKU_BO'          
     SET @CCMD=N'SELECT DISTINCT  SKU_BO.* INTO '+@CLOCDB+@CTABLENAME+' FROM SKU_BO          
    JOIN          
    (          
     SELECT PRODUCT_CODE FROM '+@CLOCDB+ 'SKU          
    ) B ON SKU_BO.PRODUCT_CODE=B.PRODUCT_CODE '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
              
     SET @NSTEP=280          
     SET @CTABLENAME='SKU_OH'          
     SET @CCMD=N'SELECT DISTINCT  SKU_OH.* INTO '+@CLOCDB+@CTABLENAME+' FROM SKU_OH          
    JOIN           
    (          
     SELECT PRODUCT_CODE FROM '+@CLOCDB+ 'SKU          
    ) B ON SKU_OH.PRODUCT_CODE=B.PRODUCT_CODE '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
              
              
    SET @NSTEP=280          
    SET @CTABLENAME='DTM'          
    SET @CCMD=N'SELECT DISTINCT  DTM.* INTO '+@CLOCDB+@CTABLENAME+' FROM DTM '          
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD  
    
    
    SET @NSTEP=280          
    SET @CTABLENAME='GST_REPORT_CONFIG'          
    SET @CCMD=N'SELECT DISTINCT  GST_REPORT_CONFIG.* INTO '+@CLOCDB+@CTABLENAME+' FROM GST_REPORT_CONFIG '          
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
              
              
    SET @NSTEP=290          
    SET @CTABLENAME='NRM'          
    SET @CCMD=N'SELECT DISTINCT  NRM.* INTO '+@CLOCDB+@CTABLENAME+' FROM NRM '          
    PRINT @CCMD      EXEC SP_EXECUTESQL @CCMD          
              
              
    SET @NSTEP=300          
    SET @CTABLENAME='CONFIG'          
    SET @CCMD=N'SELECT DISTINCT  CONFIG.* INTO '+@CLOCDB+@CTABLENAME+' FROM CONFIG '          
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
              
    SET @NSTEP=305          
              
    SET @CCMD=N'UPDATE A SET VALUE=case when '''+@CLOCID+'''='''' then value else '''+@CLOCID+''' end  FROM '+@CLOCDB+@CTABLENAME+' A WHERE CONFIG_OPTION=''LOCATION_ID'''          
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD 
    
      

	SET @CCMD=N'UPDATE A SET value=0  FROM '+@CLOCDB+@CTABLENAME+' A WHERE config_option in(''OPT_STOCK'',''OPT_GIT'') '          
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD   
	
	SET @CCMD=N'DELETE A  FROM '+@CLOCDB+@CTABLENAME+' A WHERE config_option in(''NEW_DATA_ARCHIVING_DATE'') '          
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD         
      

    
    SELECT TOP 1 @NSLSMEMOLEN=  LEN(CM_NO) FROM CMM01106 (nolock) WHERE LEFT(CM_ID,len(@CLOCID))=@CLOCID
    ORDER BY CM_DT DESC, CM_ID DESC 
   
   

    
    IF ISNULL(@NSLSMEMOLEN,0)<>0
    SET @CCMD=N'UPDATE A SET VALUE=case when '''+@CLOCID+'''='''' then value else '''+RTRIM(LTRIM(STR(@NSLSMEMOLEN)))+''' end  FROM '+@CLOCDB+@CTABLENAME+' A WHERE CONFIG_OPTION=''SLS_MEMO_LEN'''          
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD 
    
        
          
    SET @NSTEP=306 
    SET @CTABLENAME='BIN'          
    SET @CCMD=N'SELECT DISTINCT  BIN.* INTO '+@CLOCDB+@CTABLENAME+' FROM BIN 
    JOIN BIN_LOC ON BIN.BIN_ID= BIN_LOC.BIN_ID'          
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
    
    
    SET @NSTEP=307
    SET @CTABLENAME='HSN_MST'          
    SET @CCMD=N'SELECT * INTO '+@CLOCDB+@CTABLENAME+' FROM '+@CTABLENAME+'
    UNION
    SELECT * FROM '+@CTABLENAME+' WHERE HSN_CODE LIKE ''000%'''
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          


    SET @NSTEP=308
    SET @CTABLENAME='HSN_DET'          
    SET @CCMD=N'SELECT * INTO '+@CLOCDB+@CTABLENAME+' FROM '+@CTABLENAME+'
    UNION
    SELECT * FROM '+@CTABLENAME+' WHERE HSN_CODE LIKE ''000%'''
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          


	SET @NSTEP=310          
    SET @CTABLENAME='UOM'          
    SET @CCMD=N'SELECT DISTINCT  UOM.* INTO '+@CLOCDB+@CTABLENAME+' FROM UOM '   
	 PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          

	
	SET @NSTEP=320          
    SET @CTABLENAME='emp_desig'          
    SET @CCMD=N'SELECT DISTINCT  emp_desig.* INTO '+@CLOCDB+@CTABLENAME+' FROM emp_desig '   
	 PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          



	SET @NSTEP=330          
    SET @CTABLENAME='EMP_SALARY_MST'          
    SET @CCMD=N'SELECT DISTINCT  EMP_SALARY_MST.* INTO '+@CLOCDB+@CTABLENAME+' FROM EMP_SALARY_MST '   
	 PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          


     
	SET @NSTEP=340          
    SET @CTABLENAME='EMP_MST'          
    SET @CCMD=N'SELECT DISTINCT  A.* INTO '+@CLOCDB+@CTABLENAME+' FROM EMP_MST a
	  JOIN           
    (          
     SELECT emp_ID FROM '+@CLOCDB+ 'EMP_ATTENDANCE    
	 group by emp_ID       
    ) B ON A.emp_id =B.emp_id  '   

    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD  

	SET @NSTEP=350          
    SET @CTABLENAME='emp_shifts'          
    SET @CCMD=N'SELECT DISTINCT  A.* INTO '+@CLOCDB+@CTABLENAME+' FROM emp_shifts a
	  JOIN           
    (          
     SELECT shift_id FROM '+@CLOCDB+ 'EMP_ATTENDANCE    
	 union
	 SELECT shift_id FROM '+@CLOCDB+ 'EMP_MST      
    ) B ON A.shift_id =B.shift_id  '   

    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD  


                     
    IF OBJECT_ID ('KEYS_CUSTOM','U') IS NOT NULL
	begin
		SET @CTABLENAME='KEYS_CUSTOM'          
		SET @CCMD=N'SELECT DISTINCT  KEYS_CUSTOM.* INTO '+@CLOCDB+@CTABLENAME+' FROM KEYS_CUSTOM where 1=2'          
		PRINT @CCMD      
		EXEC SP_EXECUTESQL @CCMD    

	end    
   
     SET @CTABLENAME='OPS01106'          
    SET @CCMD=N'SELECT DISTINCT  OPS01106.* INTO '+@CLOCDB+@CTABLENAME+' FROM OPS01106          
    WHERE ('''+@CLOCID+'''='''' or OPS01106.DEPT_ID='''+@CLOCID+''') '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD       
       

               
     SET @NSTEP=310          
     SET @CTABLENAME='PMT01106'          
     SET @CCMD=N'SELECT a.*
     INTO '+@CLOCDB+@CTABLENAME+' FROM   pmt01106  A where 1=2 '          
              
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD          
    
   --   SET @CCMD=N'alter table  '+@CLOCDB+@CTABLENAME+'  alter column dept_id char(2) not null '          
	  --PRINT @CCMD          
	  --EXEC SP_EXECUTESQL @CCMD    
	  
	  --SET @CCMD=N'alter table  '+@CLOCDB+@CTABLENAME+'  alter column bin_id varchar(7) not null '          
	  --PRINT @CCMD          
	  --EXEC SP_EXECUTESQL @CCMD             
          
     SET @NSTEP=320     
    IF @CCURDEPT_ID =@CHODEPT_ID 
    BEGIN      
    ---NOW WE UPDATE KEYS TABLES          
    IF OBJECT_ID ('TEMPDB..#TBLKEYS','U') IS NOT NULL          
    DROP TABLE #TBLKEYS          
    SELECT DISTINCT KEYS_TABLENAME INTO #TBLKEYS FROM KEYS_MIRROR_LOG 
    WHERE KEYS_TABLENAME NOT LIKE 'KEYS_CUSTOM%'         
              
    WHILE EXISTS (SELECT TOP 1 * FROM #TBLKEYS WHERE ISNULL(KEYS_TABLENAME,'') <> '')          
    BEGIN          
               
     SET @CTABLENAME=''          
               
     SELECT @CTABLENAME=KEYS_TABLENAME  FROM #TBLKEYS          
               
	  SET @CCMD=N' SELECT A.* INTO '+@CLOCDB+@CTABLENAME+' FROM KEYS (NOLOCK) A WHERE 1=2'          
	  PRINT @CCMD          
	  EXEC SP_EXECUTESQL @CCMD          
	            
	            
	  SET @CCMD=N'INSERT INTO '+@CLOCDB+@CTABLENAME+' (COLUMNNAME,PREFIX,FINYEAR,TABLENAME,LASTKEYVAL)           
				SELECT COLUMNNAME,PREFIX,FINYEAR,TABLENAME,LASTKEYVAL FROM KEYS_MIRROR_LOG           
				WHERE KEYS_TABLENAME='''+@CTABLENAME+''' AND DEPT_ID='''+@CLOCID+''' '          
	  PRINT @CCMD          
	  EXEC SP_EXECUTESQL @CCMD          
	            
	  DELETE FROM #TBLKEYS WHERE KEYS_TABLENAME=@CTABLENAME          
                    
              
    END  
    END
    else
    BEGIN
         IF OBJECT_ID ('TEMPDB..#TBLKEYS1','U') IS NOT NULL          
         DROP TABLE #TBLKEYS1       
        
        SELECT name into #TBLKEYS1 FROM SYS.TABLES WHERE NAME LIKE 'KEYS%'
        
     WHILE EXISTS (SELECT TOP 1 * FROM #TBLKEYS1)          
     BEGIN          
               
      SET @CTABLENAME=''                   
      SELECT top 1  @CTABLENAME=name  FROM #TBLKEYS1          
               
	  SET @CCMD=N' SELECT A.* INTO '+@CLOCDB+@CTABLENAME+' FROM '+@CTABLENAME+' a'          
	  PRINT @CCMD          
	  EXEC SP_EXECUTESQL @CCMD          
	            
	         
	  DELETE FROM #TBLKEYS1 WHERE name =@CTABLENAME          
                    
              
    END  
    
    END
    
    SET @NSTEP=330
    
		    
		----DECLARE @CCOLNAME VARCHAR(MAX),@CALIASCOLNAME VARCHAR(MAX)
		
		----SET @CTABLENAME='POM01106'
					
		----SELECT @CCOLNAME=ISNULL(@CCOLNAME+',','')+(NAME),
		----@CALIASCOLNAME=ISNULL(@CALIASCOLNAME+',','')+('A.'+NAME)
		----FROM SYS.COLUMNS 
		----WHERE OBJECT_NAME(OBJECT_ID)='POM01106'
		----and name <>'ts'
		----order by NAME
		----			--SELECT @CCOLNAME,@CALIASCOLNAME
				
		----SET @CCMD=N' insert '+@CLOCDB+@CTABLENAME+' ('+@CCOLNAME+')
		----SELECT '+@CALIASCOLNAME+' FROM POM01106 A 
		----LEFT JOIN '+@CLOCDB+@CTABLENAME+' B ON A.PO_ID=B.PO_ID
		----WHERE A.PO_FOR_DEPT_ID='''+@CLOCID+''' AND B.PO_ID IS NULL ' 
								
		----PRINT @cCmd			
		----EXEC SP_EXECUTESQL @CCMD
		
		
		----SET @CCOLNAME=NULL
		----SET @CALIASCOLNAME=NULL 
		----SET @CTABLENAME='POD01106'
		
		----SELECT @CCOLNAME=ISNULL(@CCOLNAME+',','')+(NAME),
		----@CALIASCOLNAME=ISNULL(@CALIASCOLNAME+',','')+('A.'+NAME)
		----FROM SYS.COLUMNS 
		----WHERE OBJECT_NAME(OBJECT_ID)='POD01106'
		----and name <>'ts'
		----order by NAME
		----			--SELECT @CCOLNAME,@CALIASCOLNAME
				
		----SET @CCMD=N' insert '+@CLOCDB+@CTABLENAME+' ('+@CCOLNAME+')
		----SELECT '+@CALIASCOLNAME+' FROM POD01106 A 
		----JOIN POM01106 POM  ON A.PO_ID=POM.PO_ID
		----LEFT JOIN '+@CLOCDB+@CTABLENAME+' B ON A.PO_ID=B.PO_ID
		----WHERE POM.PO_FOR_DEPT_ID='''+@CLOCID+'''  AND B.PO_ID IS NULL ' 
								
		----PRINT @cCmd			
		----EXEC SP_EXECUTESQL @CCMD


   SET @NSTEP=340
		
	DECLARE @CSOURCEIMAGEDBNAME VARCHAR(100),@DTSQL NVARCHAR(MAX),@CimgTABLENAME VARCHAR(100),@CTARGETIMAGEDB VARCHAR(100),
	 @CimginfodocTABLENAME VARCHAR(100),@CimginforefTABLENAME VARCHAR(100)

	SET @CSOURCEIMAGEDBNAME =DB_NAME()+'_IMAGE.DBO.'
	SET @CimgTABLENAME='IMAGE_INFO'
	SET @CTARGETIMAGEDB=@CNEWDBNAME+'_image.DBO.'     

	

    
	SET @DTSQL='IF OBJECT_ID ('''+@CSOURCEIMAGEDBNAME+@CimgTABLENAME+''',''U'') IS NOT NULL 
	BEGIN
	     IF OBJECT_ID ('''+@CTARGETIMAGEDB+@CimgTABLENAME+''',''U'') IS  NULL 
		BEGIN
	
	         SELECT DISTINCT  * INTO '+@CTARGETIMAGEDB+@CimgTABLENAME+' FROM '+@CSOURCEIMAGEDBNAME+@CimgTABLENAME+' where dept_id='''+@CLOCID+'''
	
		END
	
	END '
	PRINT  @DTSQL
	EXEC SP_EXECUTESQL @DTSQL

	SET @NSTEP=350

	set @CimginfodocTABLENAME='IMAGE_INFO_DOC'

	SET @DTSQL='IF OBJECT_ID ('''+@CSOURCEIMAGEDBNAME+@CimginfodocTABLENAME+''',''U'') IS NOT NULL 
	BEGIN
	   	
		 IF OBJECT_ID ('''+@CTARGETIMAGEDB+@CimginfodocTABLENAME+''',''U'') IS  NULL 
		BEGIN
	
	         SELECT DISTINCT  * INTO '+@CTARGETIMAGEDB+@CimginfodocTABLENAME+' FROM '+@CSOURCEIMAGEDBNAME+@CimginfodocTABLENAME+' where dept_id='''+@CLOCID+'''
	
		END
	
	END '
	PRINT  @DTSQL
	EXEC SP_EXECUTESQL @DTSQL

	SET @NSTEP=360

	

	set @CimginforefTABLENAME='IMAGE_INFO_REF'

	SET @DTSQL='IF OBJECT_ID ('''+@CSOURCEIMAGEDBNAME+@CimginforefTABLENAME+''',''U'') IS NOT NULL 
	BEGIN
	   	
		 IF OBJECT_ID ('''+@CTARGETIMAGEDB+@CimginforefTABLENAME+''',''U'') IS  NULL 
		BEGIN
	
	         SELECT DISTINCT  a.* INTO '+@CTARGETIMAGEDB+@CimginforefTABLENAME+' FROM '+@CSOURCEIMAGEDBNAME+@CimginforefTABLENAME+' a
			 JOIN '+@CTARGETIMAGEDB+@CimgTABLENAME+' B ON A.IMG_ID=B.IMG_ID
	
		END
	
	END '
	PRINT  @DTSQL
	EXEC SP_EXECUTESQL @DTSQL
	
		
              
    END TRY          
    BEGIN CATCH          
    SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()            
    GOTO END_PROC          
    END CATCH          
              
    END_PROC:          
 IF @@TRANCOUNT>0            
 BEGIN            
               
 IF ISNULL(@CERRORMSG,'')=''          
 BEGIN            
    commit TRANSACTION            
 END            
 ELSE            
    ROLLBACK            
 END            
     
     
       ---
    
    ---
    IF ISNULL(@CERRORMSG,'')='' 
    BEGIN

	SET @CTABLENAME='EXE_TIME'          
    SET @CCMD=N'SELECT CAST(''2020-01-01'' AS DATETIME) AS last_update,CAST(''2020-01-01'' AS DATETIME) AS LATEST_EXE_TIME INTO '+@CLOCDB+@CTABLENAME+'  '          
    PRINT @CCMD          
    EXEC SP_EXECUTESQL @CCMD 

	
     DECLARE @SQL NVARCHAR(MAX)
		     
	 DECLARE @Definition TABLE(DefinitionID SMALLINT IDENTITY(1,1)
                                        ,FieldValue VARCHAR(MAX),TABLENAME VARCHAR(100))
                                               
		SET @SQL=N'SELECT name
				, ''SELECT * INTO '' + '''+@CLOCDB+''' +name +'' FROM ''+name+''''
		           FROM SYS.tables 
		           WHERE TYPE=''U''
				         AND name NOT LIKE ''TMP%''
				         AND name NOT LIKE ''TEMP%''
				         AND name NOT LIKE ''KEYS_%''
				         AND NAME NOT IN(SELECT NAME FROM '+@CNEWDBNAME+'.SYS.OBJECTS)
				         AND name NOT LIKE ''MASTER..%''
						 '
		PRINT 'EDT '+CHAR(13)+@SQL
		INSERT INTO @Definition(TABLENAME,FieldValue)
        exec sp_executesql @sql
        
         if OBJECT_ID ('tempdb..#tmpTABLE','u') is not null
           drop table #tmpTABLE
        
        select * into #tmpTABLE from @Definition
        
        declare @TABLENAME varchar(2000)
        
        while exists(select top 1 'u' from #tmpTABLE)  
        begin
           
           set @TABLENAME=''
           set @ccmd=''
           
             select top 1 @TABLENAME=TABLENAME ,@ccmd=FieldValue from #tmpTABLE
             order by DefinitionID
             
             if @TABLENAME in('ARTICLE_FIX_ATTR','image_info_config','XNS_UPLOAD_COLS','TDS_Section') or (LEFT(@TABLENAME,4)='ATTR' AND RIGHT(@TABLENAME,4)='_MST')
             begin
                  
                SET @CWHERECLAUSE=' WHERE 1=1'
                
             end
             else
             begin
             
                SET @CWHERECLAUSE=' WHERE 1=2'
             
             end
        
            SET @SQL=N'
            if not exists (select top 1 ''u'' from  ['+@CNEWDBNAME+'].SYS.objects where name='''+@TABLENAME+''') 
            begin
               '+@ccmd+''+@CWHERECLAUSE+'
            end '
            print @sql
            exec sp_executesql @sql
           
            delete from #tmpTABLE where TABLENAME=@TABLENAME
        
        end
        
      DECLARE @Definition1 TABLE(TABLENAME VARCHAR(100))
      
      SET @SQL=N'SELECT name FROM '+@CNEWDBNAME+'.INFORMATION_SCHEMA .COLUMNS   a
				   JOIN sys.tables B ON TABLE_NAME =B.name 
		           WHERE TYPE=''U'' AND name NOT LIKE ''TMP%''
				   AND name NOT LIKE ''TEMP%'' AND name NOT LIKE ''KEYS_%''
				   AND name NOT LIKE ''MASTER..%''
				   AND NAME NOT IN(''EXE_TIME'')
			       and right(name,7) not in(''_mirror'',''_Upload'')
				   and a.column_name in(''Ho_synch_last_update'')
					GROUP BY name	 '
		PRINT 'EDT '+CHAR(13)+@SQL
		INSERT INTO @Definition1(TABLENAME)
        exec sp_executesql @sql
        
        select * into #tmporgtable from @Definition1
		declare @corgtablename varchar(1000)
		
		while exists (select top 1 'U' from #tmporgtable)
		begin
		    
			select top 1  @ctablename=TABLENAME from #tmporgtable

		     SET @SQL=N' Update a set Ho_synch_last_update=last_update  from '+@CNEWDBNAME+'.dbo.'+@ctablename+' a '
			 print @SQL
			 exec sp_executesql @SQL

			 delete  from #tmporgtable where TABLENAME=@ctablename
		end
        
    
        
   -- EXEC COPYPROCEDURES @CNEWDBNAME
        
    EXEC SP3S_CRT_CONSTRAINT @CNEWDBNAME    

	SET @CIMAGEDBNAME=@CNEWDBNAME+'_IMAGE'

	
	insert into #tmpdbname(DBName,FileLocation)
		SELECT db.name AS DBName,
			   REPLACE(PHYSICAL_NAME,'.MDF','.BAK') AS FileLocation
		FROM sys.master_files mf
		INNER JOIN sys.databases db ON db.database_id = mf.database_id
		where(  db.name =@CNEWDBNAME or db.name=@CIMAGEDBNAME) AND FILE_ID =1

  --SET @SQL=N' ALTER DATABASE ['+@CNEWDBNAME+'] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE '
  --print @SQL
  --exec sp_executesql @SQL
        SET @CBACKUPDB=@CDBPATHOUT+'\'+@CNEWDBNAME+'.BAK'

        SET @CCMD = N' BACKUP DATABASE ' + @CNEWDBNAME + ' TO DISK = N''' + @CBACKUPDB +''' WITH INIT'--OverWrite
		PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD
		
		 SET @CBACKUPDB=@CDBPATHOUT+'\'+@CIMAGEDBNAME+'.BAK'
		
		SET @CCMD = N' BACKUP DATABASE ' + @CIMAGEDBNAME + ' TO DISK = N''' + @CBACKUPDB +''' WITH INIT'--OverWrite
		PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD
		
		SET @CCMD = N' DROP DATABASE ' + @CNEWDBNAME + ''
		PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD
		
		SET @CCMD = N' DROP DATABASE ' + @CIMAGEDBNAME + ''
		PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD
	  
  --      EXEC MASTER.dbo.sp_detach_db @dbname =@CNEWDBNAME
		--EXEC MASTER.dbo.sp_detach_db @dbname =@CIMAGEDBNAME


   END   
   
   if exists (select top 1'u' from #tmpdbname)
      SELECT  @CERRORMSG AS errmsg, dbName,fileLocation
	  FROM #TMPDBNAME 
   else 
	 SELECT  @CERRORMSG AS errmsg,cast('' as varchar(100)) dbName,cast('' as varchar(100)) fileLocation

   
              
          
END     
