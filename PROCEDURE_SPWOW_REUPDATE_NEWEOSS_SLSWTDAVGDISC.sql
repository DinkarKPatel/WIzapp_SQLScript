create PROCEDURE SPWOW_REUPDATE_NEWEOSS_SLSWTDAVGDISC
AS
BEGIN
	DECLARE @NGROSSSALE NUMERIC(10,2),@NNETSALE NUMERIC(10,2),
	@BSLSDISCOUNTDISABLED BIT,@NNETAMOUNT NUMERIC(10,2),@CCMDROWID VARCHAR(40),@NDISCAMT NUMERIC(10,2),
	@NTOTWTDDISC NUMERIC(10,2),@cCmId varchar(50),@cSchemeName varchar(200),
	@dCmDt DATETIME,@nSlrqty NUMERIC(10,2),@nLoop INT,@nLoopCnt INT,@nSign INT

	select b.cm_id,cm_no,cm_dt, scheme_name,sum(weighted_avg_disc_amt) wtddisc,
	sum(basic_discount_amount) basicdisc,sum(case when quantity<0 then quantity else 0 end) slrqty
	into #tmpdiff from  
	cmd01106 a (nolock) join cmm01106 b (nolock) on a.cm_id=b.cm_id
	where cm_dt>='2024-04-01' 
	group by b.cm_id,cm_no,cm_dt,scheme_name
	having abs(sum(weighted_avg_disc_amt)-sum(basic_discount_amount))>5 and
	sum(basic_discount_amount)<>0

	IF NOT EXISTS (SELECT TOP 1 cm_id FROM #tmpdiff)
		RETURN
	
	create table #tmpschemes (schemename varchar(200))

	while exists (select top 1 * from  #tmpdiff)
	begin
		select top 1 @cCmId=cm_id,@dCmDt=cm_dt,@nSlrqty=slrqty from #tmpdiff order by cm_dt

		set @nLoopCnt=(case when @nSlrqty<>0 THEN 2 ELSE 1 END)
		
		set @nLoop=1
		while @nLoop<=@nLoopCnt
		begin
			print 'Reupdating Weighted discounts for Bill date:'+convert(varchar,@dCmdt,105)+' CmId: '+@cCmId
			insert into #tmpschemes (schemename) 
			select scheme_name from  #tmpdiff where cm_id=@cCmId

			set @nSign=(case when @nLoop=1 then 1 else -1 end)
			WHILE exists (Select top 1 * from  #tmpschemes)
			BEGIN
				select top 1 @cSchemeName=schemename from  #tmpschemes
				SELECT @NGROSSSALE=0,@NNETSALE=0
		
				SELECT TOP 1 @CCMDROWID=ROW_ID FROM CMD01106 WHERE CM_ID=@CCMID AND
				scheme_name=@cSchemeName	AND sign(QUANTITY)=@nSign AND DISCOUNT_PERCENTAGE=100
				
				SELECT @NDISCAMT=SUM(DISCOUNT_AMOUNT) FROM CMD01106 WHERE CM_ID=@CCMID 
				AND scheme_name=@cSchemeName	AND sign(QUANTITY)=@nSign AND DISCOUNT_PERCENTAGE=100
		
				SELECT @NGROSSSALE=SUM(MRP*QUANTITY),@NNETSALE=SUM(RFNET),@NNETAMOUNT=SUM((MRP*QUANTITY*DISCOUNT_PERCENTAGE)/100) FROM CMD01106 WHERE CM_ID=@CCMID 
				AND scheme_name=@cSchemeName AND sign(QUANTITY)=@nSign
		
				UPDATE CMD01106 SET WEIGHTED_AVG_DISC_PCT=((@NGROSSSALE-@NNETSALE)/@NGROSSSALE)*100
				WHERE CM_ID=@CCMID AND scheme_name=@cSchemeName AND sign(QUANTITY)=@nSign
		
				UPDATE CMD01106 SET WEIGHTED_AVG_DISC_AMT=(MRP*QUANTITY*WEIGHTED_AVG_DISC_PCT/100) WHERE CM_ID=@CCMID
				AND scheme_name=@cSchemeName AND sign(QUANTITY)=@nSign
		
		
				SELECT @NTOTWTDDISC=SUM(WEIGHTED_AVG_DISC_AMT) FROM CMD01106 WHERE CM_ID=@CCMID	
				AND scheme_name=@cSchemeName AND sign(QUANTITY)=@nSign
		
				IF ABS(@NTOTWTDDISC-@NDISCAMT)>0
				BEGIN
					PRINT 'DIF FOUND'
					UPDATE CMD01106 SET WEIGHTED_AVG_DISC_AMT=WEIGHTED_AVG_DISC_AMT+(@NDISCAMT-@NTOTWTDDISC)
					WHERE ROW_ID=@CCMDROWID
				END	
			
				delete from  #tmpschemes where schemename=@cSchemeName
			END

			set @nLoop=@nLoop+1
		end

		delete from #tmpdiff where cm_id=@cCmId
	end

END
