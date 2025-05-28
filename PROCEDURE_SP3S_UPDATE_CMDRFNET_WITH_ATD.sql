CREATE PROCEDURE SP3S_UPDATE_CMDRFNET_WITH_ATD
AS
BEGIN
	IF NOT EXISTS (SELECT TOP 1 cm_id FROM cmd01106 (NOLOCK) WHERE  rfnet_with_other_charges IS NULL)
		RETURN

	UPDATE cmd01106 SET rfnet_with_other_charges=rfnet

	UPDATE a SET rfnet_with_other_charges=rfnet+((b.atd_charges/b.subtotal)*a.net) FROM cmd01106 a
	JOIN cmm01106 b ON a.cm_id=b.cm_id WHERE isnull(ATD_CHARGES,0)<>0 and b.subtotal<>0


	SELECT A.CM_ID,(a.net_amount-b.rfnet_with_atd) diff INTO #tmpcmm FROM  cmm01106 a (NOLOCK)
	JOIN (SELECT a.cm_id,SUM(rfnet_with_other_charges) rfnet_with_atd FROM cmd01106 a (NOLOCK)
	JOIN  cmm01106 b ON a.cm_id=b.cm_id WHERE atd_charges<>0 GROUP BY a.cm_id) b ON a.cm_id=b.cm_id
	WHERE a.NET_AMOUNT<>b.rfnet_with_atd

	DECLARE @cRowId VARCHAR(50),@cCmId VARCHAR(50),@nDiff NUMERIC(10,2)
	WHILE EXISTS (SELECT TOP 1 cm_id FROM  #tmpcmm)
	BEGIN
		SELECT TOP 1 @cCmId=cm_id,@nDiff=diff  FROM  #tmpcmm
	
		SELECT TOP 1 @cRowId=row_id FROM  cmd01106 (NOLOCK) WHERE cm_id=@cCmid

		UPDATE cmd01106 SET rfnet_with_other_charges=rfnet_with_other_charges+@nDiff WHERE row_id=@cRowId

		DELETE FROM  #tmpcmm WHERE cm_id=@cCmId

	END

END

