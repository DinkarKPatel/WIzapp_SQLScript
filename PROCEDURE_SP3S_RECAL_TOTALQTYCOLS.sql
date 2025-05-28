CREATE PROCEDURE SP3S_RECAL_TOTALQTYCOLS
AS
BEGIN
	UPDATE a SET total_quantity=b.total_quantity FROM inm01106 a
	JOIN (SELECT inv_id,SUM(quantity) as total_quantity FROM ind01106 GROUP BY inv_id) b
	ON a.inv_id=b.inv_id
	WHERE ISNULL(a.TOTAL_QUANTITY,0)<>b.total_quantity OR a.TOTAL_QUANTITY IS NULL

	UPDATE a SET total_quantity=b.total_quantity FROM pim01106 a
	JOIN (SELECT mrr_id,SUM(quantity) as total_quantity FROM pid01106 GROUP BY mrr_id) b
	ON a.mrr_id=b.mrr_id
	WHERE ISNULL(a.TOTAL_QUANTITY,0)<>b.total_quantity OR a.TOTAL_QUANTITY IS NULL

	UPDATE a SET total_quantity=b.total_quantity FROM rmm01106 a
	JOIN (SELECT rm_id,SUM(quantity) as total_quantity FROM rmd01106 GROUP BY rm_id) b
	ON a.rm_id=b.rm_id
	WHERE ISNULL(a.TOTAL_QUANTITY,0)<>b.total_quantity OR a.TOTAL_QUANTITY IS NULL

	UPDATE a SET total_quantity=b.total_quantity FROM cnm01106 a
	JOIN (SELECT cn_id,SUM(quantity) as total_quantity FROM cnd01106 GROUP BY cn_id) b
	ON a.cn_id=b.cn_id
	WHERE ISNULL(a.TOTAL_QUANTITY,0)<>b.total_quantity OR a.TOTAL_QUANTITY IS NULL

	UPDATE a SET total_quantity=b.total_quantity FROM cmm01106 a
	JOIN (SELECT cm_id,SUM(quantity) as total_quantity FROM cmd01106 GROUP BY cm_id) b
	ON a.cm_id=b.cm_id
	WHERE ISNULL(a.TOTAL_QUANTITY,0)<>b.total_quantity OR a.TOTAL_QUANTITY IS NULL

	UPDATE a SET total_quantity=b.total_quantity FROM wps_mst a
	JOIN (SELECT ps_id,SUM(quantity) as total_quantity FROM wps_det GROUP BY ps_id) b
	ON a.ps_id=b.ps_id
	WHERE ISNULL(a.TOTAL_QUANTITY,0)<>b.total_quantity OR a.TOTAL_QUANTITY IS NULL

	UPDATE a SET total_quantity=b.total_quantity FROM DNPS_mst a
	JOIN (SELECT ps_id,SUM(quantity) as total_quantity FROM DNPS_det GROUP BY ps_id) b
	ON a.ps_id=b.ps_id
	WHERE ISNULL(a.TOTAL_QUANTITY,0)<>b.total_quantity OR a.TOTAL_QUANTITY IS NULL

	UPDATE a SET total_quantity=b.total_quantity FROM rps_mst a
	JOIN (SELECT cm_id,SUM(quantity) as total_quantity FROM rps_det GROUP BY cm_id) b
	ON a.cm_id=b.cm_id
	WHERE ISNULL(a.TOTAL_QUANTITY,0)<>b.total_quantity OR a.TOTAL_QUANTITY IS NULL
	
	UPDATE a SET total_quantity=b.total_quantity FROM cnps_mst a
	JOIN (SELECT ps_id,SUM(quantity) as total_quantity FROM cnps_det GROUP BY ps_id) b
	ON a.ps_id=b.ps_id
	WHERE ISNULL(a.TOTAL_QUANTITY,0)<>b.total_quantity OR a.TOTAL_QUANTITY IS NULL

	UPDATE a SET total_quantity=b.total_quantity FROM icm01106 a
	JOIN (SELECT cnc_memo_id,SUM(quantity) as total_quantity FROM icd01106 GROUP BY cnc_memo_id) b
	ON a.cnc_memo_id=b.cnc_memo_id
	WHERE ISNULL(a.TOTAL_QUANTITY,0)<>b.total_quantity OR a.TOTAL_QUANTITY IS NULL

	UPDATE a SET total_quantity=b.total_quantity FROM snc_mst a
	JOIN (SELECT memo_id,SUM(quantity) as total_quantity FROM snc_det GROUP BY memo_id) b
	ON a.memo_id=b.memo_id
	WHERE ISNULL(a.TOTAL_QUANTITY,0)<>b.total_quantity OR a.TOTAL_QUANTITY IS NULL

	UPDATE a SET total_consumed_quantity=b.total_quantity FROM snc_mst a
	JOIN (SELECT memo_id,SUM(quantity) as total_quantity FROM snc_consumable_det GROUP BY memo_id) b
	ON a.memo_id=b.memo_id
	WHERE ISNULL(a.total_consumed_quantity,0)<>b.total_quantity OR a.TOTAL_QUANTITY IS NULL

	UPDATE a SET total_quantity=b.total_quantity FROM apm01106 a
	JOIN (SELECT memo_id,SUM(quantity) as total_quantity FROM apd01106 GROUP BY memo_id) b
	ON a.memo_id=b.memo_id
	WHERE ISNULL(a.TOTAL_QUANTITY,0)<>b.total_quantity OR a.TOTAL_QUANTITY IS NULL

	UPDATE a SET total_quantity=b.total_quantity FROM approval_return_mst a
	JOIN (SELECT memo_id,SUM(quantity) as total_quantity FROM approval_return_det GROUP BY memo_id) b
	ON a.memo_id=b.memo_id
	WHERE ISNULL(a.TOTAL_QUANTITY,0)<>b.total_quantity OR a.TOTAL_QUANTITY IS NULL

	UPDATE a SET total_quantity=b.total_quantity FROM jobwork_issue_mst a
	JOIN (SELECT issue_id,SUM(quantity) as total_quantity FROM jobwork_issue_det GROUP BY issue_id) b
	ON a.issue_id=b.issue_id
	WHERE ISNULL(a.TOTAL_QUANTITY,0)<>b.total_quantity OR a.TOTAL_QUANTITY IS NULL

	UPDATE a SET total_quantity=b.total_quantity FROM jobwork_receipt_mst a
	JOIN (SELECT receipt_id,SUM(quantity) as total_quantity FROM jobwork_receipt_det GROUP BY receipt_id) b
	ON a.receipt_id=b.receipt_id
	WHERE ISNULL(a.TOTAL_QUANTITY,0)<>b.total_quantity OR a.TOTAL_QUANTITY IS NULL

	UPDATE a SET total_quantity=b.total_quantity FROM floor_st_mst a
	JOIN (SELECT memo_id,SUM(quantity) as total_quantity FROM floor_st_det GROUP BY memo_id) b
	ON a.memo_id=b.memo_id
	WHERE ISNULL(a.TOTAL_QUANTITY,0)<>b.total_quantity OR a.TOTAL_QUANTITY IS NULL

	UPDATE a SET total_quantity=b.total_quantity FROM grn_ps_mst a
	JOIN (SELECT memo_id,SUM(quantity) as total_quantity FROM grn_ps_det GROUP BY memo_id) b
	ON a.memo_id=b.memo_id
	WHERE ISNULL(a.TOTAL_QUANTITY,0)<>b.total_quantity OR a.TOTAL_QUANTITY IS NULL

END