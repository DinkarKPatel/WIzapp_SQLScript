CREATE PROCEDURE SP3S_GETDATA_ARS_REORDERS
@nQueryId NUMERIC(2,0),
@cSeasonId CHAR(7)=''
AS
BEGIN
	DECLARE @cErrormsg VARCHAR(MAX)
	
	
	DECLARE @dFromDt DATETIME,@dToDt DATETIME,@cArsId VARCHAR(7),@bFlag BIT,@cRfDbName VARCHAR(500),@cCmd NVARCHAR(MAX),
	@cJoinStr VARCHAR(MAX),@cCols VARCHAR(2000),@cColsGrp VARCHAR(2000),@cHoLocId CHAR(2)
	
	SET @cRfDbName=DB_NAME()+'.DBO.'
	
	DECLARE @tPlan TABLE (ars_id CHAR(7))
		
	DECLARE @tPlanWiseStk TABLE (ars_id CHAR(7),dept_id VARCHAR(5),section_code CHAR(7),sub_section_code CHAR(7),
	article_code CHAR(9),para1_code CHAR(7),para3_code CHAR(7),para4_code CHAR(7),
	para5_code CHAR(7),para6_code CHAR(7),cbs NUMERIC(14,2),sos_variance NUMERIC(10,0),
	reorder_variance NUMERIC(10,0),maxlevel_variance NUMERIC(10,0),wh_stock NUMERIC(14,2),
	MINIMUM_ORDER NUMERIC(10,0),MINIMUM_REORDER NUMERIC(10,0),MAXIMUM_ORDER NUMERIC(10,0))
	
	SELECT TOP 1 @cHoLocId=value FROM config WHERE config_option='ho_location_id'

IF @nQueryId=1
	GOTO lblGetPlanwiseVariance	
ELSE
IF @nQueryId=2
	GOTO lblGetReOrderData


lblGetPlanwiseVariance:		
	INSERT @tPlan (ars_id)
	SELECT ARS_ID FROM ars_mst WHERE SEASON_ID=@cSeasonId

	IF NOT EXISTS (SELECT TOP 1 * FROM @tPlan)
	BEGIN
		SET @cErrormsg='No valid ARS Plan found for given Season....Please check'
		GOTO END_PROC
	END		

