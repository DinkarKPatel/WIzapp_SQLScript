CREATE PROCEDURE SPACT_CHEQUE_BOOK_INVENTORY
(
	@nQueryID		NUMERIC(2),
	@cMemoID		VARCHAR(500),
	@nMode			NUMERIC(2)

)
AS
BEGIN
	DECLARE @cCMD NVARCHAR(MAX)
	--,(CASE WHEN ISNULL(b.chq_sr_no,'')='' THEN 'Cheques(manual entry)' ELSE b.chq_sr_no END) AS [chq_sr_no],
	--b.start_leaf_no,b.no_of_leaves,a.chq_leaf_no,a.row_id
	--END
	IF @nQueryID=1
	BEGIN

	SET @cCMD=N'SELECT ac_code, ac_name 
				FROM lmv01106 (NOLOCK) 
				WHERE CHARINDEX( head_code, dbo.FN_Act_TravTree(''0000000013''))>0
				ORDER BY ac_name'
	END
	ELSE IF @nQueryID=2
	BEGIN 
	SET @cCMD=N'SELECT DISTINCT a.chq_book_id ,receive_dt
				FROM chqbook_M a (NOLOCK)
				JOIN chqbook_D b (NOLOCK) ON b.chq_book_id=a.chq_book_id
				WHERE  a.chq_book_id<>'''''--  " + Constants.vbCrLf + Interaction.IIf(cDonotShowUsedChq == "1", " AND b.chq_leaf_no NOT IN (select b.chq_leaf_no FROM chqbook_m a (NOLOCK) JOIN chqbook_D b (NOLOCK) ON b.chq_book_id=a.chq_book_id WHERE (b.cancelled=1))", "") + Constants.vbCrLf + "ORDER BY receive_dt ";
	END
	ELSE IF @nQueryID=3
	BEGIN 
	SET @cCMD=N'SELECT DISTINCT a.*,b.bank_ac_code,c.ac_name  
				FROM chqbook_M a (NOLOCK)
				JOIN chqbook_D b (NOLOCK) ON b.chq_book_id = a.chq_book_id
				JOIN lmv01106 c (NOLOCK) ON c.ac_code = b.bank_ac_code
				WHERE a.chq_book_id='''+@cMemoID+''''
	END
	ELSE IF @nQueryID=4
	BEGIN 
	SET @cCMD=N'SELECT chq_book_id,bank_ac_code,chq_leaf_no,
				CONVERT(varchar(10),v.voucher_dt,105) AS issue_dt, 
				(CASE WHEN b.RECON_DT ='''' THEN '''' ELSE CONVERT(varchar(10),b.RECON_DT,105) END) AS  clg_dt, 
				CAST((ISNULL(b.credit_amount,0)+ISNULL(b.debit_amount,0)) AS NUMERIC(14,2)) AS chq_amount, a.remarks, d. vd_id, a.cancelled, row_id, a.last_update, 
				a.company_code,CAST(0 AS BIT) as chkcancel,ISNULL(b.NARRATION,'''') AS NARRATION, ISNULL(c.AC_NAME,'''') AS AC_NAME
				FROM chqbook_D a (NOLOCK)
				LEFT OUTER JOIN vd_chqbook d ON d.chqbook_row_id=a.row_id
				LEFT OUTER JOIN VD01106 b  (NOLOCK) ON b.VD_ID=d.vd_id
				LEFT OUTER JOIN Vm01106 v  (NOLOCK) ON b.vm_id=v.vm_id 
				LEFT OUTER JOIN LM01106 c (NOLOCK) ON c.AC_CODE=b.VS_AC_CODE
				WHERE ' + (case when ISNULL(@cMemoID,'')='' THEN '1=2' ELSE ISNULL(@cMemoID,'') END) +' 
				ORDER BY chq_leaf_no'
	END
	ELSE IF @nQueryID=5
	BEGIN 
	SET @cCMD=N'SELECT chq_book_id,bank_ac_code,chq_leaf_no,
				CAST('''' AS DATETIME) AS issue_dt, CAST('''' AS DATETIME) AS  clg_dt, 
				CAST(0 AS NUMERIC(14,2)) AS chq_amount, a.remarks, '''' AS vd_id, cancelled, row_id, a.last_update, 
				a.company_code,CAST(0 AS BIT) as chkcancel,ISNULL(b.NARRATION,'''') AS NARRATION, ISNULL(c.AC_NAME,'''') AS AC_NAME
				FROM chqbook_D a (NOLOCK)
				LEFT OUTER JOIN vd_chqbook d ON d.chqbook_row_id=a.row_id
				LEFT OUTER JOIN VD01106 b (NOLOCK) ON b.VD_ID=d.vd_id
				LEFT OUTER JOIN LM01106 c (NOLOCK) ON c.AC_CODE=b.AC_CODE
				WHERE ' + (case when ISNULL(@cMemoID,'')='' THEN '1=2' ELSE ISNULL(@cMemoID,'') END) +' 
				ORDER BY chq_leaf_no'
	END
	ELSE IF @nQueryID=6
	BEGIN 
		SET @cCMD=N'SELECT chq_book_id,bank_ac_code,chq_leaf_no, 
				CONVERT(varchar(10),GETDATE(),105) AS issue_dt, 
				CONVERT(varchar(10),GETDATE(),105) AS clg_dt, 
				CAST(0 AS NUMERIC(14,2)) AS chq_amount, remarks, '''' AS vd_id, 
				cancelled, row_id, last_update, company_code,CAST(0 AS BIT)  as chkcancel 
				FROM chqbook_D (NOLOCK)
				WHERE ' + (case when ISNULL(@cMemoID,'')='' THEN '1=2' ELSE ISNULL(@cMemoID,'') END) +' 
				ORDER BY chq_leaf_no'
	END
	ELSE IF @nQueryID=7
	BEGIN
		SET @cCMD=N''
		IF @nMode=1
		BEGIN 
			SET @cCMD=N' AND (ISNULL(b.Closed,0)=0 AND b1.chqbook_row_id IS NULL) '
			SET @cCMD=N' AND (ISNULL(b.Closed,0)=0 AND a.chq_leaf_no NOT IN (select b.chq_leaf_no FROM chqbook_m a (NOLOCK) JOIN chqbook_D b (NOLOCK) ON b.chq_book_id=a.chq_book_id WHERE (b.cancelled=1) ) )'
			SET @cCMD=N' AND (ISNULL(b.Closed,0)=0 AND X1.TOTAL_LEAVES <> ISNULL(X2.TOTAL_USED_LEAVES,0) )'
		END
		ELSE IF @nMode=2
		BEGIN 
			SET @cCMD=N' AND (ISNULL(b.Closed,0)=0 AND b1.chqbook_row_id IS NOT NULL) '
			SET @cCMD=N' AND (ISNULL(b.Closed,0)=0 AND a.chq_leaf_no NOT IN (select b.chq_leaf_no FROM chqbook_m a (NOLOCK) JOIN chqbook_D b (NOLOCK) ON b.chq_book_id=a.chq_book_id WHERE (b.cancelled=1) ) )'
			SET @cCMD=N' AND (ISNULL(b.Closed,0)=0 AND X1.TOTAL_LEAVES = ISNULL(X2.TOTAL_USED_LEAVES,0) )'
		END
		ELSE IF @nMode=3
		BEGIN 
			SET @cCMD=N' AND ISNULL(b.Closed,0)=1 '
		END

		SET @cCMD=N';WITH CHQTOTAL
	AS
	(
		SELECT chq_book_id,COUNT(*) AS TOTAL_LEAVES FROM ChqBook_D (NOLOCK) GROUP BY chq_book_id
	)
	,CHQUSED
	AS
	(
		SELECT X.chq_book_id,SUM(X.TOTAL_USED_LEAVES) AS TOTAL_USED_LEAVES
		FROM 
		(
			SELECT chq_book_id,COUNT(*) AS TOTAL_USED_LEAVES 
			FROM ChqBook_D a (NOLOCK)
			JOIN 
			(
			SELECT DISTINCT chqbook_row_id FROM vd_chqbook (NOLOCK)
			)b1 ON b1.chqbook_row_id=a.row_id
			WHERE a.cancelled=0
			GROUP BY chq_book_id
			UNION ALL
			SELECT chq_book_id,COUNT(*) AS TOTAL_USED_LEAVES 
			FROM ChqBook_D a (NOLOCK)
			WHERE a.cancelled=1
			GROUP BY chq_book_id
		)X 
		GROUP BY X.chq_book_id
	)
	SELECT  c.AC_NAME,a.chq_book_id,b.chq_sr_no,b.receive_dt,(CASE WHEN (ISNULL(b.Closed,0)=0 AND X1.TOTAL_LEAVES = X2.TOTAL_USED_LEAVES ) THEN CAST(1 AS BIT) ELSE ISNULL(b.Closed,0) END) AS CLOSED
	FROM ChqBook_D a (NOLOCK)
	JOIN ChqBook_M b (NOLOCK) ON b.chq_book_id=a.chq_book_id
	JOIN LM01106 c (NOLOCK) ON c.AC_CODE=a.bank_ac_code
	JOIN CHQTOTAL X1 ON X1.chq_book_id=b.chq_book_id
	LEFT OUTER JOIN vd_chqbook b1(NOLOCK) ON b1.chqbook_row_id=a.row_id
	LEFT OUTER JOIN CHQUSED X2 ON X2.chq_book_id=b.chq_book_id
		WHERE 1=1 '+@cCMD+' 
		GROUP BY c.AC_NAME,a.chq_book_id,b.chq_sr_no,b.receive_dt,ISNULL(b.Closed,0),X1.TOTAL_LEAVES , X2.TOTAL_USED_LEAVES
		ORDER BY ac_name,a.chq_book_id,b.chq_sr_no,b.receive_dt,ISNULL(b.Closed,0)'
	END
	PRINT @cCMD

	EXEC SP_EXECUTESQL @cCMD
END
