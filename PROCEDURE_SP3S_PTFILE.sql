CREATE PROCEDURE SP3S_PTFILE  
(  
@CINV_ID VARCHAR(22)  
)  
AS  
BEGIN  
  
  
  SELECT '0000' +';'+ A.INV_NO+';'+'0000'+';'+ LM.ALIAS+';'+LM.AC_NAME+';'+'NA'+';'+CONVERT(VARCHAR(12),INV_DT,103)  
  +';'+'NA'+';'+CONVERT(VARCHAR(10),A.SUBTOTAL)+';'+CONVERT(VARCHAR(10),SUM(B.QUANTITY))   
  +';'+ CONVERT(VARCHAR(10),SUM(ITEM_TAX_AMOUNT))+';'+ '0' +';'+CONVERT(VARCHAR(10),A.DISCOUNT_AMOUNT)  
  +';'+ '0' +';'+CONVERT(VARCHAR(10),A.NET_AMOUNT)+';'+ ''+';'+'' +';'+''+';'+'' +';'+''+';'+  
  '' +';'+''+';'+''+';'+'1900/01/01'+';'+''+';'+''+';'+'NA'+';'+'0' +';'+''+';'+'NA'+';'+'NA'+';'+A.REMARKS   
  FROM INM01106 A  
  JOIN IND01106 B ON A.INV_ID=B.INV_ID   
  JOIN LOCATION L ON A.DEPT_ID=L.DEPT_ID  
  JOIN LM01106 LM ON LM.AC_CODE=L.DEPT_AC_CODE  
  WHERE A.INV_ID=''+ @CINV_ID +'' GROUP BY A.INV_NO,LM.ALIAS ,LM.AC_NAME,A.INV_DT,A.SUBTOTAL,A.DISCOUNT_AMOUNT,  
  A.NET_AMOUNT,A.REMARKS  
  
  
      UNION ALL  
  
  
  SELECT '0000'+';'+ A.INV_NO+';'+CONVERT(VARCHAR(10),B.AUTO_SRNO)+';'+LEFT(b.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX ('@',b.PRODUCT_CODE)-1,-1),LEN(b.PRODUCT_CODE )))+';'+  
   '0' +';'+SD.SUB_SECTION_NAME +';'+'NA'+';'+P4.PARA4_NAME+';'+'NA'+';'+AR.ARTICLE_NO+';'+  
    'NA'+';'+P1.PARA1_NAME +';'+'NA' +';'+  
    P2.PARA2_NAME +';'+ CONVERT(VARCHAR(10),B.QUANTITY)+';'+'0'+';'+'0'+';'+CONVERT(VARCHAR(10),B.MRP)  
    +';'+'NA' +';'+'0' +';'+'0'+';'+'NA'  
    +';'+'NA' +';'+(CASE WHEN A.BILL_LEVEL_TAX_METHOD= 1 THEN 'Y' ELSE 'N' END)  
   +';'+ 'NA' +';'+CONVERT(VARCHAR(10),B.NET_RATE)+';'+AR.ARTICLE_NAME+';'+'NA'+';'+'NA'+';'+'0'+';'+'0'  
    +';'+'NA'+';'+'0'+';'+'0'  
    +';'+'0'+';'+'NA'+';'+'NA'+';'+'0'+';'+'0'  
    +';'+'0'+';'+'0'+';'+'0'+';'+'NA'  
    +';'+'NA'  
    +';'+'NA'+';'+'NA'+';'++';'+'0'+';'+'NA'+';'+'NA'+';'+'NA'  
    +';'+SM.SECTION_NAME+';'+'NA'+';'+P3.PARA3_NAME+';'+'NA'+';'+'NA'+';'+  
    'NA'+';'+P5.PARA5_NAME+';'+'NA'+';'+  
    P6.PARA6_NAME+';'+'NA'+';'+  
    'NA'+';'+'NA'+';'+'0'+';'+  
    'NA'+';'+'NA'+';'+'NA'+';'+  
    'NA' FROM INM01106 A  
    JOIN IND01106 B ON A.INV_ID=B.INV_ID  
    JOIN SKU S ON S.PRODUCT_CODE=B.PRODUCT_CODE  
    JOIN ARTICLE AR ON AR.ARTICLE_CODE=S.ARTICLE_CODE  
    JOIN SECTIOND SD ON SD.SUB_SECTION_CODE=AR.SUB_SECTION_CODE  
    JOIN SECTIONM SM ON SM.SECTION_CODE=SD.SECTION_CODE  
    JOIN PARA1 P1 ON P1.PARA1_CODE=S.PARA1_CODE  
    JOIN PARA2 P2 ON P2.PARA2_CODE=S.PARA2_CODE  
    JOIN PARA3 P3 ON P3.PARA3_CODE=S.PARA3_CODE  
    JOIN PARA4 P4 ON P4.PARA4_CODE=S.PARA4_CODE  
    JOIN PARA5 P5 ON P5.PARA5_CODE=S.PARA5_CODE  
    JOIN PARA6 P6 ON P6.PARA6_CODE=S.PARA6_CODE  
    WHERE A.INV_ID=''+ @CINV_ID +''  
       
END
