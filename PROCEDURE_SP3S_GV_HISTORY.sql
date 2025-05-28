CREATE PROCEDURE SP3S_GV_HISTORY
@cGvSrno varchar(50)
AS
BEGIN
	SELECT a.gv_srno AS [GV NO.],adv_rec_dt AS [MEMO DT],'Cr' as [TYPE],
	adv_rec_NO AS [MEMO NO.],b.denomination xn_amount,a.dt_expiry
	FROM sku_gv_mst a (NOLOCK) 
	LEFT join 
	(SELECT gv_srno,adv_rec_no,denomination,adv_rec_dt FROM  arc_gvsale_details b (NOLOCK) 
	 JOIN arc01106 c (NOLOCK) ON c.adv_rec_id=b.adv_rec_id
	 WHERE b.gv_srno=@cGvSrno AND cancelled=0) b ON a.gv_srno=b.gv_srno
	WHERE a.gv_srno=@cGvSrno
	UNION ALL
	SELECT a.gv_srno AS [GV NO.],c.CM_dt AS [MEMO DT],'Dr' as [TYPE],
	c.cm_NO AS [MEMO NO.],b.amount xn_amount,a.dt_expiry
	FROM sku_gv_mst a (NOLOCK) 
	join paymode_xn_det b (NOLOCK) ON b.gv_srno=a.gv_srno
	JOIN cmm01106 c (NOLOCK) ON c.cm_id=b.memo_id
	WHERE a.gv_srno=@cGvSrno AND cancelled=0

	ORDER BY [MEMO DT],[MEMO NO.]
END

