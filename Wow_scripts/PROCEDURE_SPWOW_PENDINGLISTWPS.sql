CREATE PROCEDURE SPWOW_PENDINGLISTWPS
(
@NQUERYID int,
@cWhere VArchar(100)
)
As Begin

IF @NQUERYID=1 
GOTO PARTYBO
ELSE IF @NQUERYID=2 
GOTO BRANCHBO
ELSE IF @NQUERYID=3 
GOTO PARTYPL
ELSE IF @NQUERYID=4 
GOTO BRANCHPL


PARTYBO:

SELECT A.ORDER_ID as orderId,A.ORDER_NO as OrderNo,convert(varchar,A.ORDER_DT,106) as OrderDate,A.REF_NO as refNo,
B1.Orderqty,B1. ReceivedQty  ,(B1.Orderqty-B1.ReceivedQty ) as PendingQty
FROM BUYER_ORDER_MST A (NOLOCK)    
JOIN     
(    
SELECT B.ORDER_ID,    
SUM(Quantity) as Orderqty ,  
SUM(ISNULL(B.INV_QTY,0)) AS ReceivedQty  
FROM    
BUYER_ORDER_DET B (NOLOCK)   
JOIN  buyer_order_mst c (NOLOCK) ON b.order_id=c.order_id  
WHERE c.AC_CODE = @cWhere  
GROUP BY B.ORDER_ID    
)B1 ON B1.ORDER_ID =A.ORDER_ID    
WHERE  A.CANCELLED = 0   AND A.inv_mode =1
AND A.AC_CODE =@cWhere  
AND ( A.ApprovedLevelNo =99)  
AND B1.Orderqty > ISNULL(B1.ReceivedQty,0)  and ISNULL(A.Short_close,0)  <> 1    
ORDER BY A.ORDER_DT,A.ORDER_ID    


GOTO LAST


BRANCHBO:

  
SELECT A.ORDER_ID as orderId,A.ORDER_NO as OrderNo,convert(varchar,A.ORDER_DT,106) as OrderDate,A.REF_NO as refNo,
B1.Orderqty,B1. ReceivedQty  ,(B1.Orderqty-B1.ReceivedQty ) as PendingQty
FROM BUYER_ORDER_MST A (NOLOCK)    
JOIN     
(    
SELECT B.ORDER_ID,    
SUM(Quantity) as Orderqty ,  
SUM(ISNULL(B.INV_QTY,0)) AS ReceivedQty  
FROM    
BUYER_ORDER_DET B (NOLOCK)   
JOIN  buyer_order_mst c (NOLOCK) ON b.order_id=c.order_id  
WHERE c.WBO_FOR_DEPT_ID =@cWhere 
GROUP BY B.ORDER_ID    
)B1 ON B1.ORDER_ID =A.ORDER_ID    
WHERE  A.CANCELLED = 0        AND A.inv_mode =2
AND A.WBO_FOR_DEPT_ID =@cWhere   
AND ( A.ApprovedLevelNo =99)  
AND B1.Orderqty > ISNULL(B1.ReceivedQty,0)  and ISNULL(A.Short_close,0)  <> 1    
ORDER BY A.ORDER_DT,A.ORDER_ID    




PARTYPL:


 SELECT DISTINCT A.MEMO_ID AS orderId,A.MEMO_NO AS OrderNo,    
 convert(varchar,A.Memo_dt,106) as OrderDate,'' AS REF_NO,    
 TOTAL_QUANTITY as Orderqty, INVOICE_QTY AS ReceivedQty,(TOTAL_QUANTITY-INVOICE_QTY) AS PendingQty    
 FROM PLM01106 A (NOLOCK)    
 JOIN     
 (    
  SELECT B.MEMO_ID ,Short_close,SUM(B.QUANTITY) AS TOTAL_QUANTITY     
  FROM PLD01106 B (NOLOCK)      
  JOIN BUYER_ORDER_DET B11 (NOLOCK) ON B11.ROW_ID=B.ORD_ROW_ID    
  JOIN BUYER_ORDER_MST B2 (NOLOCK) ON B2.ORDER_ID=B11.ORDER_ID AND B2.AC_CODE=@cWhere    
  WHERE B2.INV_MODE=1
  GROUP BY B.MEMO_ID,Short_close    
 )B1 ON B1.MEMO_ID =A.MEMO_ID     
 LEFT OUTER JOIN    
 (    
  SELECT B.ORDER_ID AS ORDER_ID,SUM(B.QUANTITY) AS INVOICE_QTY     
  FROM WPS_DET B     
  JOIN WPS_MST C ON B.PS_ID = C.PS_ID    
  WHERE C.CANCELLED=0  AND ISNULL(B.ORDER_ID,'')<>''     
  AND ISNULL(B.PICK_LIST_ROW_ID,'')<>''     
  AND C.AC_CODE=@cWhere       AND  ps_mode=1
  GROUP BY B.ORDER_ID    
 )C ON  A.MEMO_ID = C.ORDER_ID    
 WHERE (A.CANCELLED = 0     
 AND B1.TOTAL_QUANTITY - ISNULL(C.INVOICE_QTY,0) >0)   
 and ISNULL(B1.Short_close,0)  =0 and  ISNULL(a.Short_close,0)  =0    
 ORDER BY  convert(varchar,A.Memo_dt,106),  orderId

 

GOTO LAST


BRANCHPL:

 
 SELECT DISTINCT A.MEMO_ID AS orderId,A.MEMO_NO AS OrderNo,    
 convert(varchar,A.Memo_dt,106) as OrderDate,'' AS REF_NO,    
 TOTAL_QUANTITY as Orderqty, INVOICE_QTY AS ReceivedQty,(TOTAL_QUANTITY-INVOICE_QTY) AS PendingQty    
 FROM PLM01106 A (NOLOCK)    
 JOIN     
 (    
  SELECT B.MEMO_ID ,Short_close,SUM(B.QUANTITY) AS TOTAL_QUANTITY     
  FROM PLD01106 B (NOLOCK)      
  JOIN BUYER_ORDER_DET B11 (NOLOCK) ON B11.ROW_ID=B.ORD_ROW_ID    
  JOIN BUYER_ORDER_MST B2 (NOLOCK) ON B2.ORDER_ID=B11.ORDER_ID AND B2.WBO_FOR_DEPT_ID=@cWhere    
  WHERE B2.INV_MODE=2
  GROUP BY B.MEMO_ID,Short_close    
 )B1 ON B1.MEMO_ID =A.MEMO_ID     
 LEFT OUTER JOIN    
 (    
  SELECT B.ORDER_ID AS ORDER_ID,SUM(B.QUANTITY) AS INVOICE_QTY     
  FROM WPS_DET B     
  JOIN WPS_MST C ON B.PS_ID = C.PS_ID    
  WHERE C.CANCELLED=0  AND ISNULL(B.ORDER_ID,'')<>''     
  AND ISNULL(B.PICK_LIST_ROW_ID,'')<>''     
  AND C.party_dept_id=@cWhere        AND  ps_mode=2
  GROUP BY B.ORDER_ID    
 )C ON  A.MEMO_ID = C.ORDER_ID    
 WHERE (A.CANCELLED = 0     
 AND B1.TOTAL_QUANTITY - ISNULL(C.INVOICE_QTY,0) >0)   
 and ISNULL(B1.Short_close,0)  =0 and  ISNULL(a.Short_close,0)  =0    
 ORDER BY  convert(varchar,A.Memo_dt,106),  orderId




LAST:	

END