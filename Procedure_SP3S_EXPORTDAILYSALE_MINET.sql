CREATE Procedure SP3S_EXPORTDAILYSALE_MINET--(LocId 3 digit change by Sanjay:05-11-2024)
(
 @SALE_DATE DATE='',
 @LOC varchar(4)=''
)  
as
Begin
    
	        DECLARE  @SHOP_NMBR VARCHAR(20),@POS_NMBR VARCHAR(10),@RECEIPT_NMBR VARCHAR(10),@TRAN_FILE_NMBR INT          
			,@DATE CHAR(8),@TIME CHAR(8),@USER_ID VARCHAR(10),@SHIFT_NMBR INT,@TRAN_TYPE VARCHAR(10),@SALEDATE DATE,@CMID VARCHAR(100)          
			,@DISC_AMT FLOAT,@ITEM_NSALE FLOAT,@ITEM_STAX FLOAT,@TAX FLOAT          
			,@TENDER_TYPE CHAR(1),@TENDER_AMOUNT FLOAT,@TENDER_AMOUNT_CONV FLOAT,@TAX_TYPE VARCHAR(1),@REF_RECPT VARCHAR(100) 
			,@LINE_ITEMS VARCHAR(MAX),@ID_VALUE INT  ,@LEASEID VARCHAR(100),@POS varchar(10) ,@SALETIME VARCHAR(100) 
			,@nSr Numeric(5,2),@DEPT varchar(200)


			select SrNo=cast(0 as numeric(5,2)),
			       LINE_ITEMS=cast('' as varchar(max))
				into #tmpLINE_ITEMS
			where 1=2 

	
			IF OBJECT_ID('IDOC_GEN','U') IS NOT NULL
			BEGIN
						IF EXISTS(SELECT TOP 1'U' FROM IDOC_GEN (NOLOCK) WHERE DEPT_ID=@LOC AND POS_NMBR=@POS)          
						   SELECT @ID_VALUE=MAX(CAST(SNO AS INT)) FROM IDOC_GEN (NOLOCK) WHERE DEPT_ID=@LOC AND POS_NMBR=@POS          
						ELSE          
						   SET @ID_VALUE=0  
			END
		   Else
			  SET @ID_VALUE=0  

           SELECT @LEASEID=VALUE  FROM CONFIG WHERE CONFIG_OPTION='TENANTID'
		   set @TENDER_TYPE='T'

		IF @ID_VALUE=9999          
           SET @ID_VALUE=0  
         if ISNULL (@LEASEID,'')=''          
         SET @LEASEID='TENANTID'   
         SET @POS='T0'+@LOC   
		 set @TRAN_FILE_NMBR=@ID_VALUE+1   


		SELECT @SHOP_NMBR=@LEASEID,@POS_NMBR=@POS
		SELECT @DATE=CONVERT(VARCHAR,GETDATE(),112),@TIME=CONVERT(VARCHAR,GETDATE(),108)   
		
		SELECT @RECEIPT_NMBR=MIN(CM_NO) FROM CMM01106 WHERE location_code=@LOC AND CM_DT=@SALE_DATE  
		
		SET @LINE_ITEMS='1|OPENED|'+ISNULL(@SHOP_NMBR,'')+'|'+ltrim(rtrim(ISNULL(@POS_NMBR,'')))+'|'              
		+ltrim(rtrim(ISNULL(@RECEIPT_NMBR,'')))+'|'              
		+CAST(ISNULL(@TRAN_FILE_NMBR,0) AS VARCHAR)+'|'              
		+@DATE+'|'+@TIME+'|'+'MANAGER'+'|'+CONVERT(VARCHAR,@SALE_DATE,112) 
		
	
		set @nSr=1

		INSERT INTO #TMPLINE_ITEMS(SrNo,LINE_ITEMS)
		SELECT @NSR,@LINE_ITEMS

	    set @LINE_ITEMS=''
		
		
		
	    DECLARE TR CURSOR FOR          
	    
		SELECT CM_ID,CM_NO RECEIPT_NUMBER,CM_DT [SALEDATE],CONVERT(VARCHAR,CM_TIME,108)SALETIME,'SALE'TRANSTAT,REF_CM_ID          
		FROM CMM01106 (NOLOCK) WHERE location_code=@LOC AND CM_DT=@SALE_DATE  AND CANCELLED=0          
		OPEN TR          
		FETCH NEXT FROM TR INTO @CMID,@RECEIPT_NMBR,@SALEDATE,@SALETIME,@TRAN_TYPE,@REF_RECPT          
		WHILE @@FETCH_STATUS=0          
		BEGIN          
			--CMD_CODE=101   
			SET @NSR=@NSR+1
			SET @LINE_ITEMS='101|'+@RECEIPT_NMBR+'|'          
			+'01'+'|'--SHIFT NUMBER          
			+CONVERT(VARCHAR,@SALEDATE,112)+'|'          
			+@SALETIME+'|'--TIME          
			+'MANAGER'+'|'--USER ID          
			+''+'|'--MANUAL RECEIPT          
			+CASE @TRAN_TYPE WHEN 'SALE' THEN '' ELSE 'R' END+'|'--REFUND          
			+''+'|'--REASON CODE          
			+''+'|'--SALESMAN CODE          
			+''+'|'--TABLE NMBR          
			+''+'|'--CUST COUNT          
			+'N'+'|'--TRAINING          
			+ISNULL(@TRAN_TYPE,'')          
			
			INSERT INTO #TMPLINE_ITEMS(SrNo,LINE_ITEMS)
		    SELECT @NSR,@LINE_ITEMS
            
			SET @NSR=@NSR+.1
   
        INSERT INTO #TMPLINE_ITEMS(SrNo,LINE_ITEMS)
		SELECT @NSR SRNO,
			 LINE_ITEMS='111|'          
			+ISNULL(C.PRODUCT_CODE,'')+'|'          
			+CAST(ISNULL(C.QUANTITY,0) AS VARCHAR)+'|'          
			+CAST(ISNULL(C.MRP,0) AS VARCHAR)+'|'      
			+CAST(ISNULL(C.MRP,0) AS VARCHAR)+'|'          
			+''+'|'          
			+'G'+'|'--TAXCODE          
			+''+'|'--DISC CODE          
			+CAST(ISNULL(C.DISCOUNT_AMOUNT,0) AS VARCHAR)+'|'          
			+ISNULL(SECTION_NAME,'')+'|'--ITEM DEPT          
			+ISNULL(SUB_SECTION_NAME,'')+'|'--ITEM CATG          
			+''+'|'--LABEL KEYS          
			+''+'|'--ITEM COMM          
			+CAST(ISNULL(C.XN_VALUE_WITH_GST,0) AS VARCHAR)+'|' --ITEM_NSALES         
			+CAST(ISNULL(C.DISCOUNT_AMOUNT,0) AS VARCHAR)+'|'    --DISCOUNT_BY      
			+'$'+'|'--DISC SIGN          
			+CAST(ISNULL(IGST_AMOUNT+CGST_AMOUNT+SGST_AMOUNT,0) AS VARCHAR)+'|'  --ITEM_STAX        
			+''+'|'
			FROM CMD01106 C (NOLOCK)
			JOIN SKU_NAMES SN (NOLOCK) ON SN.PRODUCT_CODE=C.PRODUCT_CODE 
			WHERE CM_ID=@CMID 

			SET @NSR=@NSR+.1
              
	    INSERT INTO #TMPLINE_ITEMS(SrNo,LINE_ITEMS)
		select SRNO=@NSR , 
		     LINE_ITEMS='121|'          
			+CAST(SUM(QUANTITY*MRP) AS VARCHAR)+'|'          
			+CAST(SUM(ISNULL(CMM_DISCOUNT_AMOUNT,0)+ISNULL(DISCOUNT_AMOUNT,0)) AS VARCHAR)+'|'          
			+''+'|'--CESS          
			+''+'|'--CHARGES          
			+CAST(SUM(ISNULL(IGST_AMOUNT,0)+ISNULL(CGST_AMOUNT,0)+ISNULL(SGST_AMOUNT,0)) AS VARCHAR)+'|'          
			+ISNULL(CASE TAX_METHOD WHEN 2 THEN 'E' ELSE 'I' END,'') +'|'--TAX_TYPE=I/E          
			+'Y'+'|'--EXECPT GST          
			+''+'|'--DISCOUNT CODE          
			+''+'|'--OTHER CHARGES          
			+''+'|'--DISCOUNT PER          
		FROM CMD01106(NOLOCK) WHERE CM_ID=@CMID          
		GROUP BY TAX_METHOD               
           		 
		SET @NSR=@NSR+.1

		INSERT INTO #TMPLINE_ITEMS(SrNo,LINE_ITEMS)
		select SRNO=@NSR ,   LINE_ITEMS='131|'          
				+ISNULL(@TENDER_TYPE,'')+'|'          
				+(CASE WHEN PAYMODE_NAME='CREDIT ISSUED' THEN '' ELSE 
				(CASE PAYMODE_GRP_CODE WHEN '0000002'  THEN 'CARD' ELSE 'CASH' END)  END) +'|'--PAYMENT NAME          
				+'S$'+'|'--CURR CODE          
				+''+'|'--BUY RATE          
				+CAST(ISNULL(AMOUNT,0) AS VARCHAR)+'|'          
				+''+'|'--REMARKS1          
				+''+'|'--REMARKS2          
				+''+'|'--REMARKS3          
				+CAST(ISNULL((AMOUNT*XD.CURRENCY_CONVERSION_RATE),0) AS VARCHAR)          
			FROM PAYMODE_XN_DET XD(NOLOCK) JOIN PAYMODE_MST PM (NOLOCK) ON PM.PAYMODE_CODE=XD.PAYMODE_CODE      
		    WHERE MEMO_ID=@CMID  AND XN_TYPE='SLS'    
			

			set @NSR=round(@NSR,0)

		FETCH NEXT FROM TR INTO @CMID,@RECEIPT_NMBR,@SALEDATE,@SALETIME,@TRAN_TYPE,@REF_RECPT          
	  END          
	  CLOSE TR          
	  DEALLOCATE TR          
      
	 set @NSR= @NSR+1

	SELECT @SHOP_NMBR=@LEASEID,@POS_NMBR=@POS,@TRAN_FILE_NMBR=@ID_VALUE+1,@USER_ID=''          
	SELECT @DATE=CONVERT(VARCHAR,GETDATE(),112),@TIME=CONVERT(VARCHAR,GETDATE(),108)          
          
	SELECT @RECEIPT_NMBR=MAX(CM_NO) FROM CMM01106 WHERE location_code=@LOC AND CM_DT=@SALE_DATE 
	
	INSERT INTO #TMPLINE_ITEMS(SrNo,LINE_ITEMS)
    select SRNO=@NSR ,
	 LINE_ITEMS='1|CLOSED|'          
	+ISNULL(@SHOP_NMBR,'')+'|'          
	+ISNULL(@POS_NMBR,'')+'|'          
	+ISNULL(@RECEIPT_NMBR,'')+'|'          
	+CAST(ISNULL(@TRAN_FILE_NMBR,0) AS VARCHAR)+'|'          
	+@DATE+'|'          
	+@TIME+'|'          
	+'MANAGER'+'|'          
	+CONVERT(VARCHAR,@SALE_DATE,112)          
	
	
	if object_id('IDOC_GEN','U') is not null
	begin

		IF NOT EXISTS(SELECT * FROM IDOC_GEN WHERE DEPT_ID=@LOC AND POS_NMBR=@POS)          
		   INSERT IDOC_GEN SELECT @LOC,@LEASEID,@POS,@ID_VALUE+1          
		ELSE              
		   UPDATE IDOC_GEN SET SNO=@ID_VALUE+1 WHERE DEPT_ID=@LOC AND POS_NMBR=@POS          
		

	end
      

	 select LINE_ITEMS from #tmpLINE_ITEMS
	 order by SrNO 

		
   

end