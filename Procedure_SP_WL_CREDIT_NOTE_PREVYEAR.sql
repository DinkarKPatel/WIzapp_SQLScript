
create PROCEDURE SP_WL_CREDIT_NOTE_PREVYEAR
 @NQUERYID NUMERIC (3,0) ,          
 @CMEMOID VARCHAR(40) = '',          
 @CWHERE  VARCHAR(500) = '',          
 @NNAVMODE NUMERIC(1,0) = 0,          
 @CFINYEAR VARCHAR(5)='',          
 @CWHERE1 VARCHAR(500) = '',
 @CLOCID VARCHAR(500) = '',
 @DMEMODT DATETIME=''           
--  WITH ENCRYPTION        
AS          
BEGIN  

 DECLARE @dPrevDate DATETIME,@cCutOffdate VARCHAR(15),@bFound BIT,
       @cPrevDbName VARCHAR(50),@cDbName VARCHAR(100),
       @CSEARCHPRODUCTCODE VARCHAR(50),@CCMD NVARCHAR(MAX)
		
	IF @NQUERYID IN(11,12)
	BEGIN	
		select top 1 @cCutOffdate=value FROM config WHERE config_option='NEW_DATA_ARCHIVING_DATE'
		IF ISNULL(@cCutOffdate,'')<>''
		BEGIN
			
			set @dPrevDate=CONVERT(DATE,@cCutOffdate)
			SET @dPrevDate=DATEADD(DD,0,@dPrevDate)
			
			SET @bFound=1
			WHILE @bFound=1
			BEGIN
			

		
				IF @dPrevDate<>@cCutOffdate
				   SET @cPrevDbName=DB_NAME()+'_01'+DBO.FN_GETFINYEAR(@dPrevDate)
				ELSE 
				   SET @cPrevDbName=DB_NAME()


				IF DB_ID(@cPrevDbName) IS NULL
					BREAK
				
				  SET @cPrevDbName=@cPrevDbName+'.dbo.' 

			
				
				 SET @CCMD=N'SELECT TOP 1 @CSEARCHPRODUCTCODE=PRODUCT_CODE
				 FROM '+@cPrevDbName+'INM01106 A(NOLOCK)  
				 JOIN '+@cPrevDbName+'IND01106 B(NOLOCK) ON A.INV_ID=B.INV_ID
				 JOIN LMV01106 C (NOLOCK) ON A.AC_CODE = C.AC_CODE   
				 WHERE A.CANCELLED=0 
				 AND B.PRODUCT_CODE='''+@CWHERE1+'''  
				 AND (A.AC_CODE='''+@CWHERE+'''  OR '''+@CWHERE+'''='''')
				 AND A.INV_MODE='''+rtrim(ltrim(STR(@NNAVMODE)))+'''
				 ORDER BY A.INV_DT,A.INV_NO DESC  '
				
				print @cCmd
				EXEC SP_EXECUTESQL @cCmd,N'@CSEARCHPRODUCTCODE VARCHAR(50) OUTPUT',@CSEARCHPRODUCTCODE OUTPUT
				
				
				IF ISNULL(@CSEARCHPRODUCTCODE,'')<>''
				begin					
					set @cDbName=@cPrevDbName
					break
				end	
				
				SET @dPrevDate=DATEADD(YY,-1,@dPrevDate)


			END
		END
		


		IF ISNULL(@CDBNAME,'')=''
		SET @CDBNAME=DB_NAME()+'.DBO.'

		IF ISNULL(@CDBNAME,'')<>''
		BEGIN
			
			SET @CCMD =N'EXEC '+@CDBNAME+'SP_WL_CREDIT_NOTE '+ltrim(STR(@NQUERYID))+','''','''+@CWHERE+''','+rtrim(ltrim(STR(@NNAVMODE)))+','''','''+@CWHERE1+''','+@CLOCID+','''',1 '
			PRINT @CCMD
			EXEC SP_EXECUTESQL @CCMD
		    RETURN
		END


	 END

END