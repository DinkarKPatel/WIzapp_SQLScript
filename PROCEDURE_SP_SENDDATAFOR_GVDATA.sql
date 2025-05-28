CREATE PROCEDURE SP_SENDDATAFOR_GVDATA  
(  
 @iMode INT=0,
 @cMemoId VARCHAR(50)  
)  
AS  
BEGIN  
  SELECT a.*,b.user_customer_code,b.mobile,a.memo_id as cm_id,ISNULL(c.allow_partial_redemption,0) 
  allow_multi_redemption
  FROM WC_GV_VALIDATE a(NOLOCK) 
  JOIN  custdym b (NOLOCK) ON a.customer_code=b.customer_code
  left join  sku_gv_mst c (NOLOCK) ON c.gv_srno=a.gv_srno
  WHERE MEMO_id=@cMemoId AND mode=@iMode  
  
  DELETE FROM wc_gv_validate with (rowlock) where  MEMO_id=@cMemoId AND mode=@iMode  
END

