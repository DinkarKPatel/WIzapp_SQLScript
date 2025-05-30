CREATE PROCEDURE UPDATEPMT_GV
		@CXNTYPE VARCHAR(10),
		@CXNID VARCHAR(40),
		@NREVERTFLAG BIT = 0,
		@NUPDATEMODE INT = 0,
		@CCMD NVARCHAR(MAX) OUTPUT

		--*** PARAMETERS :
		--*** @CXNTYPE - TRANSACTION TYPE (MODULE SPECIFIC)
		--*** @CXNID - TRANSACTION ID ( MEMO ID OF MASTER TABLE )
		--*** @NREVERTFLAG - A FLAG TO INDICATE WHETHER THIS PROCEDURE IS CALLED TO REVERT STOCK
		--*** @NRETVAL - OUTPUT PARAMETER RETURNED BY THIS PROCEDURE (BIT 1-SUCCESS, 0-UNSUCCESS)
--WITH ENCRYPTION
AS
BEGIN
	DECLARE @NOUTFLAG INT, @NRETVAL BIT,@CXNTABLE VARCHAR(50),@CEXPR NVARCHAR(500),@CXNIDPARA VARCHAR(50),
			@BCANCELLED BIT,@CUSERCODE VARCHAR(10)
	
	SET @NRETVAL = 0
	SET @CCMD = ''
	
	IF @CXNTYPE IN ('GVGEN','GVCHI')
		SET @NOUTFLAG = -1
	ELSE
		SET @NOUTFLAG = 1	
		
	IF @NREVERTFLAG = 1
		SET @NOUTFLAG = @NOUTFLAG*-1

	IF @CXNTYPE='GVGEN'
	BEGIN	
		UPDATE A SET QUANTITY_IN_STOCK = QUANTITY_IN_STOCK - ( @NOUTFLAG * B.QUANTITY )
		FROM  PMT_GV_MST A
		JOIN 
		(	SELECT B.GV_SRNO,SUM(B.QUANTITY) AS QUANTITY 
			FROM GV_GEN_DET B
			JOIN GV_GEN_MST C ON C.MEMO_ID=B.MEMO_ID
			WHERE B.MEMO_ID = @CXNID
			GROUP BY B.GV_SRNO
		) B ON A.GV_SRNO = B.GV_SRNO

		SET @NRETVAL = 1		--*** SUCCESS
			
		--*** CHECKING FOR NEGATIVE STOCK
		--*** IF USER OPTED NOT TO ALLOW NEGATIVE STOCK AND STOCK IS GOING OUT
		IF (@NREVERTFLAG = 0 OR @NUPDATEMODE=3) 
		BEGIN
			PRINT 'CHECK NEGATIVE STOCK IN GVGEN-1'
			IF EXISTS (SELECT A.GV_SRNO FROM PMT_GV_MST A JOIN
						(
							SELECT B.GV_SRNO
							FROM GV_GEN_DET B
							JOIN GV_GEN_MST C ON C.MEMO_ID=B.MEMO_ID
							WHERE B.MEMO_ID = @CXNID
							GROUP BY B.GV_SRNO
							UNION 
							SELECT GV_SRNO 
							FROM #TMPPMTBEFOREEDIT
						) B ON B.GV_SRNO=A.GV_SRNO
						WHERE A.QUANTITY_IN_STOCK < 0)
			BEGIN
				PRINT 'CHECK NEGATIVE STOCK IN GVGEN-2'
				SET @NRETVAL = 0		--*** UNSUCCESS
				SET @CCMD = N'SELECT DISTINCT A.GV_SRNO, A.QUANTITY_IN_STOCK,''FOLLOWING GV NOS. ARE GOING NEGATIVE STOCK'' AS ERRMSG 
						 FROM PMT_GV_MST A 
						 JOIN 
						(
							SELECT B.GV_SRNO
							FROM GV_GEN_DET B
							JOIN GV_GEN_MST C ON C.MEMO_ID=B.MEMO_ID
							WHERE B.MEMO_ID = '''+@CXNID+'''
							GROUP BY B.GV_SRNO
							UNION 
							SELECT GV_SRNO 
							FROM #TMPPMTBEFOREEDIT
						) B ON B.GV_SRNO=A.GV_SRNO
						WHERE A.QUANTITY_IN_STOCK < 0 '
				PRINT @CCMD		
			END
		END	
	END
	
	ELSE
	IF @CXNTYPE IN ('GVCHI','GVCHO')
	BEGIN	
		UPDATE A SET QUANTITY_IN_STOCK = QUANTITY_IN_STOCK - ( @NOUTFLAG * B.QUANTITY )
		FROM  PMT_GV_MST A
		JOIN 
		(	SELECT B.GV_SRNO,SUM(B.QUANTITY) AS QUANTITY 
			FROM GV_STKXFER_DET B
			JOIN GV_STKXFER_MST C ON C.MEMO_ID=B.MEMO_ID
			WHERE B.MEMO_ID = @CXNID
			GROUP BY B.GV_SRNO
		) B ON A.GV_SRNO = B.GV_SRNO

		SET @NRETVAL = 1		--*** SUCCESS
		
		SELECT @BCANCELLED=CANCELLED FROM GV_STKXFER_MST WHERE MEMO_ID=@CXNID
		
		--*** CHECKING FOR NEGATIVE STOCK
		--*** IF USER OPTED NOT TO ALLOW NEGATIVE STOCK AND STOCK IS GOING OUT
		IF (@NREVERTFLAG = 0 OR @BCANCELLED=1) 
		BEGIN
			IF EXISTS (SELECT A.GV_SRNO FROM PMT_GV_MST A JOIN
						(
							SELECT B.GV_SRNO,SUM(B.QUANTITY) AS QUANTITY 
							FROM GV_STKXFER_DET B
							JOIN GV_STKXFER_MST C ON C.MEMO_ID=B.MEMO_ID
							WHERE B.MEMO_ID = @CXNID
							GROUP BY B.GV_SRNO
						) B ON B.GV_SRNO=A.GV_SRNO
						WHERE A.QUANTITY_IN_STOCK < 0)
			BEGIN
				SET @NRETVAL = 0		--*** UNSUCCESS
				SET @CCMD = N'SELECT DISTINCT A.GV_SRNO, A.QUANTITY_IN_STOCK,''FOLLOWING GV NOS. ARE GOING NEGATIVE STOCK'' AS ERRMSG 
						 FROM PMT_GV_MST A 
						 JOIN 
						(
							SELECT B.GV_SRNO,SUM(B.QUANTITY) AS QUANTITY 
							FROM GV_STKXFER_DET B
							JOIN GV_STKXFER_MST C ON C.MEMO_ID=B.MEMO_ID
							WHERE B.MEMO_ID = '''+@CXNID+'''
							GROUP BY B.GV_SRNO
						) B ON B.GV_SRNO=A.GV_SRNO
						WHERE A.QUANTITY_IN_STOCK < 0 '
			END
		END	
	END		

	ELSE
	IF @CXNTYPE='GVSLS'
	BEGIN	
		UPDATE A SET QUANTITY_IN_STOCK = QUANTITY_IN_STOCK - ( @NOUTFLAG * B.QUANTITY )
		FROM  PMT_GV_MST A
		JOIN 
		(	SELECT B.GV_SRNO,SUM(B.QUANTITY) AS QUANTITY 
			FROM ARC_GVSALE_DETAILS B
			WHERE B.ADV_REC_ID = @CXNID
			GROUP BY B.GV_SRNO
		) B ON A.GV_SRNO = B.GV_SRNO

		SET @NRETVAL = 1		--*** SUCCESS
		
		--*** CHECKING FOR NEGATIVE STOCK
		--*** IF USER OPTED NOT TO ALLOW NEGATIVE STOCK AND STOCK IS GOING OUT
		IF (@NREVERTFLAG = 0 OR @NUPDATEMODE=3) 
		BEGIN
			IF EXISTS (SELECT A.GV_SRNO FROM PMT_GV_MST A JOIN
						(
							SELECT B.GV_SRNO,SUM(B.QUANTITY) AS QUANTITY 
							FROM ARC_GVSALE_DETAILS B
							WHERE B.ADV_REC_ID = @CXNID
							GROUP BY B.GV_SRNO
						) B ON B.GV_SRNO=A.GV_SRNO
						WHERE A.QUANTITY_IN_STOCK < 0)
			BEGIN
				SET @NRETVAL = 0		--*** UNSUCCESS
				SET @CCMD = N'SELECT DISTINCT A.GV_SRNO, A.QUANTITY_IN_STOCK,''FOLLOWING GV NOS. ARE GOING NEGATIVE STOCK'' AS ERRMSG 
						 FROM PMT_GV_MST A 
						 JOIN 
						(
							SELECT B.GV_SRNO,SUM(B.QUANTITY) AS QUANTITY 
							FROM ARC_GVSALE_DETAILS B
							WHERE B.ADV_REC_ID = '''+@CXNID+'''
							GROUP BY B.GV_SRNO
						) B ON B.GV_SRNO=A.GV_SRNO
						WHERE A.QUANTITY_IN_STOCK < 0 '
			END
		END	
	END			

	ELSE
	IF @CXNTYPE='GVREDEEM'
	BEGIN	

		UPDATE A SET QUANTITY_IN_STOCK = QUANTITY_IN_STOCK - ( @NOUTFLAG * B.QUANTITY )
		FROM  PMT_GV_MST A
		JOIN 
		(	SELECT B.GV_SRNO,COUNT(*) AS QUANTITY 
			FROM PAYMODE_XN_DET B
			JOIN sku_gv_mst C ON c.gv_srno=b.gv_srno
			WHERE B.MEMO_ID = @CXNID AND XN_TYPE='SLS' 
			GROUP BY B.GV_SRNO
		) B ON A.GV_SRNO = B.GV_SRNO
		
		UPDATE A SET QUANTITY_IN_STOCK = QUANTITY_IN_STOCK - ( @NOUTFLAG * B.QUANTITY )
		FROM  PMT_GV_MST A
		JOIN 
		(	SELECT B.GV_SRNO,COUNT(*) AS QUANTITY 
			FROM GV_MST_REDEMPTION B
			JOIN sku_gv_mst C ON c.gv_srno=b.gv_srno
			WHERE B.REDEMPTION_CM_ID = @CXNID 
			GROUP BY B.GV_SRNO
		) B ON A.GV_SRNO = B.GV_SRNO
		
		SET @NRETVAL = 1		--*** SUCCESS
		
		--*** CHECKING FOR NEGATIVE STOCK
		--*** IF USER OPTED NOT TO ALLOW NEGATIVE STOCK AND STOCK IS GOING OUT
		IF (@NREVERTFLAG = 0 OR @NUPDATEMODE=3) 
		BEGIN
			IF EXISTS (SELECT A.GV_SRNO FROM PMT_GV_MST A JOIN
						(
							SELECT B.GV_SRNO,COUNT(*) AS QUANTITY 
							FROM PAYMODE_XN_DET B
							WHERE B.MEMO_ID = @CXNID AND XN_TYPE='SLS'
							GROUP BY B.GV_SRNO
						) B ON B.GV_SRNO=A.GV_SRNO
						WHERE A.QUANTITY_IN_STOCK < 0)
			BEGIN
				SET @NRETVAL = 0		--*** UNSUCCESS
				SET @CCMD = N'SELECT DISTINCT A.GV_SRNO, A.QUANTITY_IN_STOCK,''FOLLOWING GV NOS. ARE GOING NEGATIVE STOCK'' AS ERRMSG 
						 FROM PMT_GV_MST A 
						 JOIN 
						(
							SELECT B.GV_SRNO,SUM(B.QUANTITY) AS QUANTITY 
							FROM PAYMODE_XN_DET B
							WHERE B.MEMO_ID = '''+@CXNID+'''  AND XN_TYPE=''SLS''
							GROUP BY B.GV_SRNO
						) B ON B.GV_SRNO=A.GV_SRNO
						WHERE A.QUANTITY_IN_STOCK < 0 '
				RETURN		
			END

			IF EXISTS (SELECT A.GV_SRNO FROM PMT_GV_MST A JOIN
						(
							SELECT B.GV_SRNO,COUNT(*) AS QUANTITY 
							FROM GV_MST_REDEMPTION B
							WHERE B.REDEMPTION_CM_ID = @CXNID
							GROUP BY B.GV_SRNO
						) B ON B.GV_SRNO=A.GV_SRNO
						WHERE A.QUANTITY_IN_STOCK < 0)
			BEGIN
				SET @NRETVAL = 0		--*** UNSUCCESS
				SET @CCMD = N'SELECT DISTINCT A.GV_SRNO, A.QUANTITY_IN_STOCK,''FOLLOWING GV NOS. ARE GOING NEGATIVE STOCK'' AS ERRMSG 
						 FROM PMT_GV_MST A 
						 JOIN 
						(
							SELECT B.GV_SRNO,SUM(B.QUANTITY) AS QUANTITY 
							FROM GV_MST_REDEMPTION B
							WHERE B.REDEMPTION_CM_ID = '''+@CXNID+'''
							GROUP BY B.GV_SRNO
						) B ON B.GV_SRNO=A.GV_SRNO
						WHERE A.QUANTITY_IN_STOCK < 0 '
			END			
		END	
	END			
	
	ELSE
	IF @CXNTYPE='GVCNC'
	BEGIN	
		UPDATE A SET QUANTITY_IN_STOCK = QUANTITY_IN_STOCK - ( @NOUTFLAG * B.QUANTITY )
		FROM  PMT_GV_MST A
		JOIN 
		(	SELECT B.GV_SRNO,SUM(B.QUANTITY) AS QUANTITY 
			FROM GV_CNC_DET B
			WHERE B.MEMO_ID = @CXNID
			GROUP BY B.GV_SRNO
		) B ON A.GV_SRNO = B.GV_SRNO

		SET @NRETVAL = 1		--*** SUCCESS
		
		--*** CHECKING FOR NEGATIVE STOCK
		--*** IF USER OPTED NOT TO ALLOW NEGATIVE STOCK AND STOCK IS GOING OUT
		IF (@NREVERTFLAG = 0 OR @NUPDATEMODE=3) 
		BEGIN
			IF EXISTS (SELECT A.GV_SRNO FROM PMT_GV_MST A JOIN
						(
							SELECT B.GV_SRNO,SUM(B.QUANTITY) AS QUANTITY 
							FROM GV_CNC_DET B
							WHERE B.MEMO_ID = @CXNID
							GROUP BY B.GV_SRNO
						) B ON B.GV_SRNO=A.GV_SRNO
						WHERE A.QUANTITY_IN_STOCK < 0)
			BEGIN
				SET @NRETVAL = 0		--*** UNSUCCESS
				SET @CCMD = N'SELECT DISTINCT A.GV_SRNO, A.QUANTITY_IN_STOCK,''FOLLOWING GV NOS. ARE GOING NEGATIVE STOCK'' AS ERRMSG 
						 FROM PMT_GV_MST A 
						 JOIN 
						(
							SELECT B.GV_SRNO,SUM(B.QUANTITY) AS QUANTITY 
							FROM GV_CNC_DET B
							WHERE B.MEMO_ID = '''+@CXNID+'''
							GROUP BY B.GV_SRNO
						) B ON B.GV_SRNO=A.GV_SRNO
						WHERE A.QUANTITY_IN_STOCK < 0 '
			END
		END	
	END			
		
END_PROC:

END
--***************************** END OF PROCEDURE UPDATEPMT_GV
