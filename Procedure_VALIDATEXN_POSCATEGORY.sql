create PROCEDURE VALIDATEXN_POSCATEGORY
(
 @cxn_type varchar(10)='',
 @CXNID VARCHAR(50)='',	
 @NUPDATEMODE INT=0,	
 @cparty_dept_id VARCHAR(5)/**//*Rohit 07-11-2024*/='',	  		 
 @CERRORMSG VARCHAR(200) OUTPUT,
 @BCALLEDFROMSCANNING BIT=0	 ,
 @cproduct_code varchar(50)='',
 @CDEPT_ID VARCHAR(5)/**//*Rohit 07-11-2024*/=''
 )
 as
 begin
 
 
		DECLARE @DTSQL NVARCHAR(MAX),@CFILTER VARCHAR(MAX)

       
	 BEGIN TRY

	 if @NUPDATEMODE=3
	    GOTO EXIT_PROC

		IF OBJECT_ID('TEMPDB..#TMPCATEGORY','U') IS NOT NULL
		   DROP TABLE #TMPCATEGORY

		SELECT C.DEPT_ID, B.*  
		INTO #TMPCATEGORY
		FROM MSTPOSCATEGORY A (NOLOCK) 
		JOIN POSCATEGORYSTKRESTRICTIONS B (NOLOCK) ON A.CATEGORYCODE=B.CATEGORYCODE
		JOIN LOCATION C (NOLOCK) ON A.CATEGORYCODE=C.CATEGORYCODE
		WHERE DEPT_ID=@cparty_dept_id

		IF NOT EXISTS (SELECT TOP 1'U' FROM #TMPCATEGORY )
		    GOTO EXIT_PROC
		
		IF OBJECT_ID('TEMPDB..#TMPBARCODE','U') IS NOT NULL
		   DROP TABLE #TMPBARCODE

		SELECT A.ROW_ID ,A.PRODUCT_CODE ,CAST('' AS VARCHAR(5))/*left(inv_id,2)*//*Rohit 07-11-2024*/ as dept_id,bin_id ,
		        FILTERAPPLY=CAST(0 AS BIT),
		       cast('' as varchar (1000)) as RestrictionName
		INTO #TMPBARCODE
		FROM ind01106 A (NOLOCK)
		WHERE 1=2


		if @BCALLEDFROMSCANNING=1
		begin
             
			    
			       INSERT INTO #TMPBARCODE(ROW_ID ,PRODUCT_CODE,dept_id,bin_id)
				   SELECT NEWID(),@CPRODUCT_CODE AS PRODUCT_CODE,@CDEPT_ID,'000' AS BIN_ID
			  
		end
		else
		begin

			IF @CXN_TYPE='WSL'
			BEGIN
				INSERT INTO #TMPBARCODE(ROW_ID ,PRODUCT_CODE,dept_id,bin_id)
				SELECT A.ROW_ID ,A.PRODUCT_CODE ,b.LOCATION_CODE /*left(inv_id,2)*//*Rohit 07-11-2024*/ as dept_id,A.bin_id 
				FROM IND01106 A (NOLOCK) 
				JOIN INM01106 B (NOLOCK) ON A.INV_ID=B.INV_ID /**//*Rohit 07-11-2024*/
				WHERE B.INV_ID=@CXNID

			END
			ELSE  IF @CXN_TYPE='WPS'
			BEGIN
				INSERT INTO #TMPBARCODE(ROW_ID ,PRODUCT_CODE,dept_id,bin_id)
				SELECT A.ROW_ID ,A.PRODUCT_CODE ,B.location_Code/*left(ps_id,2)*//*Rohit 07-11-2024*/ as dept_id,A.bin_id 
				FROM WPS_DET A (NOLOCK) 
				JOIN WPS_MST B (NOLOCK) ON B.PS_ID=A.PS_ID/**//*Rohit 07-11-2024*/
				WHERE B.PS_ID =@CXNID

			END

		end

	
	
		--SELECT @CFILTER=COALESCE(@CFILTER+' OR ',' ')+PC.CATEGORYFILTER+'  '
		--FROM #TMPCATEGORY PC

		declare @cRestrictionCode varchar(10) ,@cRestrictionName  varchar(1000)


		WHILE EXISTS (SELECT TOP 1 'U' FROM #TMPCATEGORY)
		begin

		    SET @CFILTER=''
			SELECT TOP 1  @CFILTER=PC.CATEGORYFILTER ,@CRESTRICTIONCODE=RESTRICTIONCODE ,@CRESTRICTIONNAME=RESTRICTIONNAME 
		    FROM #TMPCATEGORY PC


			SET @DTSQL=N'UPDATE A SET FILTERAPPLY=1,RestrictionName='''+@CRESTRICTIONNAME+'''
			FROM #TMPBARCODE A
			JOIN SKU_NAMES (NOLOCK) ON A.PRODUCT_CODE =SKU_NAMES .PRODUCT_CODE 
			WHERE '+@CFILTER+' 
			and  ISNULL(FILTERAPPLY,0)=0'
			PRINT @DTSQL
			EXEC SP_EXECUTESQL @DTSQL

			DELETE FROM #TMPCATEGORY WHERE RESTRICTIONCODE=@CRESTRICTIONCODE 

		end

		
		IF EXISTS (SELECT TOP 1 'U' FROM #TMPBARCODE WHERE ISNULL(FILTERAPPLY,0)=1)
		BEGIN

			SET @CERRORMSG='This Item  Belongs to POS Restrictions Category You can not Transfer this item Please Check  '

			if @BCALLEDFROMSCANNING=1
			begin

			     select @CERRORMSG=@CERRORMSG+'Restrictions:'+RestrictionName+'('+PRODUCT_CODE+')' FROM #TMPBARCODE A 
			     WHERE ISNULL(FILTERAPPLY,0)=1
				 GOTO EXIT_PROC
			end

			SELECT a.PRODUCT_CODE,RestrictionName as RESTRICTIONNAME , @CERRORMSG AS ERRMSG,0  AS QUANTITY_IN_STOCK 
			FROM #TMPBARCODE A 
			WHERE ISNULL(FILTERAPPLY,0)=1
			GOTO EXIT_PROC
		END

 END TRY
BEGIN CATCH
	SET @CERRORMSG='P:VALIDATEXN_POSCATEGORY, MEMO ID MESSAGE:'+ERROR_MESSAGE()
	GOTO EXIT_PROC
END CATCH

EXIT_PROC:


END