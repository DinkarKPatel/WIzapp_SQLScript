CREATE PROCEDURE SP3S_CHKPRT_WO_PURPOSTING--(LocId 3 digit change only increased the parameter width by Sanjay:04-11-2024)
@NSPID VARCHAR(40),
@cLocId VARCHAR(4)
AS
BEGIN
	DECLARE @cProductCode VARCHAR(50),@cApprovalLocId VARCHAR(4),@cDnAllowDnWoPurPosting VARCHAR(4),@cMrrNo VARCHAR(50)
	
	
	SELECT TOP 1 @cApprovalLocId=dept_id FROM LOC_XNSAPPROVAL
	WHERE XN_TYPE='PUR'	 AND dept_id=@cLocId
	
	IF ISNULL(@cApprovalLocId,'')=''	
		RETURN

	SELECT TOP 1 @cDnAllowDnWoPurPosting=value FROM config where config_option='DnAllowDnWoPurPosting' 
	
	IF ISNULL(@cDnAllowDnWoPurPosting,'')<>'1'
		RETURN
	
	DECLARE @IMAXLEVEL INT
	
	--GETTING THE MAX LEVEL OF APPROVAL FOR PURCHASE TRANSACTION
	SELECT @IMAXLEVEL=MAX(LEVEL_NO) 
	FROM XN_APPROVAL_CHECKLIST_LEVELS 
	WHERE XN_TYPE='PUR' AND INACTIVE=0 AND ac_posting=1
	
	IF @IMAXLEVEL IS NULL
		SELECT @IMAXLEVEL=MAX(LEVEL_NO) 
		FROM XN_APPROVAL_CHECKLIST_LEVELS 
		WHERE XN_TYPE='PUR' AND INACTIVE=0
					
	SELECT TOP 1 @cProductCode=product_code FROM PRT_rmd01106_UPLOAD a (NOLOCK)
	JOIN pim01106 b ON a.mrr_id=b.mrr_id WHERE SP_ID=@NSPID AND ApprovedLevelNo<@IMAXLEVEL
	
	IF ISNULL(@cProductCode,'')<>''
	BEGIN
		SELECT DISTINCT b.Mrr_no,rm_id as memo_id,'Mrr(s) are Pending for Approval' FROM 
		PRT_rmd01106_UPLOAD a (NOLOCK)
		JOIN pim01106 b (NOLOCK) ON a.mrr_id=b.mrr_id WHERE SP_ID=@NSPID AND ApprovedLevelNo<@IMAXLEVEL
	END	

	
	
END

/*

select approvedlevelno,mrr_id,bill_dt,* from pim01106 where mrr_no like '%ho00-000710%'

select * from postact_voucher_link where memo_id='HO011200000HO00-000710'

select cancelled,* from vm01106 where vm_id='HO9121BF2D-0F22-483E-B1AC-CC86ABD03AE4'

SELECT MAX(LEVEL_NO) 
	FROM XN_APPROVAL_CHECKLIST_LEVELS 
	WHERE XN_TYPE='PUR' AND INACTIVE=0
select * FROM XN_APPROVAL_CHECKLIST_LEVELS 
	WHERE XN_TYPE='PUR' AND INACTIVE=0	
*/