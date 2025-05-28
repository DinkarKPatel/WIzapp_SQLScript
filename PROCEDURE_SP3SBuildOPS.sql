CREATE PROCEDURE SP3SBuildOPS
(
	 @cXnID			varchar(50)
	,@nUpdateMode	numeric(2)
    ,@cInsJoinStr   VARCHAR(1000)=''
	,@cWhereclause	VARCHAR(1000)=''
	,@cRfTableName  varchar(500)=''	
	,@cErrMsg		varchar(max) output
)
AS
BEGIN
/*
XnType Filter is required during deletion from RFOPT Table because in some cases like TRO From PIM01106
,the inserted xn_id is that of wholesale invoice.
*/
	Declare @cCmd nvarchar(max),@cStep varchar(10),@cFilter varchar(1000),@cDelStr VARCHAR(1000),@cDelJoinStr VARCHAR(500)
BEGIN TRY

	DECLARE @bBuildRfopt BIT
	
	EXEC SP3S_CHKRFOPT_BUILD @bBuildRfopt OUTPUT
	
	IF @bBuildRfopt=0
		RETURN
		
	IF @cRfTableName=''
		EXEC SP3S_RFDBTABLE 'OPS',@cXnID,@cRFTABLENAME OUTPUT 
		
	--Start of Build Process for Opening Transaction
		SET @cStep=20
		/*For each Dept, last_update value should be same, if it is not same synch it first*/
		IF EXISTS(SELECT DEPT_ID 
				   FROM OPS01106 
				    GROUP BY DEPT_ID 
				     HAVING COUNT(DISTINCT LAST_UPDATE)>1)
		BEGIN		
			SET @cStep=30		     
			/*Synching Last_Update column for each location*/
			UPDATE A SET A.LAST_UPDATE = B.LAST_UPDATE 
				FROM OPS01106 A
				 JOIN (SELECT DEPT_ID,MAX(LAST_UPDATE) AS LAST_UPDATE FROM OPS01106 GROUP BY DEPT_ID) B 
				  ON A.DEPT_ID = B.DEPT_ID			
		END
		
		SET @cStep=35
		/*If UpdateMode is 0 Consider all data*/		     
		IF @nUpdateMode=0
		BEGIN
			SET @CCMD=N'INSERT '+@cRFTABLEName+'
					(DEPT_ID,XN_DT,PRODUCT_CODE,BIN_ID,ops_qty) 
				     SELECT A.DEPT_ID,XN_DT,   
						    A.PRODUCT_CODE, 
						   SUM(A.QUANTITY_OB) AS XN_QTY 
						   ,ISNULL(A.BIN_ID, ''000'')  AS [BIN_ID]
						 FROM OPS01106 A
						 JOIN sku b (NOLOCK) ON a.product_code=b.product_code
						 JOIN article c (NOLOCK) ON c.article_code=b.article_code
						 JOIN sectionD d (NOLOCK) ON d.sub_section_code=c.sub_section_code
						 JOIN sectionm e (NOLOCK) ON e.section_code=d.section_code
						 WHERE ISNULL(e.ITEM_TYPE,0) in (0,1)  '
			PRINT @CCMD
			EXEC SP_EXECUTESQL @CCMD
			
			GOTO EndProc
		END
		
		SET @cStep=40		     

		SELECT @cDelStr=(CASE WHEN @nUpdateMode=4 THEN '1=1' ELSE 'a.dept_id='''+@cXnID+'''' END)+@cWhereClause,
			   @cDelJoinStr=REPLACE(@cInsJoinstr,'xnnos.xn_id','''OPS''+xnnos.xn_id')
			  
		SET @cDelJoinStr=REPLACE(@cDelJoinStr,'a.dept_id','a.xn_id')		   
		
			
		SET @CCMD=N'DELETE A FROM '+@cRFTABLEName+'A '+@cDelJoinStr+' WHERE '+@cDelStr
		
		PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD	
		
		SET @CSTEP = 50
		
		SET @cFilter=(CASE WHEN @nUpdateMode=4 THEN '1=1' ELSE 'a.dept_ID='''+@cXnID+'''' END)+@cWhereClause				   		
		SET @CCMD=N'INSERT '+@cRFTABLEName+'
					(DEPT_ID,XN_TYPE,XN_DT,XN_NO,XN_ID,PRODUCT_CODE
					,XN_PARTY_CODE,XN_QTY,XN_NET,XN_DA,TAX_AMOUNT,BIN_ID,BATCHLOTNO) 
					 SELECT    A.DEPT_ID,
						   ''OPS'' AS XN_TYPE,   
						   XN_DT,   
						   ''OPS'' AS XN_NO,   
						   ''OPS''+A.DEPT_ID AS XN_ID, 
						   A.PRODUCT_CODE,
						   '''' AS XN_PARTY_CODE,   
						   A.QUANTITY_OB AS XN_QTY, 
						   0 AS XN_NET,  
						   0 AS XN_DA,0 AS TAX_AMOUNT   
						   ,ISNULL(A.BIN_ID, ''000'')  AS [BIN_ID],
						   SUBSTRING(A.PRODUCT_CODE, NULLIF(CHARINDEX (''@'',A.PRODUCT_CODE)+1,1),LEN(A.PRODUCT_CODE)) AS BATCHLOTNO 
						 FROM OPS01106 A '+@cInsJoinStr+'
						 JOIN sku  (NOLOCK) ON a.product_code=SKU.product_code
						 JOIN article  (NOLOCK) ON SKU.article_code=article.article_code
						 JOIN sectionD  (NOLOCK) ON sectionD.sub_section_code=article.sub_section_code
						 JOIN sectionm  (NOLOCK) ON sectionm.section_code=sectionD.section_code
						 WHERE ISNULL(sectionm.ITEM_TYPE,0) in (0,1)  
						 AND  '+@cFilter
		 PRINT @CCMD
		 EXEC SP_EXECUTESQL @CCMD
		 
	--End of Build Process for Opening Transaction		
END TRY
BEGIN CATCH
	SET @cErrMsg='SP3SBuildOPS: Step :'+@cStep+',Error :'+ERROR_MESSAGE()
END CATCH	

EndProc:

END
