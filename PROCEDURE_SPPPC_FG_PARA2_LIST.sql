CREATE PROCEDURE SPPPC_FG_PARA2_LIST  
(  
 @CARTICLE_CODE VARCHAR(10)='',  
 @CPARA1_CODE VARCHAR(10)='',  
 @CSIZEGROUP_CODE VARCHAR(10)='',  
 @CROW_ID VARCHAR(100)=''  
)  
AS  
BEGIN  
 SELECT ROW_NUMBER()OVER(ORDER BY A.ARTICLE_CODE) AS ROWNUMBER,A.ARTICLE_CODE,   
 CAST(CASE WHEN DET.PARA2_CODE IS NULL THEN 0 ELSE 1 END AS BIT) AS CHK,   
 CAST(CASE WHEN @CROW_ID='' THEN 'LATER' ELSE @CROW_ID END AS VARCHAR(40)) AS REF_ROW_ID,  
 C.PARA2_CODE,  
 P2.PARA2_NAME,  
 C.SIZEGROUP_CODE,  
 CAST(ISNULL(DET.ROW_ID,'LATER') AS VARCHAR(40)) AS ROW_ID,  
 CAST((ISNULL(DET.QUANTITY,0)- ISNULL(P5.QUANTITY,0)) AS NUMERIC(10,0)) AS QUANTITY 
 FROM ARTICLE A  
 LEFT JOIN ART_PARA1 B ON A.ARTICLE_CODE=B.ARTICLE_CODE  
 JOIN PPC_ART_DET_SIZEGROUP C ON A.ARTICLE_CODE=C.ARTICLE_CODE  
 JOIN PARA2 P2 ON P2.PARA2_CODE=C.PARA2_CODE 
 LEFT JOIN PPC_SIZEGROUP_PARA2 SP ON SP.SIZEGROUP_CODE=C.SIZEGROUP_CODE AND SP.PARA2_CODE=P2.PARA2_CODE
 LEFT OUTER JOIN
 PPC_BUYER_ORDER_SUB_DET  DET ON DET.REF_ROW_ID=@CROW_ID  AND DET.PARA2_CODE=C.PARA2_CODE
 LEFT OUTER JOIN 
 (
     SELECT COUNT(*) AS  QUANTITY,P2.BO_DET_ROW_ID,SKU.PARA2_CODE 
     FROM PPC_FGBCG_DET P2 
     JOIN PPC_FGBCG_MST  P3 ON P3.MEMO_ID =P2.MEMO_ID  
     JOIN PPC_FG_SKU SKU ON SKU.PPC_FGBCG_DET_ROW_ID =P2.ROW_ID 
     WHERE P3.CANCELLED =0
     GROUP BY P2.BO_DET_ROW_ID,SKU.PARA2_CODE 
 )P5 ON P5.BO_DET_ROW_ID=DET.REF_ROW_ID AND P5.PARA2_CODE=DET.PARA2_CODE

 WHERE A.ARTICLE_CODE = @CARTICLE_CODE  
 AND (@CPARA1_CODE='0000000' OR B.PARA1_CODE=@CPARA1_CODE)  
 AND C.SIZEGROUP_CODE=@CSIZEGROUP_CODE  
 ORDER BY ISNULL(SP.SR_NO,P2.PARA2_ORDER), [DBO].[FNMIXSORT](P2.PARA2_NAME)  
END
