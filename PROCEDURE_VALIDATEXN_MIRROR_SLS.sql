CREATE PROCEDURE VALIDATEXN_MIRROR_SLS  
 @CLOCID VARCHAR(10),
 @CXNID VARCHAR(50),   
 @CMERGEDB VARCHAR(100),
 @CERRORMSG VARCHAR(MAX) OUTPUT  
-- WITH ENCRYPTION
AS  
BEGIN  
	 DECLARE @NCMDGROSS NUMERIC(10,2),@NCMDNET NUMERIC (10,2), @NCMDTOT NUMERIC (10,2),  
		@NCMDDISC NUMERIC (10,2),@NCMMDISC NUMERIC (10,2),@NCMMNET NUMERIC (10,2),  
		@NCMMSTOT NUMERIC(10,2),@LCANCELLED BIT,@NCMMODE NUMERIC(1), @NCMMDISCPER NUMERIC (10,3),@CCMMCC CHAR(2),  
		@NCMDNETWOTAX NUMERIC (10,2), @NCMDEXCLTAX NUMERIC(10,2), @NCALCDISCOUNTAMT NUMERIC(14,2),@NDISCOUNTAMT NUMERIC(14,2),  
		@NPAYMODECRAMT NUMERIC(10,2), @NPAYMODETOTAMT NUMERIC(10,2),@CITEMNAME VARCHAR(100),@NATDCHARGES NUMERIC(10,2),
		@CERRITEMCODE VARCHAR(50),@NMINPRICE NUMERIC(10,2),@NITEMNET NUMERIC(10,2),@DTSQLERRORMSG VARCHAR(MAX) ,
		@DTSQL NVARCHAR(MAX),@NTOTAMOUNT NUMERIC(14,2),@NGROSSVAL NUMERIC(10,2),@CCHK_TABLE VARCHAR(50)   

	 SET @CERRORMSG=''
	 	
	 DECLARE @TCMMTABLE TABLE (CM_ID VARCHAR(22),CM_MODE NUMERIC (5,0),DISCOUNT_PERCENTAGE NUMERIC (7,3),
			 DISCOUNT_AMOUNT NUMERIC (10,2),NET_AMOUNT NUMERIC (10,2),ATD_CHARGES NUMERIC (10,2), ROUND_OFF NUMERIC (10,2), 
			 CUSTOMER_CODE CHAR(12), CM_NO CHAR(15),SUBTOTAL NUMERIC(10,2), FIN_YEAR VARCHAR(10),
			 CM_DT DATETIME,USER_CODE CHAR(7),AC_CODE CHAR(10),MANUAL_DISCOUNT BIT ,SUBTOTAL_R NUMERIC(10,2) )  
	    
	
	  
	 DECLARE @TCMDTABLE TABLE (CM_ID VARCHAR(22),PRODUCT_CODE VARCHAR(50),QUANTITY NUMERIC(10,3),MRP NUMERIC (10,2),NET NUMERIC (10,2),  
			  DISCOUNT_PERCENTAGE NUMERIC(7,3), DISCOUNT_AMOUNT NUMERIC (10,2),RFNET NUMERIC (10,2),  
			  TAX_AMOUNT NUMERIC(10,2), TAX_METHOD NUMERIC(1),MANUAL_DISCOUNT BIT )  
			  
	 
	 PRINT 'VALIDATEXN-1'
	 DECLARE @TPAYMODETABLE TABLE ( PAYMODE_GRP_CODE CHAR(7), PAYMODE_CODE CHAR(7), AMOUNT NUMERIC(10,2)  ) 
	 DECLARE @ERRMSS VARCHAR(MAX)
	 
	 IF OBJECT_ID('#ERROR','U') IS NOT NULL
		DROP TABLE #ERROR
	
	 SELECT @ERRMSS AS ERRMSS INTO #ERROR	
	 	     
	 SET @DTSQL = N'IF EXISTS (SELECT RFNET,CMM_DISCOUNT_AMOUNT CM_ID FROM  '+@CMERGEDB+'CMD01106  
	                WHERE CM_ID = '''+@CXNID+''' AND  (RFNET IS NULL OR CMM_DISCOUNT_AMOUNT IS NULL ) )
	                INSERT INTO #ERROR
	                EXEC '+@CMERGEDB+'SP_CMM_CAL_SUBTOTAL '''+@CXNID+''',1 '
	 EXEC SP_EXECUTESQL @DTSQL	     
	 	     
	 SET @DTSQL=N'SELECT CM_ID, CM_MODE, DISCOUNT_PERCENTAGE, DISCOUNT_AMOUNT, NET_AMOUNT,ATD_CHARGES , ROUND_OFF , 
				 CUSTOMER_CODE, CM_NO, SUBTOTAL, FIN_YEAR, CM_DT,USER_CODE AS EDT_USER_CODE, AC_CODE,MANUAL_DISCOUNT,SUBTOTAL_R
				 FROM  '+@CMERGEDB+'CMM01106 (NOLOCK) WHERE CM_ID='''+@CXNID+'''' 
	  
	 INSERT @TCMMTABLE
	 EXEC SP_EXECUTESQL @DTSQL 
	 
	 PRINT 'VALIDATEXN-2'
	 SET @DTSQL=N'SELECT CM_ID,PRODUCT_CODE,QUANTITY,MRP,NET, DISCOUNT_PERCENTAGE, DISCOUNT_AMOUNT, RFNET, 
				 TAX_AMOUNT, TAX_METHOD  ,MANUAL_DISCOUNT
				 FROM  '+@CMERGEDB+'CMD01106 (NOLOCK) WHERE CM_ID='''+@CXNID+''''  
	 
	 INSERT @TCMDTABLE  
	 EXEC SP_EXECUTESQL @DTSQL 
	 
	 PRINT 'VALIDATEXN-3'
	 SET @DTSQL=N'SELECT B.PAYMODE_GRP_CODE, A.PAYMODE_CODE, A.AMOUNT FROM  '+@CMERGEDB+'PAYMODE_XN_DET A  (NOLOCK)  
				 JOIN  '+@CMERGEDB+'PAYMODE_MST B (NOLOCK) ON A.PAYMODE_CODE = B.PAYMODE_CODE  
				 WHERE MEMO_ID = '''+@CXNID+''' AND XN_TYPE = ''SLS'''  
	 
	 INSERT @TPAYMODETABLE  	 
	 EXEC SP_EXECUTESQL @DTSQL 
	 
	 PRINT 'VALIDATEXN-4' 
	 SET @DTSQL=N'IF EXISTS (SELECT TOP 1 A.CUSTOMER_CODE FROM  '+@CMERGEDB+'CMM01106 A
							LEFT OUTER JOIN  '+@CMERGEDB+'CUSTDYM B ON A.CUSTOMER_CODE=B.CUSTOMER_CODE
							WHERE A.CM_ID='''+@CXNID+''' AND A.PARTY_TYPE<>2 AND A.CUSTOMER_CODE<>''000000000000'' AND B.CUSTOMER_CODE IS NULL)
					SET @CERRORMSGOUT=''INVALID CUSTOMER DETAILS FOUND''
				 ELSE
					SET @CERRORMSGOUT='''''	
					
	 EXEC SP_EXECUTESQL @DTSQL,N'@CERRORMSGOUT VARCHAR(200) OUTPUT',@CERRORMSGOUT=@CERRORMSG OUTPUT
	 
	 PRINT 'VALIDATEXN-5'
	 IF ISNULL(@CERRORMSG,'')=''
	 BEGIN
		 SET @DTSQL=N'IF EXISTS (SELECT TOP 1 A.CUSTOMER_CODE FROM  '+@CMERGEDB+'CMM01106 A
								LEFT OUTER JOIN  '+@CMERGEDB+'LM01106 B ON A.AC_CODE=B.AC_CODE
								WHERE A.CM_ID='''+@CXNID+''' AND A.PARTY_TYPE=2 AND B.AC_CODE IS NULL)
						SET @CERRORMSGOUT=''INVALID LEDGER DETAILS FOUND''
					 ELSE
						SET @CERRORMSGOUT='''''	
						
		 EXEC SP_EXECUTESQL @DTSQL,N'@CERRORMSGOUT VARCHAR(200) OUTPUT',@CERRORMSGOUT=@CERRORMSG OUTPUT
	 END
	 
	 PRINT 'VALIDATEXN-6'
 	 IF ISNULL(@CERRORMSG,'')=''
	 BEGIN
		 SET @CCHK_TABLE=' '+@CMERGEDB+'DTM'	
		 IF OBJECT_ID(@CCHK_TABLE,'U') IS NOT NULL
		 BEGIN
 		 SET @DTSQL=N'IF EXISTS (SELECT TOP 1 A.CUSTOMER_CODE FROM  '+@CMERGEDB+'CMM01106 A
								LEFT OUTER JOIN  '+@CMERGEDB+'DTM B ON A.DT_CODE=B.DT_CODE
								LEFT OUTER JOIN DTM C ON A.DT_CODE=C.DT_CODE
								WHERE A.CM_ID='''+@CXNID+''' AND B.DT_CODE IS NULL AND C.DT_CODE IS NULL)
						SET @CERRORMSGOUT=''INVALID DISCOUNT TYPE FOUND''
					 ELSE
						SET @CERRORMSGOUT='''''	
						
		 EXEC SP_EXECUTESQL @DTSQL,N'@CERRORMSGOUT VARCHAR(200) OUTPUT',@CERRORMSGOUT=@CERRORMSG OUTPUT
		 END
	 END
	 
 	 IF ISNULL(@CERRORMSG,'')=''
	 BEGIN
		 SET @DTSQL=N'IF EXISTS (SELECT TOP 1 CM_ID FROM  '+@CMERGEDB+'CMD01106 A
								LEFT OUTER JOIN  '+@CMERGEDB+'EMPLOYEE B ON A.EMP_CODE=B.EMP_CODE
								WHERE A.CM_ID='''+@CXNID+''' AND A.EMP_CODE IS NOT NULL AND B.EMP_CODE IS NULL)
						SET @CERRORMSGOUT=''INVALID SALES PERSON DETAILS FOUND''
					 ELSE
						SET @CERRORMSGOUT='''''	
						
		 EXEC SP_EXECUTESQL @DTSQL,N'@CERRORMSGOUT VARCHAR(200) OUTPUT',@CERRORMSGOUT=@CERRORMSG OUTPUT
	 END
	 
 	 IF ISNULL(@CERRORMSG,'')=''
	 BEGIN
		 SET @DTSQL=N'IF EXISTS (SELECT TOP 1 CM_ID FROM  '+@CMERGEDB+'CMD01106 A
								LEFT OUTER JOIN  '+@CMERGEDB+'EMPLOYEE B ON A.EMP_CODE1=B.EMP_CODE
								WHERE A.CM_ID='''+@CXNID+''' AND A.EMP_CODE1 IS NOT NULL AND B.EMP_CODE IS NULL)
						SET @CERRORMSGOUT=''INVALID SALES PERSON-2 DETAILS FOUND''
					 ELSE
						SET @CERRORMSGOUT='''''	
						
		 EXEC SP_EXECUTESQL @DTSQL,N'@CERRORMSGOUT VARCHAR(200) OUTPUT',@CERRORMSGOUT=@CERRORMSG OUTPUT
	 END
	 
 	 IF ISNULL(@CERRORMSG,'')=''
	 BEGIN
		 SET @DTSQL=N'IF EXISTS (SELECT TOP 1 CM_ID FROM  '+@CMERGEDB+'CMD01106 A
								LEFT OUTER JOIN  '+@CMERGEDB+'EMPLOYEE B ON A.EMP_CODE2=B.EMP_CODE
								WHERE A.CM_ID='''+@CXNID+''' AND A.EMP_CODE2 IS NOT NULL AND B.EMP_CODE IS NULL)
						SET @CERRORMSGOUT=''INVALID SALES PERSON-3 DETAILS FOUND''
					 ELSE
						SET @CERRORMSGOUT='''''	
						
		 EXEC SP_EXECUTESQL @DTSQL,N'@CERRORMSGOUT VARCHAR(200) OUTPUT',@CERRORMSGOUT=@CERRORMSG OUTPUT	
	 END
	 
 	 IF ISNULL(@CERRORMSG,'')=''
	 BEGIN
		 SET @DTSQL=N'IF EXISTS (SELECT TOP 1 CM_ID FROM  '+@CMERGEDB+'CMD01106 A
								LEFT OUTER JOIN  '+@CMERGEDB+'SKU B ON A.PRODUCT_CODE=B.PRODUCT_CODE
								LEFT OUTER JOIN SKU C ON A.PRODUCT_CODE=C.PRODUCT_CODE
								WHERE A.CM_ID='''+@CXNID+''' AND A.QUANTITY<0 AND B.PRODUCT_CODE IS NULL AND C.PRODUCT_CODE IS NULL)
						SET @CERRORMSGOUT=''SALE RETURN BAR CODE DETAILS NOT FOUND''
					 ELSE
						SET @CERRORMSGOUT='''''	
						
		 EXEC SP_EXECUTESQL @DTSQL,N'@CERRORMSGOUT VARCHAR(200) OUTPUT',@CERRORMSGOUT=@CERRORMSG OUTPUT
	 END
	 
	 IF ISNULL(@CERRORMSG,'')<>''
		RETURN
			 										 
	 SELECT @NPAYMODECRAMT  = SUM(CASE WHEN PAYMODE_GRP_CODE='0000004' THEN AMOUNT ELSE 0 END),  
			@NPAYMODETOTAMT = SUM(AMOUNT) FROM @TPAYMODETABLE 
	  
	 SET @NPAYMODECRAMT  = ISNULL(@NPAYMODECRAMT,0)  
	 SET @NPAYMODETOTAMT = ISNULL(@NPAYMODETOTAMT,0)  
	      
     SELECT	@NCMDGROSS = SUM(QUANTITY*MRP),   
			@NCMDNETWOTAX= SUM(NET),  
			@NCMDNET = SUM(NET + (CASE WHEN TAX_METHOD=2 THEN TAX_AMOUNT ELSE 0 END) ),  
			@NCMDTOT = SUM(ISNULL(RFNET,0)),  
			@NCMDDISC = SUM(DISCOUNT_AMOUNT),  
			@NCMDEXCLTAX = SUM(CASE WHEN TAX_METHOD=2 THEN TAX_AMOUNT ELSE 0 END) 
	 FROM @TCMDTABLE 
	 
  	 SELECT	@NCMMSTOT = ISNULL(SUBTOTAL,0)+ISNULL(SUBTOTAL_R,0),   
				@NCMMDISCPER= DISCOUNT_PERCENTAGE,  
				@NCMMDISC = DISCOUNT_AMOUNT,   
				@NCMMNET = NET_AMOUNT,
				@NATDCHARGES=ATD_CHARGES+ROUND_OFF
	 FROM @TCMMTABLE  

	     
	 IF ABS( ISNULL(@NCMMSTOT,0) - ISNULL(@NCMDNETWOTAX,0) )>.10   
     BEGIN  
		 SET @CERRORMSG='MISMATCH BETWEEN BILL MASTER & DETAIL ...'+
						(CASE WHEN ABS( ISNULL(@NCMMSTOT,0) - ISNULL(@NCMDNETWOTAX,0) )>0  THEN '-1' ELSE '' END)
						 +'...PLEASE CHECK'  
		 RETURN  
	 END  


	 IF  ISNULL(@NCMDTOT,0)<>(@NCMMNET-@NATDCHARGES)
		EXEC UPDATERFNET 'SLS',@CXNID
      
	 IF EXISTS (SELECT CM_ID FROM @TCMMTABLE WHERE CM_MODE=1 AND NET_AMOUNT<>@NPAYMODETOTAMT)  
	 BEGIN  
		 SELECT @NTOTAMOUNT=NET_AMOUNT FROM @TCMMTABLE
		 
		 SET @CERRORMSG='NET AMOUNT '+STR(@NTOTAMOUNT,14,2)+' SHOULD BE EQUAL TO THE SUM OF ALL PAYMENT MODES '+STR(@NPAYMODETOTAMT,14,2)+'...PLEASE CHECK'  
		 RETURN  
	 END  

END_PROC:  
END  
--*************************************** END OF PROCEDURE VALIDATEXN_MIRROR_SLS
