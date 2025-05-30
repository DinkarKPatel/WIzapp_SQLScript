CREATE PROCEDURE SP3S_EOSS_SCHEMES_3
(
	@CSCHEMEDETROWID VARCHAR(50),
	@CSLSTITLE VARCHAR(500),
	@CROUNDITEMLEVEL VARCHAR(5),
	@CJOINSTRBUY VARCHAR(MAX),
	@CJOINSTRGET VARCHAR(MAX),
	@CPICKSLRDISCMODE VARCHAR(5),
	@CERRMSG VARCHAR(MAX) OUTPUT
)
AS 
BEGIN

	DECLARE @NBUYQTY NUMERIC(10,2),@NGETAMT NUMERIC(10,2),@NGETQTY NUMERIC(10,2),
			@NREQGETQTY NUMERIC(10,2),@CPRODUCTCODE VARCHAR(50),@NMRP NUMERIC(10,2),@NQTY NUMERIC(10,2),
			@CCMDROWID VARCHAR(50),@NLOOPCNT INT,@NMODE INT,@BQUALIFIED BIT,
			@CROWID VARCHAR(100),@NSTEP INT,@NAMT NUMERIC(10,2),
			@CMRPORDER VARCHAR(10),@NREQBUYAMT NUMERIC(10,2),@BRETRY2NDCASE BIT,
			@CCMD NVARCHAR(MAX),@NDISCMODE INT,@NDISCPCT NUMERIC(7,3),@NDISCAMT NUMERIC(10,2),
			@NNETRATE NUMERIC(10,2),@CBUYFILTER VARCHAR(MAX),@CGETFILTER VARCHAR(MAX),
			@CADDFILTER VARCHAR(MAX),@CORGADDFILTER VARCHAR(MAX),@NFILTERMODE INT,
			@BPROCESSSLRENTRY BIT,@NGETFILTERMODE INT,@CAPPLYSCHEMEONHIGHERPRICE VARCHAR(2),
			@BAPPLYSCHEMEONDISCITEMS BIT,@nAddnlDiscountBaseAmt NUMERIC(10,0),@nAddnlLoop NUMERIC(1,0),
			@nBuyAmt NUMERIC(10,2),@bCutSizeScheme BIT
	
	SELECT @BPROCESSSLRENTRY=0,@nAddnlLoop=0

	DECLARE @CENABLEOPTIMIZEDSCHEMES VARCHAR(2)
	SELECT TOP 1 @CENABLEOPTIMIZEDSCHEMES=VALUE FROM CONFIG WHERE CONFIG_OPTION='ENABLE_OPTIMIZED_EOSS_SCHEMES'		
	
	set @CENABLEOPTIMIZEDSCHEMES=isnull(@CENABLEOPTIMIZEDSCHEMES,'')
				
START_PROC:
	SELECT @NBUYQTY=0,@CPRODUCTCODE='',@NGETAMT=0,@NMRP=0,@NQTY=0,@NGETQTY=0,
		   @CCMDROWID='',@NLOOPCNT=0,@NREQGETQTY=0,
		   @NMODE=0,@BQUALIFIED=0,@CROWID='',@NSTEP=0,@NAMT=0,@CMRPORDER='',
		   @NREQBUYAMT=0,@BRETRY2NDCASE=0,@CCMD='',@NDISCMODE=0,@CBUYFILTER='',
		   @CGETFILTER='',@CADDFILTER='',@NFILTERMODE=0,@NDISCPCT=0,@NDISCAMT=0,
		   @NNETRATE=0,@NGETFILTERMODE=0,@CORGADDFILTER='',@nBuyAmt=0
			

	--IF @CSLSTITLE='BUY 1 GET 1'
	--	SELECT 'START CHECK SCHEMES_3 FOR BUY 1 GET 1',(CASE WHEN @BPROCESSSLRENTRY=1 THEN 'SLR' ELSE 'SLS' END) AS XN_TYPE,* FROM #TMPCMD
	
	SELECT @BAPPLYSCHEMEONDISCITEMS=ISNULL(APPLY_SCHEME_ON_DISCOUNTED_ITEMS,0),@nAddnlDiscountBaseAmt=ISNULL(additional_discount_base_amount,0)
	FROM SCHEME_SETUP_DET WHERE ROW_ID=@CSCHEMEDETROWID
	
	IF NOT EXISTS (SELECT TOP 1 * FROM #TMPCMD A WHERE (@BAPPLYSCHEMEONDISCITEMS=1 AND (ABS(A.QUANTITY)-A.SCHEME_APPLIED_QTY>0 
				   OR A.SCHEME_SETUP_DET_ROW_ID<>@CSCHEMEDETROWID))OR (@BAPPLYSCHEMEONDISCITEMS=0 
				   AND ABS(A.QUANTITY)-A.SCHEME_APPLIED_QTY>0))
		GOTO END_PROC

	IF @BPROCESSSLRENTRY=1
		SET @CORGADDFILTER='A.QUANTITY<0'
	ELSE
		SET @CORGADDFILTER='A.QUANTITY>0'
	
	IF CURSOR_STATUS('GLOBAL','SCHEMECUR') IN (0,1)
	BEGIN
		CLOSE SCHEMECUR
		DEALLOCATE SCHEMECUR
	END

