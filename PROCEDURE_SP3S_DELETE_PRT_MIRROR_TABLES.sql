CREATE PROCEDURE SP3S_DELETE_PRT_MIRROR_TABLES
@cMemoId VARCHAR(50)
AS
BEGIN
	DECLARE @cMemoIdCopy VARCHAR(50)
   
		
	SET @cMemoIdCopy=@cMemoId+LEFT(@cMemoId,2)
	
	TRUNCATE TABLE #T 

	INSERT  #t
	SELECT rm_id  
	FROM PRT_RMM01106_MIRROR B (NOLOCK) WHERE rm_id=@cMemoId OR rm_id=@cMemoIdCopy

    IF EXISTS (SELECT TOP 1 'U' FROM #T)
	BEGIN
		DELETE A FROM PRT_RMM01106_MIRROR A  JOIN #T B ON  A.rm_id=B.rm_id
	
		DELETE A FROM PRT_RMD01106_MIRROR A JOIN #T B ON  A.rm_id=B.rm_id
	
		DELETE A FROM PRT_ANGM_MIRROR A JOIN #T B ON  A.prt_memo_id=B.rm_id
		DELETE A FROM PRT_PARCEL_MST_MIRROR A  JOIN #T B ON  A.prt_memo_id=B.rm_id
		DELETE A FROM PRT_PARCEL_DET_MIRROR A  JOIN #T B ON  A.prt_memo_id=B.rm_id
		DELETE A FROM PRT_PMT01106_MIRROR A  JOIN #T B ON  A.prt_memo_id=B.rm_id
	END
END