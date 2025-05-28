CREATE PROCEDURE SP3S_PROCESS_REPAIR
(
	@NQID			INT,
	@DTTODAYDATE	DATETIME,
	@bShowAll		INT=0,
	@cDeptID		VARCHAR(5)='',
	@cProductCode	VARCHAR(100)='',
	@cUserCode		VARCHAR(10)=''
)
AS
BEGIN
	DECLARE @CHEADCODE VARCHAR(MAX) ,@CHEADCODE1 VARCHAR(MAX) 
	IF @NQID=1
	BEGIN
		--if @bShowAll=1--Rohit 01-12-2022 Agianst Ticket No : 12-0071 SSPL
		EXEC SP3S_HBD_APPROVAL_STATUS @bShowAll=@bShowAll,  @DASONDATE =@DTTODAYDATE,@cLocId=@cDeptID,@cUserCode=@cUserCode
		--else
		--EXEC SP3S_HBD_APPROVAL_STATUS @bShowAll=  @DASONDATE ='',@cLocId=@cDeptID
	END
	ELSE IF @NQID=2
	BEGIN
		SELECT CAST(0 AS INT) AS HBD_STATUS,'---SELECT---' AS HBD_STATUS_NAME		
		UNION ALL
		SELECT CAST(1 AS INT) AS HBD_STATUS,'Approve & Issue Credit Note' AS HBD_STATUS_NAME 
		UNION ALL
		SELECT CAST(2 AS INT) AS HBD_STATUS,'Free Repair & Return' AS HBD_STATUS_NAME 
		UNION ALL
		SELECT CAST(3 AS INT) AS HBD_STATUS,'Charged Repair & Return' AS HBD_STATUS_NAME 
		UNION ALL
		SELECT CAST(4 AS INT) AS HBD_STATUS,'Disapprove & Return' AS HBD_STATUS_NAME 
		ORDER BY HBD_STATUS
	END
	ELSE IF @NQID=3
	BEGIN
		
		SELECT CAST(0 AS INT) AS PROCESS, '' AS PROCESS_NAME
		UNION ALL
		SELECT CAST(1 AS INT) AS PROCESS,'Return to Customer' AS PROCESS_NAME 
		UNION ALL
		SELECT CAST(2 AS INT) AS PROCESS,'Jobwork Issue' AS PROCESS_NAME 
		ORDER BY PROCESS
	END
	ELSE IF @NQID=4
	BEGIN
		DECLARE @cPC VARCHAR(MAX),@cErrMsg VARCHAR(MAX),@nBarcodeCodingScheme NUMERIC(2)
		SELECT @cPC =PRODUCT_CODE,@nBarcodeCodingScheme =barcode_coding_scheme FROM SKU WHERE PRODUCT_CODE= @cProductCode
		IF ISNULL(@cPC,'')=''
		BEGIN
			SET @cErrMsg='Product Code Not Found......'
		END
		
		SELECT ISNULL(@cProductCode,'') AS PRODUCT_CODE,ISNULL(@cErrMsg,'') AS ERR_MSG,ISNULL(@nBarcodeCodingScheme,0) as Barcode_Coding_Scheme
		
	END
	ELSE IF @NQID=5
	BEGIN
		--select rep_id AS MsgCode,SMS ,'' as sender,@cDeptID as dept_id
		--from rep_crm 
		--where rep_id IN ('MSCFIX0036','MSCFIX0037','MSCFIX0038','MSCFIX0039','MSCFIX0040','MSCFIX0041')
		--AND ISNULL(SMS,'')<>''

		select a.rep_id AS MsgCode,a.SMS ,'' as sender,@cDeptID as dept_id
		from rep_crm a
		Left outer join loc_rep_crm b on a.rep_id= b.rep_id
		where a.rep_id IN ('MSCFIX0036','MSCFIX0037','MSCFIX0038','MSCFIX0039','MSCFIX0040','MSCFIX0041')
		AND ISNULL(a.SMS,'')<>'' and b.rep_id is null
		union 
		select rep_id AS MsgCode,SMS ,sender,dept_id
		from loc_rep_crm 
		where rep_id IN ('MSCFIX0036','MSCFIX0037','MSCFIX0038','MSCFIX0039','MSCFIX0040','MSCFIX0041')
		AND ISNULL(SMS,'')<>''
		order by MsgCode
	END
END