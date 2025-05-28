CREATE PROCEDURE SP3S_REP_ACCOUNTSRECO
@dRecoDate DATETIME='',
@cXnType VARCHAR(20)='',
@BUpdateLupd bit=0
AS

BEGIN
	DECLARE @dPurCutoffDate DATETIME,@dWslCutoffDate DATETIME,@dPrtCutoffDate DATETIME,@dWsrCutoffDate DATETIME

	IF @dRecoDate<>''
		SELECT @dPurCutoffDate=@dRecoDate,@dWslCutoffDate=@dRecoDate,@dWslCutoffDate=@dRecoDate,@dWslCutoffDate=@dRecoDate
    ELSE
	BEGIN
		SELECT TOP 1 @dPurCutoffDate=cutoffdate FROM gst_accounts_config_mst (NOLOCK) WHERE xn_type='PUR'
		SELECT TOP 1 @dWslCutoffDate=cutoffdate FROM gst_accounts_config_mst (NOLOCK) WHERE xn_type='WSL'
		SELECT TOP 1 @dPrtCutoffDate=cutoffdate FROM gst_accounts_config_mst (NOLOCK) WHERE xn_type='PRT'
		SELECT TOP 1 @dWsrCutoffDate=cutoffdate FROM gst_accounts_config_mst (NOLOCK) WHERE xn_type='WSR'
	END
	
	CREATE TABLE #tmpReco (xn_type varchar(20),ac_name varchar(200),memo_no varchar(50),memo_dt datetime,posted_voucher_dt datetime,memo_amount numeric(10,2),memo_cancelled bit,posted_amount numeric(14,2),memo_id varchar(50),posted_xn_type varchar(10))

	IF @cXnType in ('','PUR')
	INSERT #tmpReco 
	SELECT 'PURCHASE' AS xn_type,ISNULL(a.ac_name,'') AS ac_name,ISNULL(a.memo_no,b.memo_id) AS memo_no,ISNULL(a.memo_dt,'') AS memo_dt,
	ISNULL(b.memo_dt,'') AS posted_voucher_dt,
	ISNULL(a.memo_amount,0) AS memo_amount,ISNULL(a.cancelled,0) AS memo_cancelled,ISNULL(b.posted_amount,0) AS posted_amount,isnull(a.mrr_id,b.memo_id) as memo_id,'pur' as posted_xn_type
	FROM 
	(
	 select ac_name,a.mrr_ID, mrr_no AS memo_no,bill_dt AS memo_dt, a.cancelled, a.ac_code,a.total_amount as memo_amount
	 from pim01106 a JOIN lm01106 b ON a.ac_code=b.AC_CODE WHERE receipt_DT>@dPurCutoffDate AND inv_mode=1
	 AND bill_challan_mode=0 
	) a 
	FULL OUTER join 
	(select memo_id,sum(drtotal) as posted_amount,VOUCHER_DT as memo_dt from postact_voucher_link a join vm01106 b on a.vm_id=b.vm_id
	 where cancelled=0 and xn_type='PUR' and voucher_dt>@dPurCutoffDate group by VOUCHER_DT,memo_id) b on a.mrr_id=b.memo_id
	 
	 where ((abs(ISNULL(a.memo_amount,0)-ISNULL(b.posted_amount,0))>1 OR ISNULL(a.memo_dt,'')<>ISNULL(b.memo_dt,'') 
		or  (ISNULL(a.cancelled,0)=1 and b.memo_id is  not null))) and not (ISNULL(a.cancelled,0)=1 and b.memo_id is  null)
	
	IF @cXnType in ('','WSL')
	INSERT #tmpReco 
	SELECT 'WHOLESALE' AS xn_type,ISNULL(a.ac_name,'') AS ac_name,ISNULL(a.memo_no,b.memo_id) AS memo_no,ISNULL(a.memo_dt,'') AS memo_dt,
	ISNULL(b.memo_dt,'') AS posted_voucher_dt,
	ISNULL(a.memo_amount,0) AS memo_amount,ISNULL(a.cancelled,0) AS memo_cancelled,ISNULL(b.posted_amount,0) AS posted_amount,isnull(a.inv_id,b.memo_id) as memo_id,'wsl' as posted_xn_type
	FROM 
	(
	 select ac_name,a.INV_ID, inv_no AS memo_no,inv_dt AS memo_dt, a.cancelled, a.ac_code,a.net_amount as memo_amount
	 from inm01106 a JOIN lm01106 b ON a.ac_code=b.AC_CODE WHERE INV_DT>@dWslCutoffDate AND inv_mode=1
	) a 
	FULL OUTER join 
	(select memo_id,sum(drtotal) as posted_amount,VOUCHER_DT as memo_dt from postact_voucher_link a join vm01106 b on a.vm_id=b.vm_id
	 where cancelled=0 and xn_type='wsl' and voucher_dt>@dPurCutoffDate group by VOUCHER_DT,memo_id) b on a.inv_id=b.memo_id
	 
	 where ((abs(ISNULL(a.memo_amount,0)-ISNULL(b.posted_amount,0))>1 OR ISNULL(a.memo_dt,'')<>ISNULL(b.memo_dt,'') 
		or  (ISNULL(a.cancelled,0)=1 and b.memo_id is  not null))) and not (ISNULL(a.cancelled,0)=1 and b.memo_id is  null)
	
	IF @cXnType in ('','PRT')
	INSERT #tmpReco  
	SELECT 'DEBIT NOTE' AS xn_type,ISNULL(a.ac_name,'') AS ac_name,ISNULL(a.memo_no,b.memo_id) AS memo_no,ISNULL(a.memo_dt,'') AS memo_dt,
	ISNULL(b.memo_dt,'') AS posted_voucher_dt,
	ISNULL(a.memo_amount,0) AS memo_amount,ISNULL(a.cancelled,0) AS memo_cancelled,ISNULL(b.posted_amount,0) AS posted_amount,isnull(a.rm_id,b.memo_id) as memo_id,'prt' as posted_xn_type
	FROM 
	(
	 select ac_name,a.rm_id, rm_no AS memo_no,rm_dt AS memo_dt, a.cancelled, a.ac_code,a.total_amount as memo_amount
	 from rmm01106 a JOIN lm01106 b ON a.ac_code=b.AC_CODE WHERE rm_DT>@dPrtCutoffDate AND mode=1
	) a 
	FULL OUTER join 
	(select memo_id,sum(drtotal) as posted_amount,VOUCHER_DT as memo_dt from postact_voucher_link a join vm01106 b on a.vm_id=b.vm_id
	 where cancelled=0 and xn_type='PRT' and voucher_dt>@dPurCutoffDate group by VOUCHER_DT,memo_id) b on a.rm_id=b.memo_id
	 
	 where ((abs(ISNULL(a.memo_amount,0)-ISNULL(b.posted_amount,0))>1 OR ISNULL(a.memo_dt,'')<>ISNULL(b.memo_dt,'') 
		or  (ISNULL(a.cancelled,0)=1 and b.memo_id is  not null))) and not (ISNULL(a.cancelled,0)=1 and b.memo_id is  null)
	 
	IF @cXnType in ('','WSR')
	INSERT #tmpReco 
	SELECT 'CREDIT NOTE' AS xn_type,ISNULL(a.ac_name,'') AS ac_name,ISNULL(a.memo_no,b.memo_id) AS memo_no,ISNULL(a.memo_dt,'') AS memo_dt,
	ISNULL(b.memo_dt,'') AS posted_voucher_dt,
	ISNULL(a.memo_amount,0) AS memo_amount,ISNULL(a.cancelled,0) AS memo_cancelled,ISNULL(b.posted_amount,0) AS posted_amount,isnull(a.cn_id,b.memo_id) as memo_id,'wsr' as posted_xn_type
	FROM 
	(
	 select ac_name,a.cn_id, cn_no AS memo_no,cn_dt AS memo_dt, a.cancelled, a.ac_code,a.total_amount as memo_amount
	 from cnm01106 a JOIN lm01106 b ON a.ac_code=b.AC_CODE WHERE cn_DT>@dWsrCutoffDate AND mode=1
	) a 
	FULL OUTER join 
	(select memo_id,sum(drtotal) as posted_amount,VOUCHER_DT as memo_dt from postact_voucher_link a join vm01106 b on a.vm_id=b.vm_id
	 where cancelled=0 and xn_type='WSR' and voucher_dt>@dPurCutoffDate group by VOUCHER_DT,memo_id) b on a.cn_id=b.memo_id
	 
	 where ((abs(ISNULL(a.memo_amount,0)-ISNULL(b.posted_amount,0))>1 OR ISNULL(a.memo_dt,'')<>ISNULL(b.memo_dt,'') 
		or  (ISNULL(a.cancelled,0)=1 and b.memo_id is  not null))) and not (ISNULL(a.cancelled,0)=1 and b.memo_id is  null)
	
	IF @BUpdateLupd=0
		select * from #tmpReco order by xn_type,memo_dt
	ELSE
	IF @cXntype='PUR'
		UPDATE a set last_update=getdate() from POSTACT_VOUCHER_LINK a
		JOIN #tmpReco b ON a.MEMO_ID=b.memo_id 
		WHERE A.xn_type='pur'
	
END