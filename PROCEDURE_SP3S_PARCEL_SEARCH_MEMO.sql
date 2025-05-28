CREATE PROCEDURE SP3S_PARCEL_SEARCH_MEMO
(
	@CXNTYPE	VARCHAR(MAX),
	@cac_code	VARCHAR(MAX),
	@CWHERE1	VARCHAR(MAX)
)
AS
BEGIN

IF OBJECT_ID('tempdb..#tmpDocs','U') IS NOT NULL
		DROP TABLE #tmpDocs
		
	DECLARE @cFilter NVARCHAR(MAX),@cCmd NVARCHAR(MAX)
  
  SELECT a.inv_no as memo_no,a.inv_id as memo_id,a.inv_dt as memo_dt,CONVERT(NUMERIC(14,2),0) AS QUANTITY ,cast('' as varchar(10)) memo_type
  INTO #tmpDocs 
  FROM INM01106 a
  WHERE 1=2
  
  SET @cFilter=(CASE WHEN @cac_code='' THEN '1=1' ELSE 'a.ac_code='''+@cac_code+'''' END)

  
  IF @CXNTYPE='WSL'
  BEGIN
		SET @cCmd=N'SELECT a.inv_no as memo_no,a.inv_id as memo_no,a.inv_dt as memo_dt, X.QUANTITY,CASE WHEN ISNULL(a.inv_mode,1)=2 THEN ''Group'' ELSE ''Party'' END AS MEMO_TYPE
		FROM INM01106 a
		JOIN 
		(
			SELECT INV_ID ,SUM(QUANTITY) AS QUANTITY FROM IND01106(NOLOCK) GROUP BY INV_ID
		)X ON X.INV_ID=a.INV_ID
		LEFT OUTER JOIN parcel_det b (NOLOCK) ON b.REF_MEMO_ID=a.INV_ID
		LEFT OUTER JOIN parcel_mst c (NOLOCK) ON c.parcel_memo_id=b.parcel_memo_id 
								AND c.xn_type=''WSL'' AND c.cancelled=0
		WHERE '+@cFilter+' AND a.cancelled=0 AND  c.parcel_memo_id IS NULL AND a.inv_no LIKE ''%'+ @CWHERE1 +  '%'''
  END 	  
  ELSE
  IF @CXNTYPE='PRT'
  BEGIN
		SET @cCmd=N'SELECT a.rm_no as memo_no,a.rm_id as memo_no,a.rm_dt as memo_dt , X.QUANTITY,CASE WHEN ISNULL(a.mode,1)=2 THEN ''Group'' ELSE ''Party'' END AS MEMO_TYPE
		FROM RMM01106 a
		JOIN 
		(
			SELECT RM_ID ,SUM(QUANTITY) AS QUANTITY FROM RMD01106(NOLOCK) GROUP BY RM_ID
		)X ON X.RM_ID=a.RM_ID
		LEFT OUTER JOIN parcel_det b (NOLOCK) ON b.REF_MEMO_ID=a.rm_ID
		LEFT OUTER JOIN parcel_mst c (NOLOCK) ON c.parcel_memo_id=b.parcel_memo_id 
								AND c.xn_type=''PRT'' AND c.cancelled=0
		WHERE '+@cFilter+' AND a.cancelled=0 AND c.parcel_memo_id IS NULL AND a.rm_no LIKE ''%'+ @CWHERE1 +  '%'''				
  END 	
  ELSE
  IF @CXNTYPE='MIS'
  BEGIN
		SET @cCmd=N'SELECT a1.issue_no as memo_no,a1.issue_id as memo_no,a1.issue_dt as memo_dt , X.QUANTITY,CAST('''' AS VARCHAR(10)) AS MEMO_TYPE
		FROM BOM_ISSUE_MST a1
		JOIN PRD_AGENCY_MST a ON a1.agency_code=a.agency_code
		JOIN 
		(
			SELECT issue_id ,SUM(QUANTITY) AS QUANTITY FROM BOM_ISSUE_DET (NOLOCK) GROUP BY issue_id
		)X ON X.issue_id=a1.issue_id
		LEFT OUTER JOIN parcel_det b (NOLOCK) ON b.REF_MEMO_ID=a1.issue_id
		LEFT OUTER JOIN parcel_mst c (NOLOCK) ON c.parcel_memo_id=b.parcel_memo_id 
								AND c.xn_type=''MIS'' AND c.cancelled=0
		WHERE '+@cFilter+' AND a1.cancelled=0 AND c.parcel_memo_id IS NULL AND a1.issue_no LIKE ''%'+ @CWHERE1 +  '%'''	
		
  END         
  ELSE
  IF @CXNTYPE='JWI'
  BEGIN
		SET @cCmd=N'SELECT a1.issue_no as memo_no,a1.issue_id as memo_no,a1.issue_dt as memo_dt , X.QUANTITY,CAST('''' AS VARCHAR(10)) AS MEMO_TYPE
		FROM JOBWORK_ISSUE_MST a1
		JOIN PRD_AGENCY_MST a ON a1.agency_code=a.agency_code
		JOIN 
		(
			SELECT issue_id ,SUM(QUANTITY) AS QUANTITY FROM JOBWORK_ISSUE_DET (NOLOCK) GROUP BY issue_id
		)X ON X.issue_id=a1.issue_id
		LEFT OUTER JOIN parcel_det b (NOLOCK) ON b.REF_MEMO_ID=a1.issue_id
		LEFT OUTER JOIN parcel_mst c (NOLOCK) ON c.parcel_memo_id=b.parcel_memo_id 
								AND c.xn_type=''JWI'' AND c.cancelled=0
		WHERE '+@cFilter+' AND a1.cancelled=0 AND c.parcel_memo_id IS NULL AND a1.issue_no LIKE ''%'+ @CWHERE1 +  '%'''	
		
  END  
  ELSE
  IF @CXNTYPE='SLS'
  BEGIN
		SET @cCmd=N'
		;WITH CMD
		AS
		(
			SELECT A.CM_id ,SUM(QUANTITY) AS QUANTITY 
			FROM CMD01106 A (NOLOCK) 
			JOIN CMM01106 B (NOLOCK) ON B.CM_ID=A.CM_ID
			GROUP BY A.CM_ID		
		)
		
		SELECT a1.cm_no as memo_no,a1.cm_id as memo_no,a1.cm_dt as memo_dt , X.QUANTITY,CAST('''' AS VARCHAR(10)) AS MEMO_TYPE
		FROM CMM01106 a1
		JOIN CMD X ON X.cm_id=a1.cm_id
		LEFT OUTER JOIN parcel_det b (NOLOCK) ON b.REF_MEMO_ID=a1.cm_id
		LEFT OUTER JOIN parcel_mst c (NOLOCK) ON c.parcel_memo_id=b.parcel_memo_id 
								AND c.xn_type=''SLS'' AND c.cancelled=0
		WHERE '+@cFilter+' AND a1.cancelled=0 AND c.parcel_memo_id IS NULL AND a1.CM_no LIKE ''%'+ @CWHERE1 +  '%'''	
		
  END  
	IF ISNULL(@cCmd,'')<>''
	BEGIN
		PRINT @cCmd
		INSERT #tmpDocs (memo_no,memo_id,memo_dt,quantity,memo_type)	   	     
		EXEC SP_EXECUTESQL @cCmd
	END
  
  SELECT * FROM #tmpDocs   
END  
