CREATE PROC SP_INSERT_XFERLOG
--WITH ENCRYPTION
AS
BEGIN
BEGIN TRY
	DECLARE @XN_TYPE VARCHAR(50),@T_NAME VARCHAR(50),@P_COLUMN VARCHAR(50),@D_COLUMN VARCHAR(50),
			@ORDERED INT, @QRY NVARCHAR(MAX) ,@CCURLOCID VARCHAR(10),@CHOLOCID VARCHAR(10),
			@CINXXNTYPE VARCHAR(10)

	DECLARE @TEMP_TABLE TABLE (XN_NAME VARCHAR(50),T_NAME VARCHAR(50),P_COLUMN VARCHAR(50),D_COLUMN VARCHAR(50),ORDERED INT,ID INT IDENTITY(1,1))

	SELECT TOP 1 @CCURLOCID = [VALUE] FROM CONFIG WHERE CONFIG_OPTION = 'LOCATION_ID'            
    SELECT TOP 1 @CHOLOCID = [VALUE] FROM CONFIG WHERE CONFIG_OPTION = 'HO_LOCATION_ID'    
	
	IF @CCURLOCID=@CHOLOCID
		RETURN
		 
	INSERT INTO @TEMP_TABLE (XN_NAME,T_NAME,P_COLUMN ,D_COLUMN ,ORDERED )
	SELECT 'PO','POM01106','PO_ID','PO_DT',20 UNION         
	SELECT 'PUR','PIM01106','MRR_ID','RECEIPT_DT',40 UNION 
	SELECT 'PBG','PBM01106','MEMO_ID','BILL_DT',50   UNION 
	SELECT 'SCF','SCM01106','MEMO_ID','MEMO_DT',60 UNION 
	SELECT 'IRR','IRM01106','IRM_MEMO_ID','IRM_MEMO_DT',70 UNION 
	SELECT 'APP','APM01106','MEMO_ID','MEMO_DT',80 UNION 
	SELECT 'APR','APPROVAL_RETURN_MST','MEMO_ID','MEMO_DT',90 UNION 
	SELECT 'RPS','RPS_MST','CM_ID','CM_DT',110 UNION 
	SELECT 'SLS','CMM01106','CM_ID','CM_DT',120 UNION 
	SELECT 'ARC','ARC01106','ADV_REC_ID','ADV_REC_DT',125 UNION 
	SELECT 'PTC','PEM01106','PEM_MEMO_ID','PEM_MEMO_DT',130 UNION 
	SELECT 'PRT','RMM01106','RM_ID','RM_DT',150  UNION 
	SELECT 'WSLORD','WSL_ORDER_MST','ORDER_ID','ORDER_DT',160 UNION 
	SELECT 'WPS','WPS_MST','PS_ID','PS_DT',170 UNION 
	SELECT 'WSL','INM01106','INV_ID','INV_DT',180 UNION 
	SELECT 'WSR','CNM01106','CN_ID','CN_DT',190 UNION   
	SELECT 'ACT','VM01106','VM_ID','VOUCHER_DT',220 UNION 
	SELECT 'ATD','EMP_WPAYATT','ROW_ID','IST_TIME',230 UNION 
	SELECT 'CNC','ICM01106','CNC_MEMO_ID','CNC_MEMO_DT',240   UNION 
	SELECT 'POADJ','PO_ADJ_MST','MEMO_ID','MEMO_DT',250 UNION 
	SELECT 'CUS','CUSTDYM','CUSTOMER_CODE','LAST_UPDATE',260  

	
	IF CURSOR_STATUS('GLOBAL','CURR_MIRROR') IN (0,1)  
	BEGIN  
	  CLOSE CURR_MIRROR  
	  DEALLOCATE CURR_MIRROR  
	END

	BEGIN TRAN
	
	DECLARE CURR_MIRROR CURSOR FOR SELECT XN_NAME,T_NAME,P_COLUMN,D_COLUMN,ORDERED FROM @TEMP_TABLE ORDER BY ID
	OPEN CURR_MIRROR 
	FETCH NEXT FROM CURR_MIRROR INTO @XN_TYPE ,@T_NAME ,@P_COLUMN ,@D_COLUMN,@ORDERED
	WHILE @@FETCH_STATUS=0  
	BEGIN
		SET @CINXXNTYPE='XNS'+@XN_TYPE
		SET @QRY = N'UPDATE B  SET LAST_UPDATE=A.LAST_UPDATE FROM XFERLOG B
					JOIN  '+@T_NAME+' A ON A.'+@P_COLUMN+'=B.XN_ID AND B.XN_TYPE='''+@CINXXNTYPE+'''
					WHERE A.'+@D_COLUMN+' < CONVERT(VARCHAR,DATEADD(DAY,-15,GETDATE()),110) AND 
					B.LAST_UPDATE<>A.LAST_UPDATE '+
					(CASE WHEN @XN_TYPE='PUR' THEN ' AND (A.INV_MODE<>2 OR A.RECEIPT_DT<>'''')' ELSE '' END)+ 
					(CASE WHEN @XN_TYPE='WSR' THEN ' AND (A.MODE<>2 OR A.RECEIPT_DT<>'''')' ELSE '' END)
					
		PRINT @QRY            
		EXEC SP_EXECUTESQL @QRY 

		SET @QRY = N'INSERT INTO XFERLOG  (XN_TYPE,XN_ID,LAST_UPDATE)
					SELECT '''+@CINXXNTYPE+''' AS XN_TYPE,A.'+@P_COLUMN+' AS XN_ID ,A.LAST_UPDATE FROM 
					'+@T_NAME+' A LEFT OUTER JOIN XFERLOG B ON A.'+@P_COLUMN+'=B.XN_ID AND B.XN_TYPE='''+@CINXXNTYPE+'''
					WHERE A.'+@D_COLUMN+' < CONVERT(VARCHAR,DATEADD(DAY,-15,GETDATE()),110) AND B.XN_ID IS NULL'+
					(CASE WHEN @XN_TYPE='PUR' THEN ' AND (A.INV_MODE<>2 OR A.RECEIPT_DT<>'''')' ELSE '' END)+ 
					(CASE WHEN @XN_TYPE='WSR' THEN ' AND (A.MODE<>2 OR A.RECEIPT_DT<>'''')' ELSE '' END)
					
		PRINT @QRY            
		EXEC SP_EXECUTESQL @QRY		
		FETCH NEXT FROM CURR_MIRROR INTO @XN_TYPE ,@T_NAME ,@P_COLUMN ,@D_COLUMN,@ORDERED   
	END
	CLOSE CURR_MIRROR 
	DEALLOCATE CURR_MIRROR 
	COMMIT
	SELECT '' AS ERRMSG
END TRY

BEGIN CATCH
	ROLLBACK
	SELECT ERROR_MESSAGE () AS ERRMSG
END CATCH

END
