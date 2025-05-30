CREATE PROCEDURE SPCM_BILL_BALANCE
@CCM_ID		VARCHAR(50)
--WITH ENCRYPTION

AS
BEGIN
	DECLARE @NTOTAL NUMERIC(20,2)
	DECLARE @TTABLE TABLE 
	(
		[XN_TYPE]		VARCHAR(100),
		[MEMO_NO]		VARCHAR(50),
		[MEMO_ID]		VARCHAR(100),
		[MEMO_DT]		DATETIME,
		[BILL_AMOUNT]	NUMERIC(20,2),
		[ADJ_AMOUNT]	NUMERIC(20,2),
		[NET]			NUMERIC(20,2)
	)
	INSERT INTO @TTABLE ([XN_TYPE],	[MEMO_NO],[MEMO_ID],[MEMO_DT],[BILL_AMOUNT],[ADJ_AMOUNT],[NET]	)
	SELECT 'CREDIT BILL' AS [XN_TYPE],CM_NO AS [MEMO_NO],MEMO_ID AS [MEMO_ID],CM_DT AS [MEMO_DT],A.AMOUNT AS [BILL_AMOUNT],CAST(0 AS NUMERIC(5,2)) AS [ADJ_AMOUNT],A.AMOUNT AS [NET]
	FROM PAYMODE_XN_DET A 
	JOIN CMM01106 B ON B.CM_ID=A.MEMO_ID 
	WHERE PAYMODE_CODE='0000004' AND XN_TYPE='SLS' AND MEMO_ID=@CCM_ID 
	
	INSERT INTO @TTABLE ([XN_TYPE],	[MEMO_NO],[MEMO_ID],[MEMO_DT],[BILL_AMOUNT],[ADJ_AMOUNT],[NET]	)
	SELECT (CASE WHEN B.ARCT=1 THEN 'OUTSTANDING' 
				WHEN B.ARCT=2 THEN 'ADVANCE'
				ELSE 'OTHER CHARGES' END) AS [XN_TYPE],
				B.ADV_REC_NO AS [MEMO_NO],B.ADV_REC_ID AS [MEMO_ID],B.ADV_REC_DT AS [MEMO_DT],CAST(0 AS NUMERIC(5,2)) AS [BILL_AMOUNT],A.RECEIPT_AMOUNT AS [ADJ_AMOUNT],B.AMOUNT-B.DISCOUNT_AMOUNT AS [NET]
	FROM CMM_CREDIT_RECEIPT A
	JOIN ARC01106 B ON B.ADV_REC_ID=A.ADV_REC_ID
	WHERE B.CANCELLED=0 AND B.ARC_TYPE=1 AND A.CM_ID=@CCM_ID
	UNION ALL
	SELECT 'CREDIT REFUND' AS [XN_TYPE],B.CM_NO AS [MEMO_NO],B.CM_ID AS [MEMO_ID],C.CM_DT AS [MEMO_DT],CAST(0 AS NUMERIC(5,2)) AS [BILL_AMOUNT],A.CREDIT_REFUND_AMOUNT AS [ADJ_AMOUNT],B.NET_AMOUNT AS [NET]
	FROM CMR01106 A
	JOIN CMM01106 B ON B.CM_ID=A.CM_ID
	JOIN CMM01106 C ON C.CM_ID=A.REF_CM_ID
	WHERE B.CANCELLED=0 AND C.CM_ID=@CCM_ID

	DECLARE @NCUMMULATIVE NUMERIC(14,2),@NBILL NUMERIC(14,2),@NADJ NUMERIC(14,2),@CMEMO VARCHAR(50)
	SET @NCUMMULATIVE=0

	BEGIN TRY
		DECLARE ABC CURSOR 
		FOR 
		SELECT BILL_AMOUNT,ADJ_AMOUNT,MEMO_ID FROM @TTABLE
	END TRY
	BEGIN CATCH
		CLOSE ABC
		DEALLOCATE ABC
		DECLARE ABC CURSOR 
		FOR 
		SELECT BILL_AMOUNT,ADJ_AMOUNT,MEMO_ID FROM @TTABLE
	END CATCH

	OPEN ABC

	FETCH NEXT FROM ABC INTO @NBILL ,@NADJ ,@CMEMO
	WHILE @@FETCH_STATUS=0
	BEGIN

	SET @NCUMMULATIVE=@NCUMMULATIVE -(CASE WHEN @NBILL<>0 THEN -1 * @NBILL ELSE @NADJ END)
	UPDATE @TTABLE SET NET=@NCUMMULATIVE WHERE MEMO_ID=@CMEMO
	FETCH NEXT FROM ABC INTO @NBILL ,@NADJ ,@CMEMO
	END
	CLOSE ABC
	DEALLOCATE ABC

	SELECT @NTOTAL=SUM(ADJ_AMOUNT) FROM @TTABLE

	INSERT INTO @TTABLE ([XN_TYPE],	[MEMO_NO],[MEMO_ID],[MEMO_DT],[BILL_AMOUNT],[ADJ_AMOUNT],[NET]	)
	SELECT 'BALANCE' AS [XN_TYPE],'' AS [MEMO_NO],MEMO_ID AS [MEMO_ID],NULL AS [MEMO_DT],SUM(AMOUNT) AS [BILL_AMOUNT],@NTOTAL AS [ADJ_AMOUNT],SUM(AMOUNT) -@NTOTAL AS [NET]
	FROM PAYMODE_XN_DET A 
	JOIN CMM01106 B ON B.CM_ID=A.MEMO_ID 
	WHERE PAYMODE_CODE='0000004' AND XN_TYPE='SLS' AND MEMO_ID=@CCM_ID 
	GROUP BY MEMO_ID

	UPDATE @TTABLE SET BILL_AMOUNT=NULL WHERE BILL_AMOUNT=0
	UPDATE @TTABLE SET ADJ_AMOUNT=NULL WHERE ADJ_AMOUNT=0
	--UPDATE @TTABLE SET NET=NULL WHERE NET=0

	SELECT * FROM @TTABLE

END
