CREATE PROCEDURE SP3S_MERGE_LOCPMT  
@cTempTable VARCHAR(300),  
@cMemoIdCol VARCHAR(100)='',  
@cMemoId VARCHAR(40)=''  ,
@CXN_TYPE VARCHAR(10)='',
@bCancelXn BIT=0
AS  
BEGIN  
	DECLARE @cCmd NVARCHAR(MAX),@cCurPmtTablename VARCHAR(200),@cOptPmt VARCHAR(1)  

		 
	SET @cCmd=N'UPDATE a SET quantity_in_stock=b.quantity_in_stock
	FROM pmt01106 a  WITH  (ROWLOCK) 
	JOIN '+@cTempTable+' b (NOLOCK) ON  	a.product_code=b.product_code AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'+  
	(CASE WHEN @cMemoId<>'' THEN  ' WHERE '+@cMemoIdCol+'='''+@cMemoId+'''' ELSE '' END)
	PRINT @cCmd     
	EXEC SP_EXECUTESQL @cCmd  

	IF @bCancelXn=0
	BEGIN
		SET @cCmd=N'INSERT pmt01106	( BIN_ID, DEPT_ID, DEPT_ID_NOT_STUFFED, last_update, product_code, quantity_in_stock, rep_id, 
									  STOCK_RECO_QUANTITY_IN_STOCK )  
					SELECT DISTINCT A.BIN_ID, A.DEPT_ID, '''' AS DEPT_ID_NOT_STUFFED,GETDATE() AS  last_update, 
					A.product_code,SUM(A.quantity_in_stock),'''' AS rep_id,0 AS STOCK_RECO_QUANTITY_IN_STOCK
					FROM '+@cTempTable+' a  WITH  (NOLOCK)  
					LEFT OUTER JOIN pmt01106 b (NOLOCK) ON a.product_Code=b.product_code  
					AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id WHERE b.product_code IS NULL '+
					(CASE WHEN @cMemoId<>'' THEN  ' AND '+@cMemoIdCol+'='''+@cMemoId+'''' ELSE '' END)+'
					GROUP BY A.product_code,A.BIN_ID, A.DEPT_ID'
				
		PRINT @cCmd     
		EXEC SP_EXECUTESQL @cCmd  
	END
	
   
END
