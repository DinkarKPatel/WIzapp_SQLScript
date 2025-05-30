CREATE VIEW VW_PPC_TTM_PRINT
AS
SELECT CAST(1 AS BIT) AS CHK,  
       IM.MEMO_ID AS MEMO_ID,  
       IM.MEMO_NO,  
       CONVERT(VARCHAR,IM.MEMO_DT,105) AS MEMO_DT,  
       ROW_ID=ID.ROW_ID,  
       A.AC_CODE,LM.AC_NAME ,  
       BO.BILL_NO,  
       B.ARTICLE_CODE,ART.ARTICLE_NO,ART.ARTICLE_NAME,  
       B.SIZEGROUP_CODE,SG.SIZEGROUP_NAME ,  
       B.PARA1_CODE,P1.PARA1_NAME AS COLOR,  
       B.PARA3_CODE,P3.PARA3_NAME BUYER_STYLE_NO,  
       SKU.PARA2_CODE,P2.PARA2_NAME SIZE, 
       ID.PRODUCT_CODE,  
       ID.QUANTITY,  
       PMT.QUANTITY_IN_STOCK,  
       ID.PURCHASE_PRICE AS  RATE,  
       ID.AMOUNT
      
    FROM PPC_FGBCG_MST A  
    JOIN PPC_FGBCG_DET B ON A.MEMO_ID =B.MEMO_ID   
    JOIN PPC_FG_SKU SKU ON SKU.PPC_FGBCG_DET_ROW_ID=B.ROW_ID   
    JOIN PPC_FG_PMT PMT ON SKU.PRODUCT_CODE=PMT.PRODUCT_CODE   
    JOIN ARTICLE ART ON ART.ARTICLE_CODE =SKU.ARTICLE_CODE   
    JOIN PARA1 P1 ON P1.PARA1_CODE =SKU.PARA1_CODE   
    JOIN PARA2 P2 ON P2.PARA2_CODE =SKU.PARA2_CODE   
    JOIN PARA3 P3 ON P3.PARA3_CODE =SKU.PARA3_CODE   
    JOIN PPC_SIZEGROUP SG ON SG.SIZEGROUP_CODE =SKU.SIZEGROUP_CODE   
    JOIN LM01106 LM ON LM.AC_CODE =A.AC_CODE   
    JOIN PPC_TRANSFER_TO_TRADING_DET ID ON ID.PRODUCT_CODE=SKU.PRODUCT_CODE  
    JOIN PPC_TRANSFER_TO_TRADING_MST  IM ON ID.MEMO_ID=IM.MEMO_ID  
    JOIN
    (
     SELECT ROW_ID ,BILL_NO 
     FROM PPC_BUYER_ORDER_DET A
     JOIN PPC_BUYER_ORDER_MST B ON A.ORDER_ID =B.ORDER_ID 
     WHERE B.CANCELLED =0
     GROUP BY ROW_ID ,BILL_NO
    
    ) BO ON BO.ROW_ID =B.BO_DET_ROW_ID