BEGIN TRY        
	
	PRINT 'CHECK SCHEME SP3S_EOSS_SCHEMES_3' 	
	SET @NSTEP=10
		
	SELECT @CMRPORDER='',@BQUALIFIED=0,@BRETRY2NDCASE=0
		
	IF OBJECT_ID('TEMPDB..#TEMPCMDPREV','U') IS NOT NULL
		DROP TABLE #TEMPCMDPREV

	IF OBJECT_ID('TEMPDB..#TMPCMDSCHEMES','U') IS NOT NULL
		DROP TABLE #TMPCMDSCHEMES
	
	SET @NSTEP=12
	SELECT PRODUCT_CODE,MRP,QUANTITY,CMD_ROW_ID AS ROW_ID,CONVERT(INT,0) AS MODE,
	CONVERT(NUMERIC(10,2),0) AS DISCOUNT_AMOUNT,QUANTITY AS GET_QUANTITY,
	QUANTITY AS SCHEME_APPLIED_QTY INTO #TMPCMDSCHEMES FROM #TMPCMD WHERE 1=2 

	SELECT @CBUYFILTER=(CASE WHEN FILTER_MODE IN (0,1)  AND @CENABLEOPTIMIZEDSCHEMES<>'1'  THEN  BUY_FILTER_CRITERIA ELSE '1=1' END),
		   @CGETFILTER=(CASE WHEN GET_FILTER_MODE IN (0,1) AND @CENABLEOPTIMIZEDSCHEMES<>'1'  THEN  GET_FILTER_CRITERIA ELSE '1=1' END),
		   @NDISCMODE=DISC_METHOD,@NDISCPCT=DISCOUNT_PERCENTAGE,@NDISCAMT=DISCOUNT_AMOUNT,@NNETRATE=NET_PRICE,
		   @NFILTERMODE=FILTER_MODE,@NGETFILTERMODE=GET_FILTER_MODE,@bCutSizeScheme=isnull(cut_Size_scheme,0)
	FROM SCHEME_SETUP_DET WHERE ROW_ID=@CSCHEMEDETROWID
		
	SET @NSTEP=14
	
	IF @NFILTERMODE NOT IN (0,1)
		SELECT @CADDFILTER=@CORGADDFILTER+' AND SLSDET.ROW_ID='''+@CSCHEMEDETROWID+''''
	ELSE
		SELECT @CADDFILTER=@CORGADDFILTER+' AND 1=1'
	
	IF @bCutSizeScheme=1
		SELECT @CADDFILTER=@CADDFILTER+' AND a.cut_size=1'

	
   	SET @CCMD=N' SELECT A.PRODUCT_CODE,A.MRP,'+(CASE WHEN @BAPPLYSCHEMEONDISCITEMS=1 THEN 'ABS(A.QUANTITY) ' ELSE 
   				 '(ABS(A.QUANTITY)-A.SCHEME_APPLIED_QTY) ' END)+'*(CASE WHEN A.QUANTITY<0 THEN -1 ELSE 1 END),
   				 A.CMD_ROW_ID AS ROW_ID,1 AS MODE,
				 0 AS DISCOUNT_AMOUNT,0 AS GET_QUANTITY,0 AS SCHEME_APPLIED_QTY FROM #TMPCMD A 
				 JOIN #CMDITV ITV ON ITV.PRODUCT_CODE=A.PRODUCT_CODE'+@CJOINSTRBUY+' WHERE '+
				 (CASE WHEN @BAPPLYSCHEMEONDISCITEMS=1 THEN ' (ABS(A.QUANTITY)-A.SCHEME_APPLIED_QTY>0 OR A.SCHEME_SETUP_DET_ROW_ID<>'''+@CSCHEMEDETROWID+''') AND '
					   ELSE 'ABS(A.QUANTITY)-A.SCHEME_APPLIED_QTY>0 AND A.DISCOUNT_PERCENTAGE=0 AND ISNULL(A.SCHEME_SETUP_DET_ROW_ID,'''')='''' AND ' END)+@CBUYFILTER+' AND '+ @CADDFILTER
	----- Date :20-12-2018 Had to take A.SCHEME_SETUP_DET_ROW_ID='' mark because problem started coming at Suvidha in which case they had created a zero percent title
	----- which was being considered in Buy n Get n Scheme						   
				 
	
	PRINT @CCMD
				 
	INSERT #TMPCMDSCHEMES
	EXEC SP_EXECUTESQL @CCMD
	
	SET @NSTEP=20


	IF @NGETFILTERMODE NOT IN (0,1)
		SELECT @CADDFILTER=@CORGADDFILTER+' AND SLSDET.ROW_ID='''+@CSCHEMEDETROWID+''''
	ELSE
		SELECT @CADDFILTER=@CORGADDFILTER+' AND 1=1'

	IF @bCutSizeScheme=1
		SELECT @CADDFILTER=@CADDFILTER+' AND a.cut_size=1'
		
	SET @CCMD=N' SELECT A.PRODUCT_CODE,A.MRP,'+(CASE WHEN @BAPPLYSCHEMEONDISCITEMS=1 THEN 'ABS(A.QUANTITY) ' ELSE 
   				 '(ABS(A.QUANTITY)-A.SCHEME_APPLIED_QTY) ' END)+'*(CASE WHEN A.QUANTITY<0 THEN -1 ELSE 1 END),
				 A.CMD_ROW_ID AS ROW_ID,2 AS MODE,0 AS DISCOUNT_AMOUNT,0 AS GET_QUANTITY,0 AS SCHEME_APPLIED_QTY FROM #TMPCMD A
				 JOIN #CMDITV ITV ON ITV.PRODUCT_CODE=A.PRODUCT_CODE '+@CJOINSTRGET+' WHERE '+
				 (CASE WHEN @BAPPLYSCHEMEONDISCITEMS=1 THEN ' (ABS(A.QUANTITY)-A.SCHEME_APPLIED_QTY>0 OR A.SCHEME_SETUP_DET_ROW_ID<>'''+@CSCHEMEDETROWID+''') AND '
					   ELSE 'ABS(A.QUANTITY)-A.SCHEME_APPLIED_QTY>0  AND A.DISCOUNT_PERCENTAGE=0  AND ISNULL(A.SCHEME_SETUP_DET_ROW_ID,'''')='''' AND ' END)+@CGETFILTER+' AND '+ @CADDFILTER
	----- Date :20-12-2018 Had to take A.SCHEME_SETUP_DET_ROW_ID='' mark because problem started coming at Suvidha in which case they had created a zero percent title
	----- which was being considered in Buy n Get n Scheme						   
				 
	INSERT #TMPCMDSCHEMES
	EXEC SP_EXECUTESQL @CCMD
	

	--IF @CSLSTITLE='BUY 5 QTY GET 2 FREE'
		--SELECT 'BUY 5 QTY GET 2 FREE FINAL',* FROM #TMPCMD
		
	IF NOT EXISTS (SELECT TOP 1 * FROM #TMPCMDSCHEMES WHERE MODE=1) OR
	   NOT EXISTS (SELECT TOP 1 * FROM #TMPCMDSCHEMES WHERE MODE=2)
	BEGIN   
		IF @BPROCESSSLRENTRY=0 AND @CPICKSLRDISCMODE<>'3'
		BEGIN
			SET @BPROCESSSLRENTRY=1
			GOTO START_PROC
		END	
		ELSE
			GOTO END_PROC	
	END
	
	SET @NSTEP=25

	SELECT @NBUYQTY= BUY_QUANTITY ,@NGETQTY=GET_QUANTITY FROM SCHEME_SETUP_DET 
	WHERE ROW_ID=@CSCHEMEDETROWID
	
	SELECT * INTO #TEMPCMDPREV FROM #TMPCMDSCHEMES
		
	SET @NREQGETQTY=0
			
	SET @NSTEP=30
	
	IF @nAddnlDiscountBaseAmt>0 AND @nAddnlLoop=0
		SET @NGETQTY=@NGETQTY+1
		
	DECLARE SCHEMECUR CURSOR FOR SELECT PRODUCT_CODE,MRP,QUANTITY,ROW_ID,MODE FROM
	#TMPCMDSCHEMES WHERE MODE=2 ORDER BY MRP

	
	OPEN SCHEMECUR
	FETCH NEXT FROM SCHEMECUR INTO @CPRODUCTCODE,@NMRP,@NQTY,@CCMDROWID,@NMODE
	WHILE @@FETCH_STATUS=0
	BEGIN
		SET @NSTEP=40
		SET @NLOOPCNT=1
		WHILE @NLOOPCNT<=ABS(@NQTY)
		BEGIN
			SET @NREQGETQTY=@NREQGETQTY+1
		    
		    SET @NSTEP=50
			UPDATE #TMPCMDSCHEMES SET QUANTITY=ABS(QUANTITY)-1,GET_QUANTITY=GET_QUANTITY+
			(CASE WHEN @BPROCESSSLRENTRY=1 THEN -1 ELSE  1 END),
			SCHEME_APPLIED_QTY=SCHEME_APPLIED_QTY+1
			WHERE ROW_ID=@CCMDROWID
		    
		    IF @nAddnlDiscountBaseAmt>0
				SELECT @nBuyAmt=@nBuyAmt+ @NMRP-(CASE WHEN @NDISCMODE=1 THEN  
					(CASE WHEN @CROUNDITEMLEVEL='1' THEN ROUND(@NMRP*@NDISCPCT/100,0) ELSE @NMRP*@NDISCPCT/100 END)
					WHEN @NDISCMODE=2 THEN (CASE WHEN @NMRP-@NNETRATE>0 THEN @NMRP-@NNETRATE ELSE @NMRP END)
					ELSE (CASE WHEN @NMRP-@NDISCAMT>0 THEN @NDISCAMT ELSE @NMRP END) END)
				
		    IF @NREQGETQTY=@NGETQTY
			BEGIN
				SET @BQUALIFIED=1				
				BREAK
			END	
			
			SET @NLOOPCNT=@NLOOPCNT+1
		END										
		
		IF @BQUALIFIED=1
			BREAK
			
		FETCH NEXT FROM SCHEMECUR INTO @CPRODUCTCODE,@NMRP,@NQTY,@CCMDROWID,@NMODE
	END
	CLOSE SCHEMECUR
	DEALLOCATE SCHEMECUR

	--select 'after get', @BQUALIFIED as BQUALIFIED,@NREQGETQTY,@NGETQTY,@nAddnlDiscountBaseAmt

	IF @BQUALIFIED=0
		GOTO EXIT_PROC
	
	SET @NSTEP=70
	SET @BQUALIFIED=0
	
	--SELECT 'chck buy',PRODUCT_CODE,MRP,QUANTITY,ROW_ID FROM #TMPCMDSCHEMES WHERE MODE=1 AND QUANTITY>0 
	
	--select @NBUYQTY as org_NBUYQTY
	DECLARE SCHEMECUR CURSOR FOR SELECT PRODUCT_CODE,MRP,QUANTITY,ROW_ID FROM
	#TMPCMDSCHEMES WHERE MODE=1 AND QUANTITY<>0 
	ORDER BY MRP DESC
	
	OPEN SCHEMECUR
	FETCH NEXT FROM SCHEMECUR INTO @CPRODUCTCODE,@NMRP,@NQTY,@CCMDROWID
	
	WHILE @@FETCH_STATUS=0
	BEGIN
		SET @NSTEP=80
		SET @NLOOPCNT=1
		WHILE @NLOOPCNT<=ABS(@NQTY)
		BEGIN
			SET @NBUYQTY=@NBUYQTY-1
		    SET @nBuyAmt=@nBuyAmt+@nMrp
		    
		    SET @NSTEP=90

			UPDATE #TMPCMDSCHEMES SET SCHEME_APPLIED_QTY=SCHEME_APPLIED_QTY+1
			WHERE ROW_ID=@CCMDROWID
		    
			IF @NBUYQTY<=0 
			BEGIN
				--select @nBuyAmt,@nAddnlDiscountBaseAmt as nAddnlDiscountBaseAmt,@nAddnlLoop,@NGETQTY as ngetqty
				IF (@nBuyAmt>=@nAddnlDiscountBaseAmt OR @nAddnlLoop=1)
					SET @BQUALIFIED=1				
					
				BREAK
			END
		    	
			SET @NLOOPCNT=@NLOOPCNT+1
		END										
		
		SET @NSTEP=100
		IF @BQUALIFIED=1 OR @NBUYQTY<=0 
			BREAK		
	
		FETCH NEXT FROM SCHEMECUR INTO @CPRODUCTCODE,@NMRP,@NQTY,@CCMDROWID
	END
	
	--select 'after buy',@nBuyAmt as nBuyAmt, @BQUALIFIED as BQUALIFIED,@NREQGETQTY,@NGETQTY,@nAddnlDiscountBaseAmt
	
	SET @NSTEP=110
	
	CLOSE SCHEMECUR
	DEALLOCATE SCHEMECUR
	
	GOTO EXIT_PROC
END TRY
	
BEGIN CATCH
	  PRINT 'CATCH START'       
	  SET @CERRMSG='P:SP3S_EOSS_SCHEMES_3, STEP:'+LTRIM(RTRIM(STR(@NSTEP)))+', MESSAGE:'+ERROR_MESSAGE()        
	  GOTO END_PROC
END CATCH
	
EXIT_PROC:
	
	--select @BQUALIFIED as BQUALIFIED,'check #tmpcmdschemes',* from #TMPCMDSCHEMES
		
	IF ISNULL(@CERRMSG,'')=''
	BEGIN
		
		IF @BQUALIFIED=0
		BEGIN
			UPDATE #TMPCMDSCHEMES SET DISCOUNT_AMOUNT=0
			
			--IF @nAddnlDiscountBaseAmt>0
			--	SET @nAddnlLoop=@nAddnlLoop+1
		END	
		ELSE
		BEGIN
			
			--IF @CSLSTITLE='BUY 1 GET 1'
			--	SELECT 'QUALIFIED CHECK SCHEMES_3 FOR BUY 1 GET 1',(CASE WHEN @BPROCESSSLRENTRY=1 THEN 'SLR' ELSE 'SLS' END) AS XN_TYPE,* FROM #TMPCMD
			
			--select 'check #tmpcmdschemes',* from #TMPCMDSCHEMES
			
			UPDATE #TMPCMDSCHEMES SET DISCOUNT_AMOUNT=(CASE WHEN @NDISCMODE=1 THEN  
				(CASE WHEN @CROUNDITEMLEVEL='1' THEN ROUND(MRP*@NDISCPCT/100,0) ELSE MRP*@NDISCPCT/100 END)
				WHEN @NDISCMODE=2 THEN (CASE WHEN MRP-@NNETRATE>0 THEN MRP-@NNETRATE ELSE MRP END)
				ELSE (CASE WHEN MRP-@NDISCAMT>0 THEN @NDISCAMT ELSE MRP END) END)*GET_QUANTITY
			WHERE GET_QUANTITY<>0
			
			DECLARE @CBNGNROWID VARCHAR(50)
			SET @CBNGNROWID=NEWID()
			
			UPDATE #TMPCMD SET DISCOUNT_AMOUNT=#TMPCMD.DISCOUNT_AMOUNT+ABS(B.DISCOUNT_AMOUNT)*
			(CASE WHEN @BPROCESSSLRENTRY=1 THEN -1 ELSE 1 END) ,
			SLS_TITLE=SLS_TITLE+(CASE WHEN SLS_TITLE<>'' THEN ',' ELSE '' END)+@CSLSTITLE,
			SCHEME_SETUP_DET_ROW_ID=@CSCHEMEDETROWID,
			SCHEME_APPLIED_QTY=#TMPCMD.SCHEME_APPLIED_QTY+B.SCHEME_APPLIED_QTY,
			BNGN_QTY=BNGN_QTY+B.SCHEME_APPLIED_QTY,
			BNGN_DISCOUNT=BNGN_DISCOUNT+B.DISCOUNT_AMOUNT,
			BNGN_ROW_ID=@CBNGNROWID
			FROM #TMPCMDSCHEMES B WHERE B.ROW_ID=#TMPCMD.CMD_ROW_ID 
			AND B.SCHEME_APPLIED_QTY<>0
			
			----Need to recalculate this again because of Discount amount validation being failed 
			---- on Final save
			UPDATE  #TMPCMD SET DISCOUNT_AMOUNT=round(mrp*quantity*DISCOUNT_PERCENTAGE/100,2)

			UPDATE #TMPCMD SET DISCOUNT_PERCENTAGE=ABS(ROUND((DISCOUNT_AMOUNT/(MRP*QUANTITY))*100,2)),
			NET=(MRP*QUANTITY)-DISCOUNT_AMOUNT
		END		
		
		
		--IF @@SPID=237		
		--	SELECT 'AFTER APPLYING SP3S_EOSS_SCHEMES_3',* FROM #TMPCMD
		
		--IF @@SPID='118a92271f0-177e-4be0-b385-193f90cb218c'
			
		--SELECT 'COME OUT OF LOOP-1'	
		IF @BPROCESSSLRENTRY=0 AND ((@BQUALIFIED=1 AND (@nAddnlDiscountBaseAmt=0 OR @nAddnlLoop<=1))
								  OR (@BQUALIFIED=0 AND @nAddnlDiscountBaseAmt>0 AND @nAddnlLoop<=1))	
		BEGIN
			
			--SELECT 'COME OUT OF LOOP-2',@BQUALIFIED,@nAddnlLoop	
			IF @nAddnlDiscountBaseAmt>0
				SET @nAddnlLoop=@nAddnlLoop+1
								
			
			IF EXISTS (SELECT TOP 1 * FROM #TMPCMD A WHERE (@BAPPLYSCHEMEONDISCITEMS=1 AND (A.QUANTITY-A.SCHEME_APPLIED_QTY>0 
				   OR A.SCHEME_SETUP_DET_ROW_ID<>@CSCHEMEDETROWID))OR (@BAPPLYSCHEMEONDISCITEMS=0 
				   AND A.QUANTITY-A.SCHEME_APPLIED_QTY>0))
				GOTO START_PROC
			
				
		END
		ELSE
		IF @BPROCESSSLRENTRY=1 AND @BQUALIFIED=1
		BEGIN
			--SELECT 'COME OUT OF LOOP-2'
			IF EXISTS (SELECT TOP 1 * FROM #TMPCMD A WHERE (@BAPPLYSCHEMEONDISCITEMS=1 AND (ABS(A.QUANTITY)-A.SCHEME_APPLIED_QTY>0 
				   OR A.SCHEME_SETUP_DET_ROW_ID<>@CSCHEMEDETROWID))OR (@BAPPLYSCHEMEONDISCITEMS=0 
				   AND ABS(A.QUANTITY)-A.SCHEME_APPLIED_QTY>0) AND QUANTITY<0)
				GOTO START_PROC		
		END		
		
		IF @BPROCESSSLRENTRY=0 AND @CPICKSLRDISCMODE<>'3'
		BEGIN
			--SELECT 'COME OUT OF LOOP-3'
			SET @BPROCESSSLRENTRY=1
			GOTO START_PROC
		END	
		ELSE
		BEGIN
			--SELECT 'COME OUT OF LOOP-4'
			GOTO END_PROC
		END		
	END	
	ELSE
	BEGIN
		--SELECT 'COME OUT OF LOOP-5'
		GOTO END_PROC
	END
END_PROC:

	--select @BQUALIFIED as BQUALIFIED,'check at end #tmpcmdschemes',* from #TMPCMDSCHEMES

	--IF @CSLSTITLE='BUY 5 QTY GET 2 FREE'
	--	SELECT 'LAST STEP :'+STR(@NSTEP)	
END
----- END OF PROCEDURE SP3S_EOSS_SCHEMES_3