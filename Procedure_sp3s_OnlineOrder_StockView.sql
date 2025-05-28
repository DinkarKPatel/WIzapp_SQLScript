create Procedure sp3s_OnlineOrder_StockView
(
 @nspid varchar(50)='',
 @CUserCode varchar(10)='0000000',
 @cdept_id varchar(5)='01'
)
as
begin
     
	

	 SELECT C.ORDER_NO ,C.ORDER_DT,B.PARA7_CODE ,b.quantity as Order_qty,C.Ref_no,CASE WHEN B.quantity<0 THEN 'Sale Return' ELSE 'Sale' END as SaleType
	      into #tmpordPara7
	 FROM wslord_online_order_upload A (nolock)
	 JOIN BUYER_ORDER_DET B (nolock) ON A.ORDER_ID =B.ORDER_ID
	 JOIN BUYER_ORDER_MST C (nolock) ON C.ORDER_ID=B.ORDER_ID
	 WHERE A.SP_ID=@nspid

	 

	 SELECT A.PARA7_CODE, BIN.BIN_NAME , PMT.BIN_ID,
	        SUM(PMT.QUANTITY_IN_STOCK) AS STOCKQTY 
	into #tmpstock
	FROM 
	 (
	 SELECT PARA7_CODE  FROM #TMPORDPARA7 A
	 GROUP BY PARA7_CODE
	 ) A
	 JOIN SKU  (NOLOCK) ON A.PARA7_CODE =SKU.PARA7_CODE
     JOIN PMT01106 PMT (NOLOCK) ON SKU.PRODUCT_CODE =PMT.PRODUCT_CODE
	 JOIN BIN (NOLOCK) ON BIN.BIN_ID=PMT.BIN_ID
     JOIN BINUSERS B (NOLOCK) ON BIN.MAJOR_BIN_ID =B.BIN_ID      
	 WHERE PMT.QUANTITY_IN_STOCK >0
	 and b.user_code=@CUserCode and pmt.DEPT_ID=@cdept_id
	 and isnull(pmt.bo_order_id,'')=''
	 and pmt.BIN_ID<>'999'
	 GROUP BY A.PARA7_CODE,BIN.BIN_NAME ,PMT.BIN_ID

	

	 SELECT A.ORDER_NO ,A.ORDER_DT ,A.ORDER_QTY,P7.PARA7_NAME AS SKU,
	        c.BIN_ID  ,c.BIN_NAME ,c.STOCKQTY ,A.Ref_no as RefNo,A.SaleType
	 FROM #TMPORDPARA7 A
	 JOIN PARA7 P7 (NOLOCK) ON A.PARA7_CODE=P7.PARA7_CODE
	 join #tmpstock c on a.para7_code=c.para7_code
	 order by A.ORDER_DT,A.ORDER_NO,P7.PARA7_NAME ,c.BIN_NAME ,c.STOCKQTY 



END