lblGetReOrderData:
	
	print 'step1'
	SET @bFlag=0
		
	WHILE @bFlag=0
	BEGIN	
		SET @cArsId=''
		
		print 'step2'	
		SELECT TOP 1 @cArsId=ars_id FROM @tPlan
		
		IF ISNULL(@cArsId,'')=''
			BREAK
		
		print 'step3'		
		SET @cJoinStr=' JOIN ars_det ON a.dept_id=ars_det.dept_id AND '
		
		SELECT TOP 1  @cJoinStr=@cJoinstr+' ars_det.article_code=sku.article_code AND '
		FROM ARS_DET WHERE ARS_ID=@cArsId AND ISNULL(ars_det.article_code,'')<>''

		SELECT TOP 1  @cJoinStr=@cJoinstr+' ars_det.para1_code=sku.para1_code AND '
		FROM ARS_DET WHERE ARS_ID=@cArsId AND ISNULL(ars_det.para1_code,'')<>''
		
		print 'step4'
		SELECT TOP 1  @cJoinStr=@cJoinstr+' ars_det.para3_code=sku.para3_code AND '
		FROM ARS_DET WHERE ARS_ID=@cArsId AND ISNULL(ars_det.para3_code,'')<>''

		SELECT TOP 1  @cJoinStr=@cJoinstr+' ars_det.para4_code=sku.para4_code AND '
		FROM ARS_DET WHERE ARS_ID=@cArsId AND ISNULL(ars_det.para4_code,'')<>''

		SELECT TOP 1  @cJoinStr=@cJoinstr+' ars_det.para5_code=sku.para5_code AND '
		FROM ARS_DET WHERE ARS_ID=@cArsId AND ISNULL(ars_det.para5_code,'')<>''

		SELECT TOP 1  @cJoinStr=@cJoinstr+' ars_det.para6_code=sku.para6_code AND '
		FROM ARS_DET WHERE ARS_ID=@cArsId AND ISNULL(ars_det.para6_code,'')<>''				

		SELECT TOP 1  @cJoinStr=@cJoinstr+' ars_det.section_code=sd.section_code AND '
		FROM ARS_DET WHERE ARS_ID=@cArsId AND ISNULL(ars_det.section_code,'')<>''

		SELECT TOP 1  @cJoinStr=@cJoinstr+' ars_det.sub_section_code=sd.sub_section_code '
		FROM ARS_DET WHERE ARS_ID=@cArsId AND ISNULL(ars_det.sub_section_code,'')<>''
		
		print 'step5'
		
		SELECT @cCols='',@cColsGrp=''

		SELECT @cCols=@cCols+(CASE WHEN CHARINDEX('section_code',@cJoinStr)>0 THEN 'sd.section_code,' ELSE ''''' AS section_code,' END)
		SELECT @cCols=@cCols+(CASE WHEN CHARINDEX('sub_section_code',@cJoinStr)>0 THEN 'sd.sub_Section_code,' ELSE ''''' AS sub_Section_code,' END)		
		SELECT @cCols=@cCols+(CASE WHEN CHARINDEX('article_code',@cJoinStr)>0 THEN 'sku.article_code,' ELSE ''''' AS article_code,' END)
		SELECT @cCols=@cCols+(CASE WHEN CHARINDEX('para1_code',@cJoinStr)>0 THEN 'sku.para1_code,' ELSE ''''' AS para1_code,' END)
		SELECT @cCols=@cCols+(CASE WHEN CHARINDEX('para3_code',@cJoinStr)>0 THEN 'sku.para3_code,' ELSE ''''' AS para3_code,' END)
		SELECT @cCols=@cCols+(CASE WHEN CHARINDEX('para4_code',@cJoinStr)>0 THEN 'sku.para4_code,' ELSE ''''' AS para4_code,' END)
		SELECT @cCols=@cCols+(CASE WHEN CHARINDEX('para5_code',@cJoinStr)>0 THEN 'sku.para5_code,' ELSE ''''' AS para5_code,' END)
		SELECT @cCols=@cCols+(CASE WHEN CHARINDEX('para6_code',@cJoinStr)>0 THEN 'sku.para6_code,' ELSE ''''' AS para6_code' END)
		
		print 'step6'
		SELECT @cColsGrp=@cColsGrp+(CASE WHEN CHARINDEX('section_code',@cJoinStr)>0 THEN 'sd.section_code,' ELSE '' END)
		SELECT @cColsGrp=@cColsGrp+(CASE WHEN CHARINDEX('sub_section_code',@cJoinStr)>0 THEN 'sd.sub_Section_code,' ELSE '' END)		
		SELECT @cColsGrp=@cColsGrp+(CASE WHEN CHARINDEX('article_code',@cJoinStr)>0 THEN 'sku.article_code,' ELSE '' END)
		SELECT @cColsGrp=@cColsGrp+(CASE WHEN CHARINDEX('para1_code',@cJoinStr)>0 THEN 'sku.para1_code,' ELSE '' END)
		SELECT @cColsGrp=@cColsGrp+(CASE WHEN CHARINDEX('para3_code',@cJoinStr)>0 THEN 'sku.para3_code,' ELSE '' END)
		SELECT @cColsGrp=@cColsGrp+(CASE WHEN CHARINDEX('para4_code',@cJoinStr)>0 THEN 'sku.para4_code,' ELSE '' END)
		SELECT @cColsGrp=@cColsGrp+(CASE WHEN CHARINDEX('para5_code',@cJoinStr)>0 THEN 'sku.para5_code,' ELSE '' END)
		SELECT @cColsGrp=@cColsGrp+(CASE WHEN CHARINDEX('para6_code',@cJoinStr)>0 THEN 'sku.para6_code' ELSE '' END)
		
		print 'step7'								
		SET @cCols=(CASE WHEN RIGHT(@cCols,1)=',' THEN SUBSTRING(@cCols,1,LEN(@cCols)-1) ELSE @cCols END)
		
		SET @cColsGrp=(CASE WHEN RIGHT(@cColsGrp,1)=',' THEN SUBSTRING(@cColsGrp,1,LEN(@cColsGrp)-1) ELSE @cColsGrp END)
																
		SET @cJoinStr=(CASE WHEN RIGHT(@cJoinStr,4)='AND ' THEN SUBSTRING(@cJoinStr,1,LEN(@cJoinStr)-4) ELSE @cJoinStr END)														
		
		--SELECT @cCols,@cJoinStr,@cColsGrp
		
		print 'step8'
		SET @cCmd=N'SELECT ars_Det.ars_id,a.dept_id,MINIMUM_ORDER,MINIMUM_REORDER,MAXIMUM_ORDER,'+@cCols+'
		     --,SUM((CASE WHEN XN_TYPE=''OPS'' 
			 --OR (XN_TYPE IN (''WPR'',''SCF'',''OPS'',''PRD'', ''PUR'', ''CHI'', ''SLR'',''UNC'',''APR'', ''WSR'', ''PFI'', ''PFG'', ''BCG'',''MRP'',''DCI'',''PSB'',''JWR''))    
			 --THEN 1 WHEN XN_TYPE IN (''WPI'',''SCC'',''BOC'',''PRT'',''CHO'',''SLS'',''CNC'',''APP'',''WSL'',''CIP'', ''CRM'', ''DCO'',''MIP'',''CSB'',''JWI'',''DLM'') 
			 --THEN -1 ELSE 0.000 END)* XN_QTY )  AS cbs
		    ,SUM(A.STOCK_QTY+A.OPS_QTY) AS cbs
			,0,0,0
			FROM '+@cRfDbName+'VW_ARS_RF A (NOLOCK)     
			JOIN sku (NOLOCK) ON sku.product_code=a.product_code
			JOIN LOCATION C (NOLOCK) ON C.DEPT_ID=A.DEPT_ID   
			JOIN article d ON d.article_Code=sku.article_code
			JOIN sectiond sd ON sd.sub_section_code=d.sub_section_code '+@cJoinStr+' 
			WHERE --XN_DT <= '''+CONVERT(VARCHAR,GETDATE(),110)+''' 
			--AND XN_TYPE NOT IN (''SAC'',''SAU'') 
			A.XN_MODE=''STOCK''
			AND c.loc_type=1 
			AND isnull(d.stock_na,0)=0
			AND ars_det.ars_id='''+@cArsId+'''
			GROUP BY a.dept_id,ars_Det.ars_id,MINIMUM_ORDER,MINIMUM_REORDER,MAXIMUM_ORDER,'+@cColsGrp
		
		PRINT @cCmd
		
		print 'step9'
		INSERT @tPlanWiseStk (ars_id,dept_id,MINIMUM_ORDER,MINIMUM_REORDER,MAXIMUM_ORDER,
		section_code,sub_section_code,article_code,para1_code,para3_code,para4_code,para5_code,para6_code,cbs,
		sos_variance,reorder_variance,maxlevel_variance)
		EXEC SP_EXECUTESQL @cCmd			
		
		print 'step10'
		UPDATE a SET wh_stock=(SELECT SUM(cbs) FROM @tPlanWiseStk b JOIN location c ON c.dept_id=b.dept_id
							   WHERE b.section_code=a.section_code AND b.sub_section_code=a.sub_section_code
							   AND b.article_code=a.article_code AND b.para1_code=a.para1_code AND b.para3_code=a.para3_code	
							   AND b.para4_code=a.para4_code AND b.para5_code=a.para5_code
							   AND c.pur_Loc=1)
		FROM @tPlanWiseStk a
		
		print 'step11'
		UPDATE @tPlanWiseStk SET sos_variance=MINIMUM_ORDER-cbs FROM @tPlanWiseStk  WHERE cbs<minimum_order
		UPDATE @tPlanWiseStk SET reorder_variance=MINIMUM_REORDER-cbs FROM @tPlanWiseStk  WHERE cbs<MINIMUM_REORDER AND cbs>=MINIMUM_ORDER
		UPDATE @tPlanWiseStk SET maxlevel_variance=MAXIMUM_ORDER-cbs FROM @tPlanWiseStk  WHERE cbs>=MAXIMUM_ORDER
		
		print 'step12'
		DELETE FROM @tPlan WHERE ars_id=@cArsId
	END	
		
	SELECT a.* FROM @tPlanWiseStk a JOIN location b ON a.dept_id=b.dept_id
	WHERE pur_loc=0 AND a.dept_id<>@cHoLocId
	
END_PROC:		
END
