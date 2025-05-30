CREATE VIEW VW_BUYER_ORDER_ALLOCATE  
AS
     
     SELECT A.MEMO_ID,A.MEMO_NO,A.MEMO_DT AS MEMO_DATE,
            ART.ARTICLE_NO ,ART.ARTICLE_NAME,
            P1.PARA1_NAME ,P2.PARA2_NAME ,
            A.CANCELLED,B.INHOUSE_ORDER_ID,B.QUANTITY AS INHOUSE_QTY,C.BUYER_ORDER_ID,
            LM.AC_NAME ,C.QUANTITY AS ALLOCATE_QTY,A.FIN_YEAR
            --,D.PRODUCT_CODE,D.QUANTITY AS WIP_QTY
     FROM BUYER_ORDER_ALLOCATE_MST A
	 JOIN BUYER_ORDER_ALLOCATE_DET B ON A.MEMO_ID =B.MEMO_ID 
	 JOIN BUYER_ORDER_ALLOCATE_SUB_DET C ON B.ROW_ID=C.REF_ROW_ID 
	 JOIN ARTICLE ART ON ART.ARTICLE_CODE =A.ARTICLE_CODE 
	 JOIN PARA1 P1 ON P1.PARA1_CODE =A.PARA1_CODE
	 JOIN PARA2 P2 ON P2.PARA2_CODE =A.PARA2_CODE
	 JOIN LM01106 LM ON LM.AC_CODE=C.AC_CODE
