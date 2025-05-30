CREATE PROCEDURE UPDATEUPCPMT_PRD
		@CXNTYPE VARCHAR(10),
		@CXNNO VARCHAR(40)='',
		@CXNID VARCHAR(40),
		@NREVERTFLAG BIT = 0,
		@NALLOWNEGSTOCK BIT = 0,
		@NCHKDELBARCODES BIT = 0,
		@NUPDATEMODE INT=0,	
		@CCMD NVARCHAR(4000) OUTPUT

		--*** PARAMETERS :
		--*** @CXNTYPE - TRANSACTION TYPE (MODULE SPECIFIC)
		--*** @CXNNO - TRANSACTION NO ( MEMO NO OF MASTER TABLE )
		--*** @CXNID - TRANSACTION ID ( MEMO ID OF MASTER TABLE )
		--*** @NREVERTFLAG - A FLAG TO INDICATE WHETHER THIS PROCEDURE IS CALLED TO REVERT STOCK
		--*** @NALLOWNEGSTOCK - FLAG TO INDICATE WHETHER OR NOT ALLOW NEGATIVE STOCK
		--*** @NRETVAL - OUTPUT PARAMETER RETURNED BY THIS PROCEDURE (BIT 1-SUCCESS, 0-UNSUCCESS)
--WITH ENCRYPTION
AS
BEGIN



	DECLARE @NOUTFLAG INT, @NRETVAL BIT,@CXNTABLE VARCHAR(50),@CEXPR NVARCHAR(500),@CXNIDPARA VARCHAR(50),
			@BCANCELLED BIT
	
	SET @NRETVAL = 0
	SET @CCMD = ''
	
	IF EXISTS (SELECT TOP  1 'U' FROM  PRD_UPCPMT WHERE WO_ID=@CXNID)
	GOTO END_PROC

	--*** STARTING STOCK UPDATION FOR UPC PMT
	IF @CXNTYPE IN ('PRD_WO')				
	BEGIN
	
	 IF OBJECT_ID('TEMPDB..#TMPORDER','U') IS NOT NULL
		DROP TABLE #TMPORDER
	 
	 SELECT  MST.MEMO_ID AS ORDER_ID
				,MST.MEMO_NO AS ORDER_NO
				,MST.MEMO_DT  AS ORDER_DT
				,MST.ARTICLE_SET_CODE
				,AR1.ARTICLE_NAME AS FG_ARTICLE_NAME
				,AR1.ARTICLE_NO AS FG_ARTICLE_NO
				,AR1.ARTICLE_CODE AS FG_ARTICLE_CODE
				,PARA1.PARA1_CODE
				,PARA1.PARA1_NAME
				,PARA2.PARA2_CODE
				,PARA2.PARA2_NAME
				,DET.QUANTITY AS WO_QTY 
		INTO #TMPORDER
		FROM PRD_WO_DET B (NOLOCK) 
		JOIN PRD_WO_MST MST (NOLOCK) ON B.MEMO_ID=MST.MEMO_ID
		JOIN ARTICLE AR (NOLOCK) ON AR.ARTICLE_CODE =B.ARTICLE_CODE
		JOIN ARTICLE AR1 (NOLOCK) ON AR1.ARTICLE_CODE =MST.ARTICLE_SET_CODE     
		JOIN
		(
		 SELECT PARA1_CODE,PARA2_CODE,REF_ROW_ID,SUM(QUANTITY) AS QUANTITY 
		 FROM PRD_WO_SUB_DET C
		 GROUP BY REF_ROW_ID,PARA1_CODE,PARA2_CODE
		) DET ON B.ROW_ID=DET.REF_ROW_ID
		JOIN PARA1  (NOLOCK) ON DET.PARA1_CODE=PARA1.PARA1_CODE
		JOIN PARA2  (NOLOCK) ON DET.PARA2_CODE=PARA2.PARA2_CODE
		WHERE MST.MEMO_ID=@CXNID AND
		--MST.MEMO_DT BETWEEN @DFROMDT AND @DTODT AND
        MST.CANCELLED=0
	
		--AND MST.MEMO_ID='HO0111700000HO00000559'
		GROUP BY MST.MEMO_ID 
				,MST.MEMO_NO 
				,MST.MEMO_DT  
				,MST.ARTICLE_SET_CODE
				,AR1.ARTICLE_NAME 
				,AR1.ARTICLE_NO 
				,AR1.ARTICLE_CODE 
				,PARA1.PARA1_CODE
				,PARA1.PARA1_NAME
				,PARA2.PARA2_CODE
				,PARA2.PARA2_NAME
				,DET.QUANTITY
      

			DECLARE @TQTY INT, @SR INT, @NCANCELLED BIT, @NQTY INT, @ORDER_ID VARCHAR(100),@CPARA1_CODE VARCHAR(10),@CPARA2_CODE VARCHAR(10),@CORDER_NO VARCHAR(10)

            SELECT @NCANCELLED=CANCELLED FROM PRD_WO_MST WHERE MEMO_ID=@CXNID
            
            IF @NCANCELLED=1
            BEGIN
                
                DELETE FROM PRD_UPCPMT WHERE WO_ID=@CXNID
                GOTO END_PROC
            END
            
            DECLARE @CPREFIX AS VARCHAR(100),@CNEXTPRODUCTCODE VARCHAR(100),@CFINYEAR VARCHAR(2),@MAXSR INT
            
            SELECT TOP 1 @CFINYEAR=RIGHT(FIN_YEAR,2) FROM PRD_WO_MST WHERE MEMO_ID=@CXNID 
            
            SET @CNEXTPRODUCTCODE=''
            SET @CPREFIX='WIP'+CAST(@CFINYEAR AS VARCHAR(2))
            
      
          
			WHILE EXISTS (SELECT TOP 1 'U' FROM #TMPORDER)
			BEGIN
			  EXEC GETNEXTKEY 'PRD_UPCPMT', 'PRODUCT_CODE', 50, @CPREFIX, 0, '', 0,@CNEXTPRODUCTCODE OUTPUT  
			     
			    IF OBJECT_ID ('TEMPDB..#TMP','U') IS NOT NULL
                 DROP TABLE #TMP 
                 
			  SET @NQTY=SUBSTRING (@CNEXTPRODUCTCODE,6,LEN(@CNEXTPRODUCTCODE))
			  
			  SELECT TOP 1 @TQTY=WO_QTY, @CORDER_NO=ORDER_NO, @ORDER_ID=ORDER_ID,@CPARA1_CODE=PARA1_CODE,@CPARA2_CODE=PARA2_CODE FROM  #TMPORDER
			  
		       SET @TQTY=@NQTY+@TQTY
		      
		      ;WITH CTE AS
					(
						SELECT SR=@NQTY
						UNION ALL
						SELECT SR=SR+1
						FROM CTE  WHERE SR<@TQTY-1
			 )
				
			  SELECT * INTO #TMP FROM CTE
			  		
			  INSERT PRD_UPCPMT	( ORDER_ID, PARA1_CODE, PARA2_CODE, WO_ID, PRODUCT_CODE, QUANTITY_IN_STOCK, JOB_CODE ) 
			  SELECT 	  ORDER_ID=NULL, PARA1_CODE=@CPARA1_CODE, PARA2_CODE=@CPARA2_CODE, WO_ID=@ORDER_ID, 
			  PRODUCT_CODE='WIP'+@CFINYEAR+CAST(SR AS VARCHAR(100)), QUANTITY_IN_STOCK=1, JOB_CODE=NULL 
			  FROM #TMP
			 
			 
			 SELECT @MAXSR=MAX(SR) FROM #TMP
			 
			 
             UPDATE KEYS_PMT SET LASTKEYVAL=@CPREFIX+CAST(@MAXSR AS VARCHAR(10) ) WHERE TABLENAME ='PRD_UPCPMT'
               
   

			 DELETE FROM #TMPORDER WHERE ORDER_ID= @ORDER_ID AND PARA1_CODE=@CPARA1_CODE AND PARA2_CODE=@CPARA2_CODE
             
			END
			
			
         GOTO END_PROC
		    
		END			-- END OF LABEL UNIQUE PRODUCT CODE 
		
		
	  
	 
	END_PROC:
	

END
