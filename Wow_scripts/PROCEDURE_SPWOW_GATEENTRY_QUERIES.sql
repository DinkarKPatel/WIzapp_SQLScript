CREATE PROCEDURE SPWOW_GATEENTRY_QUERIES
@nQueryId INT=1,
@cMemoId VARCHAR(50)='',
@dFromDt DATETIME='',
@dToDt DATETIME=''
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@nFileCount INT

	IF @nQueryId=1
		GOTO lblMemoDetails
	ELSE
	IF @nQueryId=2
		GOTO lblListofMemos
	ELSE
		GOTO lblLast
lblMemoDetails:
	
	select a.parcel_memo_id parcelMemoId, parcel_memo_no parcelNo,a.bilty_no biltyNo, a.gate_entry_no partyRefNo,a.Cancelled,
    Format(parcel_memo_dt,'dd-MMM-yyy') parcelDt,a.parcel_type itemType,XN_ITEM_TYPE_DESC itemTypeDesc, d.Angadia_name transporterName,parcel_ac_code partyCode,
	b.ac_name Party,total_amount totalAmount,(CASE WHEN grn.ref_gateentry_memo_id IS NOT NULL THEN 1 ELSE 0 END) grnCreated,a.angadia_code transporterCode,a.Remarks,
	a.driver_name driverName,a.vehicle_no vehicleNo,a.pay_mode paymentType,
	TOT_QUANTITY totalQuantity,TOT_WEIGHT totalWeight,tot_boxes totalNoOfBoxes
    from parcel_mst a JOIN lm01106 b ON a.PARCEL_AC_CODE = b.AC_CODE 
    JOIN angm d ON d.Angadia_code = a.angadia_code
    JOIN XN_ITEM_TYPE_DESC_mst c on c.xn_item_type = a.parcel_type 
    LEFT JOIN  grn_ps_mst grn (NOLOCK) ON grn.ref_gateentry_memo_id=a.parcel_memo_id AND grn.cancelled=0 
    WHERE a.parcel_memo_id =@cMemoId

    select a.parcel_memo_id parcelMemoId,row_id rowId,Quantity,PARTY_INV_NO partyInvoiceNo,invItemsweight weight,box_no noOfBoxes,
	convert(bit,0) deleted
    from parcel_det a (NOLOCK) WHERE a.parcel_memo_id =@cMemoId

    SET @cCmd=N'SELECT fileName,img_id imageId,convert(bit,0) deleted FROM '+DB_NAME()+'_IMAGE..IMAGE_INFO_DOC WHERE memo_id='''+@cMemoId+''' AND  filename is not null'
	EXEC SP_EXECUTESQL @cCmd
	GOTO lblLast

lblListofMemos:
	CREATE TABLE #tblFileCnt (memo_id VARCHAR(50),fileCount INT)

    SET @cCmd=N'SELECT memo_id,count(*) FROM '+DB_NAME()+'_IMAGE..IMAGE_INFO_DOC (NOLOCK) WHERE xn_type=''frmParcel'' AND  filename is not null
	            GROUP BY memo_id'
	

	INSERT INTO #tblFileCnt (memo_id,fileCount)
	EXEC SP_EXECUTESQL @cCmd

	select a.parcel_memo_id parcelMemoId, parcel_memo_no parcelNo,a.bilty_no biltyNo, a.gate_entry_no partyRefNo,a.Cancelled,
	parcel_memo_dt parcelDt,XN_ITEM_TYPE_DESC itemTypeDesc, d.Angadia_name transporterName, b.ac_name Party,
	total_amount totalAmount,(CASE WHEN grn.ref_gateentry_memo_id IS NOT NULL THEN 1 ELSE 0 END) grnCreated,ISNULL(f.FileCount,0) filesCount,
	TOT_QUANTITY totalQuantity,TOT_WEIGHT totalWeight,tot_boxes totalNoOfBoxes
	from parcel_mst a JOIN lm01106 b ON a.PARCEL_AC_CODE = b.AC_CODE 
	JOIN angm d ON d.Angadia_code = a.angadia_code
	JOIN XN_ITEM_TYPE_DESC_mst c on c.xn_item_type = a.parcel_type 
	LEFT JOIN  grn_ps_mst grn (NOLOCK) ON grn.ref_gateentry_memo_id=a.parcel_memo_id AND grn.cancelled=0 
	LEFT JOIN #tblFileCnt f on f.memo_id=a.parcel_memo_id

	WHERE a.parcel_memo_dt BETWEEN @dFromDt AND @dToDt 

	GOTO lblLast

lblLast:
END
