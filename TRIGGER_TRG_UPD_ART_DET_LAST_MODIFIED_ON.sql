create TRIGGER [DBO].[TRG_UPD_ART_DET_LAST_MODIFIED_ON] ON [DBO].ART_DET
FOR INSERT,UPDATE
AS
BEGIN
    
	INSERT INTO opt_sku_diff (master_code,master_tablename)
	SELECT a.ROW_ID,'ART_DET' diff_type FROM DELETED a
	JOIN INSERTED b ON b.row_id=a.row_id
	LEFT JOIN  opt_sku_diff df (NOLOCK) ON a.ROW_ID=df.master_code AND df.master_tablename='ART_DET'	
	WHERE ( ISNULL(a.boxWeight,0)<>ISNULL(b.boxWeight,0)
	)
	AND df.master_code IS NULL

	IF (SELECT TRIGGER_NESTLEVEL())> 1  OR dbo.FN_CHECKHOLOC()=0
		RETURN
			
	UPDATE ART_DET SET LAST_MODIFIED_ON=CAST(GETDATE() AS DATE) 
	FROM DELETED B WHERE B.row_id=ART_DET.row_id
	AND (ART_DET.para1_code <> B.para1_code OR ART_DET.para2_code <> B.para2_code OR ART_DET.WS_PRICE <> B.WS_PRICE OR ART_DET.MRP <> B.MRP
	 or ART_DET.mrp_inc_amt<> B.mrp_inc_amt or ART_DET.mrp2<> B.mrp2 OR ART_DET.para2_ratio <> B.para2_ratio 
	 OR ART_DET.purchase_price<> B.purchase_price OR ART_DET.center_point<> B.center_point OR ART_DET.sizegroup_code<> B.sizegroup_code   )
END
