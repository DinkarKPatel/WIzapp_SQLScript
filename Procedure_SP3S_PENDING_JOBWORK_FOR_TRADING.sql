create PROCEDURE SP3S_PENDING_JOBWORK_FOR_TRADING 
(
  @cDtFilter varchar(500)
)
as
begin

     Declare @cCmd nvarchar(max)

	


	SET @cCmd=N'		
		SELECT b.ISSUE_ID,ISSUE_no ,ISSUE_dt ,''PR''+a.agency_code xn_party_code,A.location_code AS DEPT_ID,
		       b.bin_id,b.product_code,sum(B.QUANTITY-isnull(tmp.RECQTY,0)) as adj_QTY
			
		FROM JOBWORK_ISSUE_MST A (NOLOCK)
		JOIN JOBWORK_ISSUE_Det B  (NOLOCK) ON A.ISSUE_ID =B.ISSUE_ID 
		JOIN SKU_NAMES SN (NOLOCK) ON b.PRODUCT_CODE=SN.PRODUCT_CODE
		JOIN #LOCLIST LL ON LL.DEPT_ID=A.location_code
		Left JOIn 
		(
			SELECT B.REF_ROW_ID ,SUM(b.QUANTITY) AS RECQTY
			FROM JOBWORK_RECEIPT_MST A (NOLOCK)
			JOIN JOBWORK_RECEIPT_DET B (NOLOCK) ON A.RECEIPT_ID=B.RECEIPT_ID
			JOIN #LOCLIST LL ON LL.DEPT_ID=A.location_code
			WHERE A.CANCELLED=0 AND A.RECEIPT_DT'+@CDTFILTER+' 
			GROUP BY B.REF_ROW_ID
		) TMP ON B.ROW_ID=TMP.REF_ROW_ID
		WHERE  A.ISSUE_DT'+@cDtFilter+' AND A.CANCELLED=0 AND A.WIP=0 AND A.ISSUE_TYPE=1 
		AND isnull(sn.STOCK_NA,0)=0
		AND ISNULL(Sn.sku_ITEM_TYPE,0) IN(0,1) AND ISNULL(non_receivable,0)=0 
		AND ISNULL(a.ISSUE_MODE,0)<>1 
		GROUP BY B.ISSUE_ID,ISSUE_NO ,ISSUE_DT ,A.AGENCY_CODE ,A.location_code, 
		       B.BIN_ID,B.PRODUCT_CODE
	'
	print @cCmd
	insert into #TMP_JOBWORK_FOR_TRADING(MEMO_ID,XN_NO,XN_DT,xn_party_code,DEPT_ID,bin_id,product_code,QUANTITY)
	exec sp_executesql @cCmd


	  

end