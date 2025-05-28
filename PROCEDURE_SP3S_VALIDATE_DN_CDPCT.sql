CREATE PROCEDURE SP3S_VALIDATE_DN_CDPCT
@cMemoId VARCHAR(40),
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN	
	DECLARE @nPurCdPct1 NUMERIC(6,2),@nDnTermsCdPct1 NUMERIC(6,2),@nPurCdPct2  NUMERIC(6,2),@nDnTermsCdPct2  NUMERIC(6,2),
	@nMode NUMERIC(1,0),@cPurCdPc1 VARCHAR(50),@cDnTermsPc1 VARCHAR(50),@cPurCdPc2 VARCHAR(50),@cDnTermsPc2 VARCHAR(50),
	@cApplyCdonTotal1 VARCHAR(5),@cApplyCdonTotal2 VARCHAR(5),@bEnableDnPosting BIT

	SELECT TOP 1 @nMode=mode FROM  rmm01106 (NOLOCK) WHERE rm_id=@cMemoId


	select @bEnableDnPosting=ISNULL(enableposting,0) from gst_accounts_config_mst where xn_type='prt' 

	IF @nMode=2 OR @bEnableDnPosting=0
		RETURN

	SELECT top 1 @nPurCdPct1=(CASE WHEN ISNULL(a.terms,'')<>'' THEN substring(terms,dbo.CHARINDEX_NTH('-',terms,1,5)+1,
			dbo.CHARINDEX_NTH('-',terms,1,6)-dbo.CHARINDEX_NTH('-',terms,1,5)-1) 
	ELSE a.pur_cd_percentage END),@cApplyCdonTotal1=ISNULL(SUBSTRING(terms,DBO.CHARINDEX_NTH('-',Terms,1,10)+1,1),''),
	@cPurCdPc1=a.product_code 
	FROM rmd01106 a (NOLOCK)
	WHERE a.rm_id=@cMemoId AND (ISNULL(a.terms,'')<>'' OR ISNULL(a.pur_cd_percentage,0)<>0)

	
	IF ISNULL(@cPurCdPc1,'')<>''
	BEGIN
		SELECT top 1 @nPurCdPct2=(CASE WHEN ISNULL(a.terms,'')<>'' THEN substring(terms,dbo.CHARINDEX_NTH('-',terms,1,5)+1,
			dbo.CHARINDEX_NTH('-',terms,1,6)-dbo.CHARINDEX_NTH('-',terms,1,5)-1)
		ELSE a.pur_cd_percentage END),@cApplyCdonTotal2=ISNULL(SUBSTRING(terms,DBO.CHARINDEX_NTH('-',Terms,1,10)+1,1),''),@cPurCdPc2=a.product_code 
		FROM rmd01106 a (NOLOCK)
		WHERE a.rm_id=@cMemoId AND (CASE WHEN ISNULL(a.terms,'')<>'' THEN substring(terms,dbo.CHARINDEX_NTH('-',terms,1,5)+1,
			dbo.CHARINDEX_NTH('-',terms,1,6)-dbo.CHARINDEX_NTH('-',terms,1,5)-1)
		ELSE a.pur_cd_percentage END)<>@nPurCdPct1

		IF ISNULL(@cPurCdPc2,'')<>''
		BEGIN
			SET @cErrormsg='Mixing of Bar codes with different Cd% not allowed (Bar Code :'+@cPurCdPc2+' Cd% :'+ltrim(rtrim(str(@nPurCdPct2,6,2)))+',
			Bar code :'+@cPurCdPc1+' Cd% :'+ltrim(rtrim(str(@nPurCdPct1,6,2)))+')'
		END
	END
	

END