CREATE PROCEDURE SAVETRAN_MANUAL_SKU
(  
 @NUPDATEMODE  NUMERIC(1,0)=0,  
 @NSPID    INT,  
 @CFINYEAR   VARCHAR(10)='',  
 @CMACHINENAME  VARCHAR(100)='',  
 @CWINDOWUSERNAME VARCHAR(100)='',  
 @CWIZAPPUSERCODE VARCHAR(10)='0000000',
 @cProductCode VARCHAR(100)='',@cArticleCode VARCHAR(100)='',@nMRP NUMERIC(14,2)=0
)  
--WITH ENCRYPTION
AS  
BEGIN
	 DECLARE @CTEMPDBNAME VARCHAR(100),
	         @CMASTERTABLENAME  VARCHAR(100),
             --@CTEMPMASTERTABLENAME VARCHAR(100),
             --@CTEMPMASTERTABLE  VARCHAR(100),
             @CTEMPFINALMASTERTABLENAME VARCHAR(100),
             @CTEMPFINALMASTERTABLE  VARCHAR(100),
             @CERRORMSG    VARCHAR(500), 
			 @CKEYFIELD1    VARCHAR(50), 
			 @CMEMONO    VARCHAR(20),
			 @NSTEP     INT, 
			 @CCMD     NVARCHAR(MAX),
			 @CSPID    INT

             DECLARE @OUTPUT TABLE ( ERRMSG VARCHAR(2000), MEMO_ID VARCHAR(100))  

			 SET @NSTEP = 10
             SET @NSTEP = 40
             SELECT @CSPID = @@SPID ,@CKEYFIELD1 = 'PRODUCT_CODE'
            
			 SET @NSTEP = 60
			  SET @CTEMPDBNAME = ''
	BEGIN TRY 
	BEGIN TRANSACTION  
	
	         SET @NSTEP = 100
	         SET @CMASTERTABLENAME = 'SKU'
	         --SET @CTEMPMASTERTABLENAME = 'TEMP_SKU_'+LTRIM(RTRIM(STR(@NSPID))) 
	         --SET @CTEMPMASTERTABLE = @CTEMPDBNAME + @CTEMPMASTERTABLENAME
	         
	         SET @CTEMPFINALMASTERTABLENAME = 'TEMP_FINAL_SKU_'+LTRIM(RTRIM(STR(@CSPID))) 
             SET @CTEMPFINALMASTERTABLE  = @CTEMPDBNAME +@CTEMPFINALMASTERTABLENAME
	         
	      --   SET @NSTEP = 120
	      --   SET @CCMD = N'IF OBJECT_ID('''+@CTEMPMASTERTABLE+''',''U'') IS NULL
							--SET @CERRORMSG= ''TEMP TABLE NOT FOUND.'''
	      -- 	 PRINT @CCMD
	      -- 	 EXEC SP_EXECUTESQL @CCMD,N'@CERRORMSG VARCHAR(500) OUTPUT',@CERRORMSG OUTPUT
	       	 
	       	 SET @NSTEP = 130
	       	 IF ISNULL(@CERRORMSG,'') <> ''
	            GOTO END_PROC
	    
	       	 
	       	 SET @NSTEP = 160
	       	 SET @CCMD = N'IF OBJECT_ID('''+@CTEMPFINALMASTERTABLE+''',''U'') IS NOT NULL
							DROP TABLE '+@CTEMPFINALMASTERTABLE+''
	       	 PRINT @CCMD
	       	 EXEC SP_EXECUTESQL @CCMD
	       	 
	       	 SET @NSTEP = 200
	       	 SET @CCMD = N'SELECT * INTO '+@CTEMPFINALMASTERTABLE+' FROM SKU WHERE 1 = 2'
	       	 PRINT @CCMD
	       	 EXEC SP_EXECUTESQL @CCMD
	       	  
	       	 --SET @NSTEP = 230
	       	 --SET @CCMD = N'DELETE A  FROM '+@CTEMPMASTERTABLE+' A LEFT OUTER JOIN ARTICLE B
	       	 --              ON A.ARTICLE_CODE = B.ARTICLE_CODE
	       	 --              WHERE B.ARTICLE_CODE IS NULL OR ISNULL(A.ARTICLE_CODE,'''')= '''''
	       	 
	       	 
	   
	       	 SET @NSTEP = 250
	       	 SET @CCMD = N'INSERT INTO '+@CTEMPFINALMASTERTABLE+' 
	       	             (  
	       	                PRODUCT_CODE,
							ARTICLE_CODE,
							MRP,
	       	                PARA2_CODE,
							LAST_UPDATE,
							PURCHASE_PRICE,
							PARA3_CODE,
							INV_DT,
							INV_NO,
							AC_CODE,
							RECEIPT_DT,
							PARA4_CODE,
							PARA5_CODE,
							PARA6_CODE,
							FORM_ID,
							DT_CREATED,
							WS_PRICE,
							IMAGE_NAME,
							TAX_AMOUNT,
							CHALLAN_NO,
							FIX_MRP,
							PRODUCT_NAME,							
							PARA1_CODE,
							ER_FLAG,
							UPLOADED_TO_ACTIVSTREAM,
							BARCODE_CODING_SCHEME,
							EMP_CODE
						 )
	       	               SELECT 
	       	               '''+@cProductCode+''' AS  PRODUCT_CODE,
	       	               '''+@cArticleCode+''' AS  ARTICLE_CODE,
	       	               '+CAST(@nMRP AS VARCHAR(20))+' AS  MRP, 
	       	               ''0000000'' AS PARA2_CODE,
						   GETDATE() AS LAST_UPDATE,
							0 AS PURCHASE_PRICE,
							''0000000'' AS PARA3_CODE,
							GETDATE() AS INV_DT,
							'''' AS INV_NO,
							''0000000000'' AS AC_CODE,
							GETDATE () AS RECEIPT_DT,
							''0000000'' AS PARA4_CODE,
							''0000000'' AS PARA5_CODE,
							''0000000'' AS PARA6_CODE,
							''0000000'' AS FORM_ID,
							'''' AS DT_CREATED,
							0 AS WS_PRICE,
							'''' AS IMAGE_NAME,
							0 AS TAX_AMOUNT,
							'''' AS CHALLAN_NO,
							0 AS FIX_MRP,
							'''' AS PRODUCT_NAME,							
							''0000000'' AS PARA1_CODE,
							0 AS ER_FLAG,
							0 AS UPLOADED_TO_ACTIVSTREAM,
							C.CODING_SCHEME AS BARCODE_CODING_SCHEME,
							''0000000'' AS EMP_CODE
							FROM  ARTICLE C WHERE C.ARTICLE_CODE ='''+@cArticleCode+''''
	       	              -- FROM '+@CTEMPMASTERTABLE
						   
						   --+' A 
	       	              
	       	--               LEFT OUTER JOIN SKU B ON A.PRODUCT_CODE= B.PRODUCT_CODE 
	       	--               JOIN ARTICLE C ON C.ARTICLE_CODE = A.ARTICLE_CODE
	       	--               WHERE B.PRODUCT_CODE IS NULL AND ISNULL(A.PRODUCT_CODE,'''') <> '''''
	       	               
	       	          PRINT @CCMD
	       	          EXEC SP_EXECUTESQL @CCMD     
	       	               
	       	          SET @NSTEP = 300 
   	                 EXEC UPDATEMASTERXN
   	                @CSOURCEDB=@CTEMPDBNAME,
					@CSOURCETABLE=@CTEMPFINALMASTERTABLENAME,
					@CDESTDB='',
					@CDESTTABLE=@CMASTERTABLENAME,
					@CKEYFIELD1=@CKEYFIELD1,
					@CKEYFIELD2='',
					@CKEYFIELD3='',
					@LINSERTONLY=1,
					@CFILTERCONDITION='',
					@BALWAYSUPDATE=1
	       	           
	       	 
	       	  	     
    END TRY
    BEGIN CATCH
		SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()  
		GOTO END_PROC
    END CATCH
    END_PROC:
                    INSERT INTO @OUTPUT(ERRMSG,MEMO_ID)
	       			SELECT ISNULL(@CERRORMSG,''),'SKU'
	       	
	       	IF ISNULL(@CERRORMSG,'') = ''
	       	BEGIN  
	       	  COMMIT
	       	  --SET @CCMD = N'IF OBJECT_ID('''+@CTEMPMASTERTABLE+''',''U'') IS NOT NULL
	       			--			DROP TABLE  '+@CTEMPMASTERTABLE+'
	       			--		IF OBJECT_ID('''+@CTEMPFINALMASTERTABLE+''',''U'') IS NOT NULL
	       			--			DROP TABLE  '+@CTEMPFINALMASTERTABLE+''
SET @CCMD = N'IF OBJECT_ID('''+@CTEMPFINALMASTERTABLE+''',''U'') IS NOT NULL
	       						DROP TABLE  '+@CTEMPFINALMASTERTABLE+''
	       	  PRINT @CCMD
	       	  EXEC SP_EXECUTESQL 	@CCMD				
	       	END
	       	ELSE
	       	  ROLLBACK
	       	  
	       	 SELECT * FROM  @OUTPUT		
END
