CREATE PROCEDURE SP3S_UPDATE_STOCK_IN_EDIT
(
	@cTABLE_NAME	VARCHAR(100),
	@cMEMO_ID		VARCHAR(50)
)
AS
BEGIN
	IF @cTABLE_NAME='CMD01106'
	BEGIN
		SELECT a.ref_cmd_row_id 
		INTO #SP3S_UPDATE_STOCK_IN_EDIT
		FROM hold_back_deliver_det a
		JOIN hold_back_deliver_mst b ON b.memo_id=a.memo_id
		JOIN CMD01106 C ON C.ROW_ID=a.ref_cmd_row_id
		WHERE b.cancelled=0 and c.cm_id=@cMEMO_ID

		SELECT b.row_id,B.product_code,ISNULL(ART.FIX_MRP_Applicable ,0) AS FIX_MRP_Applicable,ISNULL(A.quantity_in_stock,0)+B.QUANTITY AS  quantity_in_stock
		,selling_days,SIS_NET,sisloc_eoss_discount_percentage,sisloc_eoss_discount_amount,sisloc_mrp,sisloc_gst_percentage,sisloc_taxable_value,sisloc_lgst_amount,
		sisloc_igst_amount,sisloc_itemnet_difference,sisloc_gst_difference,ISNULL(HBD.ref_cmd_row_id,'') AS HBD_REF_CMD_ROW_ID
		FROM  CMD01106 B  
		JOIN CMM01106 CMM ON B.CM_ID= CMM.CM_ID 
		join sku sn (Nolock) on B.PRODUCT_CODE =sn.product_Code 
		JOIN ARTICLE ART (NOLOCK) ON ART.ARTICLE_CODE=sn.ARTICLE_CODE
		LEFT OUTER JOIN PMT01106 A ON A.product_code=B.product_code AND A.DEPT_ID=CMM.location_Code  AND A.BIN_ID=B.BIN_ID
		LEFT OUTER JOIN #SP3S_UPDATE_STOCK_IN_EDIT HBD ON HBD.ref_cmd_row_id=B.ROW_ID 
		WHERE B.CM_ID=@cMEMO_ID
	END
	ELSE IF @cTABLE_NAME='RPS_DET'
	BEGIN
		SELECT b.row_id,B.product_code,ISNULL(ART.FIX_MRP_Applicable ,0) AS FIX_MRP_Applicable,ISNULL(A.quantity_in_stock,0)+B.QUANTITY AS  quantity_in_stock
		FROM  RPS_DET B  
		JOIN RPS_MST CMM ON B.CM_ID= CMM.CM_ID 
		join sku sn (Nolock) on B.PRODUCT_CODE =sn.product_Code 
		JOIN ARTICLE ART (NOLOCK) ON ART.ARTICLE_CODE=sn.ARTICLE_CODE
		LEFT OUTER JOIN PMT01106 A ON A.product_code=B.product_code AND A.DEPT_ID=CMM.location_Code  AND A.BIN_ID=B.BIN_ID
		WHERE B.CM_ID=@cMEMO_ID
	END
	ELSE IF @cTABLE_NAME='DNPS_DET'
	BEGIN
		SELECT b.row_id,B.product_code,ISNULL(ART.FIX_MRP_Applicable ,0) AS FIX_MRP_Applicable,ISNULL(A.quantity_in_stock,0)+B.QUANTITY AS  quantity_in_stock
		FROM  DNPS_DET B  
		JOIN DNPS_MST CMM ON B.PS_ID= CMM.PS_ID 
		join sku sn (Nolock) on B.PRODUCT_CODE =sn.product_Code 
		JOIN ARTICLE ART (NOLOCK) ON ART.ARTICLE_CODE=sn.ARTICLE_CODE
		LEFT OUTER JOIN PMT01106 A ON A.product_code=B.product_code AND A.DEPT_ID=CMM.location_Code  AND A.BIN_ID=B.BIN_ID
		WHERE B.PS_ID=@cMEMO_ID
	END
	ELSE
	SELECT CAST('' AS VARCHAR(100)) AS row_id,CAST('' AS VARCHAR(100)) AS product_code,CAST(0 AS numeric(14,3)) AS FIX_MRP_Applicable,CAST(0 AS numeric(14,3)) AS quantity_in_stock
END