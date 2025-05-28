CREATE PROCEDURE SP3S_GET_XPERTREP_PAYMODEEXPR
@dFromDt DATETIME,
@dToDt DATETIME,
@cPaymodeColsStru VARCHAR(2000) OUTPUT,
@cPaymodeColsExpr VARCHAR(2000) OUTPUT
AS
BEGIN	
		DECLARE @CPAYMODECODE CHAR(7),@bPaymodeGrpReqd BIT,@bPaymodeReqd BIT,
				@CPAYMODENAME VARCHAR(1000),@bPaymodeEntry bit,@cUpdCols VARCHAR(2000),
				@COUTPUT NVARCHAR(MAX),	@CCMD NVARCHAR(MAX),
				@CPAYMODESTR NVARCHAR(MAX),@cXnType VARCHAR(100),@cStruColName VARCHAR(200)
				
		SELECT @CCMD='',@COUTPUT='',@cPaymodeColsStru='',@cPaymodeColsExpr=''
		

		UPDATE a SET payment_grp_reqd=1 FROM #rep_det_paymodes a 
		JOIN #rep_det b ON 1=1 WHERE b.col_expr='Payment_Groups'

		UPDATE a SET payment_mode_reqd=1 FROM #rep_det_paymodes a 
		JOIN #rep_det b ON 1=1 WHERE b.col_expr='payment_modes'

		SELECT TOP 1 paymode_code,convert(bit,0) payment_mode,convert(bit,0) payment_grp
		INTO #tmpPaymodes FROM paymode_mst WHERE 1=2


		WHILE EXISTS (SELECT TOP 1 * FROM #rep_det_paymodes WHERE  data_processed=0)
		BEGIN
			SELECT @COUTPUT='',@cUpdCols=''
				
			SELECT TOP 1 @cXnType=xn_type,@bPaymodeReqd=ISNULL(payment_mode_reqd,0),
			@bPaymodeGrpReqd=ISNULL(payment_grp_reqd,0)
			FROM #rep_det_paymodes WHERE data_processed=0

			print 'Processing Paymodes for Xntype:'+@cXnType
			DELETE FROM #tmpPaymodes
			
			IF @cXnType='Retail Sale' AND @bPaymodeReqd=1
				INSERT INTO #tmpPaymodes (paymode_code,payment_mode)
				SELECT DISTINCT paymode_code,1  FROM  paymode_xn_det a (NOLOCK)
				JOIN cmm01106 b (NOLOCK) ON a.memo_id=b.cm_id
				WHERE cm_dt BETWEEN @dFromDt AND @dToDt AND xn_type='SLS'
			
			IF @cXnType='Wholesale' AND @bPaymodeReqd=1
				INSERT INTO #tmpPaymodes (paymode_code,payment_mode)
				SELECT DISTINCT paymode_code,1 FROM  paymode_xn_det a (NOLOCK)
				JOIN inm01106 b (NOLOCK) ON a.memo_id=b.inv_id
				WHERE inv_dt BETWEEN @dFromDt AND @dToDt AND xn_type='WSL'
			
			IF @cXnType='Retail Sale' AND @bPaymodeGrpReqd=1
				INSERT INTO #tmpPaymodes (paymode_code,payment_grp)
				SELECT DISTINCT paymode_grp_code,1 FROM  paymode_xn_det a (NOLOCK)
				JOIN cmm01106 b (NOLOCK) ON a.memo_id=b.cm_id
				JOIN paymode_mst c (NOLOCK) ON c.paymode_code=a.paymode_code
				WHERE cm_dt BETWEEN @dFromDt AND @dToDt AND xn_type='SLS'
			
			IF @cXnType='Wholesale' AND @bPaymodeGrpReqd=1
				INSERT INTO #tmpPaymodes (paymode_code,payment_grp)
				SELECT DISTINCT paymode_grp_code,1 FROM  paymode_xn_det a (NOLOCK)
				JOIN inm01106 b (NOLOCK) ON a.memo_id=b.inv_id
				JOIN paymode_mst c (NOLOCK) ON c.paymode_code=a.paymode_code
				WHERE inv_dt BETWEEN @dFromDt AND @dToDt AND xn_type='WSL'
			

			WHILE EXISTS (SELECT TOP 1 * FROM #tmpPaymodes)
			BEGIN

				SELECT TOP 1 @cPaymodeCode=paymode_code,@bPaymodeEntry=ISNULL(payment_mode,0) FROM #tmpPaymodes

				print 'Processing Paymodes for Xntype:'+@cXnType+' Paymode code:'+@cPaymodeCode

				IF @bPaymodeEntry=1
					SELECT TOP 1 @cPaymodeName=paymode_name FROM paymode_mst (NOLOCK) WHERE paymode_code=@CPAYMODECODE
				ELSE
					SELECT TOP 1 @cPaymodeName=paymode_grp_name FROM paymode_grp_mst (NOLOCK) WHERE paymode_grp_code=@CPAYMODECODE
				
				SET @cStruColName='['+@cPaymodeName+(CASE WHEN @bPaymodeEntry=0 THEN '_GRP' ELSE '' END)+']'

				IF CHARINDEX(@cStruColName,@cPaymodeColsStru)=0
					SELECT @cPaymodeColsStru=@cPaymodeColsStru+(CASE WHEN  @cPaymodeColsStru<>'' THEN ',' ELSE '' END)+
					'CONVERT(NUMERIC(14,2),0) AS '+@cStruColName,
					@cPaymodeColsExpr=@cPaymodeColsExpr+(CASE WHEN  @cPaymodeColsExpr<>'' THEN ',' ELSE '' END)+'SUM('+@cStruColName+') AS '+@cStruColName

				SET @COUTPUT=@COUTPUT+(CASE WHEN @COUTPUT<>'' THEN ',' ELSE '' END)+ N'SUM(CASE WHEN pm.'+(CASE WHEN @bPaymodeEntry=1 THEN 'PAYMODE_CODE' ELSE 'paymode_grp_code' END)
				+'='''+@CPAYMODECODE+''' THEN AMOUNT ELSE 0 END)  AS '+@cStruColName

				SET @cUpdCols=@cUpdCols+(CASE WHEN @cUpdCols<>'' THEN ',' ELSE '' END)+@cStruColName+'=b.'+@cStruColName

				DELETE FROM #tmpPaymodes WHERE paymode_code=@cPaymodeCode
			END

			UPDATE #rep_det_paymodes SET paymode_expr=@COUTPUT,paymode_updcols=@cUpdCols, data_processed=1
			WHERE xn_type=@cXnType
		END

					
END
