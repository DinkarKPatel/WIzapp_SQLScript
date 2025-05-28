
create PROC SAVETRAN_PLM
(
  @NSPID varchar(50),
  @NMODE INT=2,
  @CMEMOID VARCHAR(100)
)
----WITH ENCRYPTION
AS
BEGIN
   SET NOCOUNT ON
   DECLARE @CCMD NVARCHAR(MAX),@ON VARCHAR(1000),@COL VARCHAR(1000)
   ,@CMASTERTABLENAME VARCHAR(100),@CSOURCEMASTERTABLENAME VARCHAR(100)
   ,@CTRANSACTIONTABLENAME1 VARCHAR(100),@CSOURCETRANSACTIONTABLENAME1 VARCHAR(100)
   ,@NSTEP INT=0,@CERRORMSG VARCHAR(MAX)='',@UPDATE VARCHAR(MAX)='',@NSAVETRANLOOP INT
   ,@CMEMONO VARCHAR(100),@NMEMONOLEN INT,@CMEMONOVAL VARCHAR(100),@CLOCATIONID VARCHAR(100),@CFINYEAR VARCHAR(10)
   ,@MEMOID VARCHAR(100),@UPD DATETIME=GETDATE(),@NREVERTFLAG NUMERIC(1,0)
   ,@CAC_CODE varchar(15),@SalesOrderXnType varchar(30),@SalesOrderXnType1 varchar(30),@corderid varchar(50)
   ,@cFirstNo varchar(20),@cLastNo varchar(20),@cstatus varchar(max),@cBatchLotNo varchar(50), @cLocId char(4)=''


   BEGIN TRY
   BEGIN TRANSACTION

	 set @SalesOrderXnType='OrderPickList'
	 set @SalesOrderXnType1='PickList'



	 SET @CBATCHLOTNO=@CLOCID+CONVERT(VARCHAR(40), NEWID())
	

	 select * into #tmpSalesOrderProcessing
     from SalesOrderProcessing (nolock) where 1=2

    IF @NMODE=3--CANCEL DOC
    BEGIN
        UPDATE PLM01106 SET CANCELLED=1,LAST_UPDATE=GETDATE() WHERE MEMO_ID=@CMEMOID

		IF EXISTS (SELECT TOP 1 'U' FROM PLM01106 (NOLOCK) WHERE MEMO_ID =@CMEMOID AND ISNULL(ORDER_ID,'')<>'')
		BEGIN

			INSERT INTO #tmpSalesOrderProcessing(XnType,Memoid,RefMemoid,ArticleCode ,Para1Code ,Para2Code ,Para3Code,Qty  )
			SELECT @SalesOrderXnType XnType ,A.MEMO_ID Memoid,a.order_id RefMemoid,  B.ARTICLE_CODE,B.PARA1_CODE ,B.PARA2_CODE ,B.PARA3_CODE ,-1*B.QUANTITY   
			FROM PLM01106 A (nolock)
			JOIN PLD01106 B (nolock) ON A.memo_id =B.memo_id 
			WHERE A.MEMO_ID =@CMEMOID

		end
		else
		begin
		    
			INSERT INTO #tmpSalesOrderProcessing(XnType,Memoid,RefMemoid,ArticleCode ,Para1Code ,Para2Code ,Para3Code,Qty  )
			SELECT @SalesOrderXnType ,Memoid,RefMemoid,ArticleCode ,Para1Code ,Para2Code ,Para3Code,-1*Qty
			FROM SALESORDERPROCESSING A(NOLOCK) WHERE  MEMOID=@CMEMOID
			AND XNTYPE ='ORDERPICKLIST'

		end

		INSERT INTO #tmpSalesOrderProcessing(XnType,Memoid,RefMemoid,ArticleCode ,Para1Code ,Para2Code ,Para3Code,Qty  )
		SELECT @SalesOrderXnType1 XnType ,A.MEMO_ID Memoid,A.MEMO_ID RefMemoid,  B.ARTICLE_CODE,B.PARA1_CODE ,B.PARA2_CODE ,B.PARA3_CODE ,-1*B.QUANTITY   
		FROM PLM01106 A (nolock)
		JOIN PLD01106 B (nolock) ON A.memo_id =B.memo_id 
		WHERE A.MEMO_ID =@CMEMOID



			Exec Sp3s_SalesOrderProcessing_PLM
			     @nUpdateMode=@NMODE,
				 @cmemoid=@CMEMOID,
				 @CERRORMSG=@CERRORMSG output 

	
        GOTO END_PROC
    END
	IF @NMODE=4--Short close
    BEGIN
	   
	   if exists (select top 1 'u' from PLM01106 (nolock)  WHERE MEMO_ID=@CMEMOID and Short_close=1 )
	   begin
	        SET @CERRORMSG = 'memo has already Short close'
			GOTO END_PROC
	   end

	   if exists (select top 1 'u' from PLM01106 (nolock)  WHERE MEMO_ID=@CMEMOID and CANCELLED=1 )
	   begin
	        SET @CERRORMSG = 'memo has already cancelled'
			GOTO END_PROC
	   end

        UPDATE PLM01106 SET Short_close=1,LAST_UPDATE=GETDATE() WHERE MEMO_ID=@CMEMOID

		set @SalesOrderXnType='PLShortClose'

		INSERT INTO #tmpSalesOrderProcessing(XnType,Memoid,RefMemoid,ArticleCode ,Para1Code ,Para2Code ,Para3Code,Qty  )
		select @SalesOrderXnType as XnType,@CMEMOID Memoid, a.RefMemoId RefMemoid,a.ArticleCode ,a.Para1Code ,a.Para2Code ,a.Para3Code,
		    SUM(CASE WHEN XNTYPE='PickList' THEN QTY else  -QTY  END) as Qty
		from SALESORDERPROCESSING A
		where XnType in('PickList','PLPackSlip','PLIinvoice')
		and RefMemoId=@CMEMOID
		group by a.RefMemoId,a.ArticleCode ,a.Para1Code ,a.Para2Code ,a.Para3Code

			Exec Sp3s_SalesOrderProcessing_PLM
			     @nUpdateMode=@NMODE,
				 @cmemoid=@CMEMOID,
				 @CERRORMSG=@CERRORMSG output 

        GOTO END_PROC
    END

    SET @NSTEP=1
     SELECT @CMASTERTABLENAME='PLM01106',@CSOURCEMASTERTABLENAME='PLM_PLM01106_UPLOAD'

	 SELECT @CTRANSACTIONTABLENAME1='PLD01106',@CSOURCETRANSACTIONTABLENAME1='PLM_PLD01106_UPLOAD'
     --GENERATING NEW MEMO NO		
     
     Update PLM_PLD01106_UPLOAD set  Para3_code='0000000' where  ISNULL(Para3_code,'')='' and SP_ID=@NSPID
	
     SELECT @CFINYEAR='01'+DBO.FN_GETFINYEAR(GETDATE())
	    
    if @NMODE=1
		SELECT @CLOCATIONID		= location_code  FROM PLM_PLm01106_UPLOAD (nolock) WHERE SP_ID =@NSPID 
    ELSE
		SELECT @CLOCATIONID		= location_code  FROM plm01106 (nolock) WHERE MEMO_ID  =@CMEMOID  

     SELECT CAST('' AS VARCHAR(20)) AC_CODE ,
	       CAST('' AS VARCHAR(100)) AS ORDER_ID
		INTO #TMPDNSUPPLIER 
	 WHERE 1=2	

	 INSERT INTO #TMPDNSUPPLIER(AC_CODE,ORDER_ID)
	 SELECT AC_CODE  ,ORDER_ID 
	 FROM PLM_PLD01106_UPLOAD 
	 WHERE SP_ID=@NSPID
	 GROUP BY AC_CODE,ORDER_ID 

	LBLGENPL:
	truncate table #tmpSalesOrderProcessing

	SELECT TOP 1 @CAC_CODE=AC_CODE ,@CORDERID=ORDER_ID 
	FROM #TMPDNSUPPLIER
	ORDER BY ORDER_ID

	UPDATE PLM_PLM01106_UPLOAD SET AC_CODE=@CAC_CODE,ORDER_ID =@CORDERID,BatchLotNo=@CBATCHLOTNO WHERE SP_ID=@NSPID

	

	 SET @NSAVETRANLOOP=0

	 SET @CMEMONO='MEMO_NO'   
	 SET @NMEMONOLEN=10
	 
	 WHILE @NSAVETRANLOOP=0
	   BEGIN
	      EXEC GETNEXTKEY @CMASTERTABLENAME, @CMEMONO,@NMEMONOLEN,@CLOCATIONID,1,@CFINYEAR,0, @CMEMONOVAL OUTPUT   
	      SET @NSTEP = 50
		  --PRINT @CMEMONOVAL
		  SET @CCMD=N'IF EXISTS (
								 SELECT '+@CMEMONO+' FROM '+@CMASTERTABLENAME+' 
								 WHERE '+@CMEMONO+'='''+@CMEMONOVAL+''' 
								 AND FIN_YEAR = '''+@CFINYEAR+'''
								)
						SET @NLOOPOUTPUT=0
					ELSE
						SET @NLOOPOUTPUT=1'
		  PRINT @CCMD
		  EXEC SP_EXECUTESQL @CCMD, N'@NLOOPOUTPUT BIT OUTPUT',@NLOOPOUTPUT=@NSAVETRANLOOP OUTPUT
	   END

	 IF @CMEMONOVAL IS NULL OR @CMEMONOVAL LIKE '%LATER%'  
	   BEGIN
		 SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO NO....'	
		 GOTO END_PROC  		
	   END
	 
	 
     SET @MEMOID = @CLOCATIONID + @CFINYEAR+REPLICATE('0', (22-LEN(@CLOCATIONID + @CFINYEAR))-LEN(LTRIM(RTRIM(@CMEMONOVAL))))  + LTRIM(RTRIM(@CMEMONOVAL))
  
	-- SET @MEMOID = @CLOCATIONID + @CFINYEAR+ ISNULL(REPLICATE('0', 10-LEN(LTRIM(RTRIM(@CMEMONOVAL)))),'') + LTRIM(RTRIM(@CMEMONOVAL)) 
	 
     SET @NSTEP=5
     SET @CCMD='UPDATE ['+@CSOURCEMASTERTABLENAME+'] SET MEMO_NO='''+@CMEMONOVAL+''',MEMO_ID='''+@MEMOID+''',LAST_UPDATE='''+CONVERT(VARCHAR,@UPD,113)+''' where sp_id='''+@NSPID+''''
     EXEC(@CCMD)
     
     SET @NSTEP=10

	

	 declare @CWHERECLAUSE varchar(1000)
	 set @CWHERECLAUSE = ' SP_ID='''+LTRIM(RTRIM((@NSPID)))+''''

	 	EXEC UPDATEMASTERXN_OPT 
			  @CSOURCEDB	= ''
			, @CSOURCETABLE = @CSOURCEMASTERTABLENAME
			, @CDESTDB		= ''
			, @CDESTTABLE	= @CMASTERTABLENAME
			, @CKEYFIELD1	= 'ROW_ID'
			, @LINSERTONLY  = 1
			, @BALWAYSUPDATE = 1				
			, @CFILTERCONDITION=@CWHERECLAUSE
			 ,@LUPDATEXNS=1

	
	 
	 SET @cMemoId=@MEMOID

	 SET @NSTEP=20

	
	 SET @CCMD='UPDATE ['+@CSOURCETRANSACTIONTABLENAME1+'] SET MEMO_ID='''+@MEMOID+''',LAST_UPDATE='''+CONVERT(VARCHAR,@UPD,113)+''',ROW_ID=LEFT(NEWID(),100) where sp_id='''+@NSPID+''' '
	 PRINT @CCMD
     EXEC(@CCMD)

	
	
    set @CWHERECLAUSE = ' SP_ID='''+LTRIM(RTRIM((@NSPID)))+''' and order_id='''+@CORDERID+''' '

  	 EXEC UPDATEMASTERXN_OPT 
			  @CSOURCEDB	= ''
			, @CSOURCETABLE = @CSOURCETRANSACTIONTABLENAME1
			, @CDESTDB		= ''
			, @CDESTTABLE	= @CTRANSACTIONTABLENAME1
			, @CKEYFIELD1	= 'ROW_ID'
			, @LINSERTONLY  = 1
			, @BALWAYSUPDATE = 1				
			, @CFILTERCONDITION=@CWHERECLAUSE
		    ,@LUPDATEXNS=1
 

		 if not Exists (select top 1 'u' From PLD01106 (nolock) where memo_id=@CMEMOID)
		 begin
					 SET @CERRORMSG = ' BLANK Details CAN NOT BE SAVED'
					  GOTO END_PROC
		 end


		INSERT INTO #tmpSalesOrderProcessing(XnType,Memoid,RefMemoid,ArticleCode ,Para1Code ,Para2Code ,Para3Code,Qty  )
		SELECT @SalesOrderXnType XnType ,A.MEMO_ID Memoid,a.order_id RefMemoid,  B.ARTICLE_CODE,B.PARA1_CODE ,B.PARA2_CODE ,B.PARA3_CODE ,B.QUANTITY   
		FROM PLM01106 A (nolock)
		JOIN PLD01106 B (nolock) ON A.memo_id =B.memo_id 
		WHERE A.MEMO_ID =@CMEMOID
		union all
		SELECT @SalesOrderXnType1 XnType ,A.MEMO_ID Memoid,A.MEMO_ID RefMemoid,  B.ARTICLE_CODE,B.PARA1_CODE ,B.PARA2_CODE ,B.PARA3_CODE ,B.QUANTITY   
		FROM PLM01106 A (nolock)
		JOIN PLD01106 B (nolock) ON A.memo_id =B.memo_id 
		WHERE A.MEMO_ID =@CMEMOID

	   	Exec Sp3s_SalesOrderProcessing_PLM
			     @nUpdateMode=@NMODE,
				 @cmemoid=@CMEMOID,
				 @CERRORMSG=@CERRORMSG output 
            
			if isnull(@CERRORMSG,'')<>''
			GOTO END_PROC


if @NMODE=1
begin
        IF ISNULL(@CFIRSTNO,'')=''
	       SET @CFIRSTNO=@CMEMONOVAL

		delete from #TMPDNSUPPLIER where order_id =@CORDERID 
		IF EXISTS (SELECT TOP  1 'U' FROM #TMPDNSUPPLIER)
		   GOTO LBLGENPL

      IF ISNULL(@cLastNo,'')=''
	       SET @cLastNo=@CMEMONOVAL

		if @CFIRSTNO<>@cLastNo
		set @cstatus='memo:'+@CFIRSTNO+ ' to ' +@cLastNo +' Generated '
	   

end

END TRY
      
BEGIN CATCH
	 SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()
	 GOTO END_PROC
END CATCH
   
END_PROC:

   IF @@TRANCOUNT>0
   BEGIN
		IF ISNULL(@CERRORMSG,'')=''
		   commit TRANSACTION
		ELSE
		   ROLLBACK 	
   END 

   IF ISNULL(@CERRORMSG,'')='' AND 1=1
	  BEGIN
	      print 'delete'
		  Delete  from PLM_PLD01106_UPLOAD where sp_id=@NSPID
		  Delete  from PLM_PLM01106_UPLOAD where sp_id=@NSPID
      END		
		  
   SELECT ISNULL(@CERRORMSG,'') AS ERRMSG,@MEMOID MEMO_ID,@cstatus As Status
   SET NOCOUNT OFF
END
--END OF PROCEDURE SAVETRAN_PLM

