create PROCEDURE  SP3S_ORDER_DETAILS_PO_WBO
(
	@CWHERE VARCHAR(100)=''
)
AS
BEGIN

--In Row Material stores order is in pod01106)
	--DECLARE @CWHERE VARCHAR(100)=''
	;WITH ORD_PLAN
	AS
	(
		SELECT BM.ORDER_ID,BM.ORDER_NO,BM.ORDER_DT,bm.Ref_no
		FROM POD01106 G (NOLOCK)                    
		JOIN BUYER_ORDER_DET BD (NOLOCK) ON (BD.ROW_ID   =G.WOD_ROW_ID   or bd.order_id =g.wod_row_id )
	    JOIN BUYER_ORDER_MST BM (NOLOCK) ON BM.ORDER_ID=BD.ORDER_ID
		WHERE G.po_id = @CWHERE  and bm.CANCELLED =0
		GROUP BY  BM.ORDER_ID,BM.ORDER_NO,BM.ORDER_DT,BM.REF_NO
	)

	SELECT  A.ORDER_NO AS BUYER_ORDER_NO,A.ORDER_DT AS BUYER_ORDER_DT,
	        A.REF_NO AS BUYER_ORDER_REF_NO,
			'' AS JOB_CARD_ID,'' AS JOB_CARD_NO
	FROM ORD_PLAN a
	
	
END

