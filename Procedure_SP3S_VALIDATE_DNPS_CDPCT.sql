CREATE PROCEDURE SP3S_VALIDATE_DNPS_CDPCT
@cMemoId VARCHAR(40),
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN	
	DECLARE @nPurCdPct1 NUMERIC(6,2),@nDnTermsCdPct1 NUMERIC(6,2),@nPurCdPct2  NUMERIC(6,2),@nDnTermsCdPct2  NUMERIC(6,2),
	@nMode NUMERIC(1,0),@cPurCdPc1 VARCHAR(50),@cDnTermsPc1 VARCHAR(50),@cPurCdPc2 VARCHAR(50),@cDnTermsPc2 VARCHAR(50),
	@cApplyCdonTotal1 VARCHAR(5),@cApplyCdonTotal2 VARCHAR(5)

	SELECT TOP 1 @nMode=ps_mode FROM  dnps_mst (NOLOCK) WHERE ps_id=@cMemoId

	IF @nMode=2
		RETURN

	SELECT top 1 @nPurCdPct1=(CASE WHEN ISNULL(a.DNPS_Terms,'')<>'' THEN substring(DNPS_Terms,dbo.CHARINDEX_NTH('-',DNPS_Terms,1,5)+1,
			dbo.CHARINDEX_NTH('-',DNPS_Terms,1,6)-dbo.CHARINDEX_NTH('-',DNPS_Terms,1,5)-1) 
	ELSE a.DNPS_CD_PERCENTAGE END),@cApplyCdonTotal1=ISNULL(SUBSTRING(DNPS_Terms,DBO.CHARINDEX_NTH('-',DNPS_Terms,1,10)+1,1),''),
	@cPurCdPc1=a.product_code 
	FROM DNPS_DET a (NOLOCK)
	WHERE a.ps_id=@cMemoId AND (ISNULL(a.DNPS_Terms,'')<>'' OR ISNULL(a.DNPS_CD_PERCENTAGE,0)<>0)

	
	IF ISNULL(@cPurCdPc1,'')<>''
	BEGIN
		SELECT top 1 @nPurCdPct2=(CASE WHEN ISNULL(a.DNPS_Terms,'')<>'' THEN substring(DNPS_Terms,dbo.CHARINDEX_NTH('-',DNPS_Terms,1,5)+1,
			dbo.CHARINDEX_NTH('-',DNPS_Terms,1,6)-dbo.CHARINDEX_NTH('-',DNPS_Terms,1,5)-1)
		ELSE a.DNPS_CD_PERCENTAGE END),@cApplyCdonTotal2=ISNULL(SUBSTRING(DNPS_Terms,DBO.CHARINDEX_NTH('-',DNPS_Terms,1,10)+1,1),''),@cPurCdPc2=a.product_code 
		FROM DNPS_DET a (NOLOCK)
		WHERE a.ps_id=@cMemoId AND (CASE WHEN ISNULL(a.DNPS_Terms,'')<>'' THEN substring(DNPS_Terms,dbo.CHARINDEX_NTH('-',DNPS_Terms,1,5)+1,
			dbo.CHARINDEX_NTH('-',DNPS_Terms,1,6)-dbo.CHARINDEX_NTH('-',DNPS_Terms,1,5)-1)
		ELSE a.DNPS_CD_PERCENTAGE END)<>@nPurCdPct1

		IF ISNULL(@cPurCdPc2,'')<>''
		BEGIN
			SET @cErrormsg='Mixing of Bar codes with different Cd% not allowed (Bar Code :'+@cPurCdPc2+' Cd% :'+ltrim(rtrim(str(@nPurCdPct2,6,2)))+',
			Bar code :'+@cPurCdPc1+' Cd% :'+ltrim(rtrim(str(@nPurCdPct1,6,2)))+')'
		END
	END
	

END