create PROCEDURE SP3S_WSL_ORDER_PENDING_LIST
(
 @CDEPT_ID VARCHAR(2)=''
)
AS
BEGIN
--this procedure shows Pending order for invoice
     IF ISNULL(@CDEPT_ID,'')=''
	 SELECT @CDEPT_ID=DEPT_ID FROM NEW_APP_LOGIN_INFO (nolock) WHERE SPID=@@SPID 
    ;with cte_order as
    (
    select a.RefMemoId ,
           b.ORDER_ID, b.ORDER_NO,
	       b.ORDER_DT AS ORDER_DT,
	       b.REF_NO,
		   DELIVERY_DT,
		   c.AC_NAME AS RECEIVER_NAME,
		   DATEDIFF(DD,b.DELIVERY_DT,GETDATE ()) AS AGEING    ,
           sum(case when a.XnType ='Order' then Qty else -1*Qty end) as Pending_QTY
    from SalesOrderProcessing A
    join BUYER_ORDER_MST b (nolock) on a.RefMemoId =b.order_id 
    JOIN LM01106 c (NOLOCK) ON c.AC_CODE =B.AC_CODE
    WHERE b.CANCELLED=0 AND ISNULL(b.Short_close,0)=0
    and XNTYPE IN('ORDER','ORDERPACKSLIP','ORDERINVOICE')
	AND b.WBO_FOR_DEPT_ID=@CDEPT_ID
    group by a.RefMemoId ,b.ORDER_ID, b.ORDER_NO,
	       b.ORDER_DT ,b.REF_NO,DELIVERY_DT,
		   c.AC_NAME , DATEDIFF(DD,b.DELIVERY_DT,GETDATE ()) 
    having sum(case when a.XnType ='Order' then Qty else -1*Qty end)<>0
     
    ),
     Cte_plpackslip as
    (
	    
	SELECT B.ORDER_ID ,SUM(A.QTY) AS PLPACKSLIPQTY 
	FROM SALESORDERPROCESSING A (NOLOCK)
	JOIN PLM01106 B  (NOLOCK) ON A.REFMEMOID =B.MEMO_ID 
	WHERE XNTYPE='PLPACKSLIP' AND B.CANCELLED =0 --and 1=2
	and b.location_code =@CDEPT_ID
	GROUP BY B.ORDER_ID
    
    )
    
	
--sum(OrderQty-(orderPackSlipQty+orderInvoiceQty+plPackSlipQty+orderShortCloseQty))
    SELECT A.ORDER_ID, A.ORDER_NO,
	       A.ORDER_DT AS ORDER_DT,
	       A.REF_NO,
		   DELIVERY_DT,
		   a.RECEIVER_NAME,
		   a.PENDING_QTY-ISNULL(PLPACKSLIPQTY,0) as PENDING_QTY,
		   a.AGEING    ,
		   ISNULL(PLPACKSLIPQTY,0)
	FROM cte_order A (NOLOCK)
	left join Cte_plpackslip b on a.RefMemoId =b.order_id 
	where a.PENDING_QTY-ISNULL(PLPACKSLIPQTY,0)<>0
	-- and  a.ORDER_ID ='01250000000001kv000013'
	ORDER BY A.ORDER_DT ,A.ORDER_NO
	
END