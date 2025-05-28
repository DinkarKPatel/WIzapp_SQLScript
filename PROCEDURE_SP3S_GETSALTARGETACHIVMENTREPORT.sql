CREATE PROCEDURE SP3S_GETSALTARGETACHIVMENTREPORT   
(  
 @Tiles VArchar (1000),  
 @cFrom VArchar (10),  
 @cTo VArchar (10)  
)  
AS  
BEGIN  
  
Declare @cCmd VARCHAR(MAX)  
DECLARE @Names VARCHAR(8000)   
  
SELECT @Names = COALESCE(@Names + ', ', '') + SLSTARGET_PARA_NAME   
FROM SLSTARGET_SETUP  A  
JOIN SLSTARGET_MST  B ON A.MEMO_ID= b.MEMO_ID    
WHERE MEMO_NAME = @Tiles   
  
Set @cCmd= ' Select   Dept_id,   ' + @Names + ',SUM(TARGET_QTY) AS [TARGET_QTY],SUM(TARGET_VALUE) AS [TARGET_VALUE] ,  
SUM(SALE_QTY) AS [SALE_QTY],SUM(SALE_VALUE) AS [SALE_VALUE], (SUM(SALE_QTY)- SUM(TARGET_QTY)) AS [SHORTFALL_QTY],  
(SUM(SALE_VALUE)- SUM(TARGET_VALUE)) AS [SHORTFALL_VALUE] ,   
((SUM(SALE_QTY)- SUM(TARGET_QTY)) / (CASE WHEN SUM(TARGET_QTY)=0 THEN 1 ELSE SUM(TARGET_QTY) END)) * 100 AS [QTY_VAR] ,  
((SUM(SALE_VALUE)- SUM(TARGET_VALUE)) / (CASE WHEN SUM(TARGET_VALUE)=0 THEN 1 ELSE SUM(TARGET_VALUE) END)) * 100 AS [VALUE_VAR]  
 FROM  
(   
Select loc.Dept_id,' + @Names + ',SUM(TARGET_QTY) AS TARGET_QTY,SUM(TARGET_VALUE) AS TARGET_VALUE ,  
CAST (0 AS NUMERIC(14,0)) AS SALE_QTY,CAST (0 AS NUMERIC(14,0)) AS SALE_VALUE  
FROM  SLSTARGET_DET  A (NOLOCK)  
JOIN  SLSTARGET_MST  B (NOLOCK) ON A.MEMO_ID= B.MEMO_ID  
LEFT OUTER JOIN SECTIONM  C (NOLOCK) ON A.SECTION_CODE= C.SECTION_CODE  
LEFT OUTER JOIN SECTIOND  D (NOLOCK) ON A.SUb_SECTION_CODE= D.SUB_SECTION_CODE  
LEFT OUTER JOIN ARTICLE  E  (NOLOCK)ON A.ARTICLE_CODE= E.ARTICLE_CODE  
LEFT OUTER JOIN PARA1  P1 (NOLOCK) ON A.PARA1_CODE= P1.PARA1_CODE  
LEFT OUTER JOIN PARA2  P2 (NOLOCK) ON A.PARA2_CODE= P2.PARA2_CODE  
LEFT OUTER JOIN PARA3  P3 (NOLOCK) ON A.PARA3_CODE= P3.PARA3_CODE  
LEFT OUTER JOIN PARA4  P4 (NOLOCK) ON A.PARA4_CODE= P4.PARA4_CODE  
LEFT OUTER JOIN PARA5  P5  (NOLOCK)ON A.PARA5_CODE= P5.PARA5_CODE  
LEFT OUTER JOIN PARA6  P6 (NOLOCK) ON A.PARA6_CODE= P6.PARA6_CODE  
LEFT OUTER JOIN EMPLOYEE  EMP (NOLOCK) ON A.EMP_CODE= EMP.EMP_CODE  
LEFT OUTER JOIN article_fix_attr ATTR  (NOLOCK) ON A.article_code = ATTR.ARTICLE_CODE   
LEFT OUTER JOIN attr1_mst at1 (NOLOCK) ON at1.attr1_key_code=A.attr1_key_code  
LEFT OUTER JOIN attr2_mst at2 (NOLOCK) ON at2.attr2_key_code=A.attr2_key_code  
LEFT OUTER JOIN attr3_mst at3 (NOLOCK) ON at3.attr3_key_code=A.attr3_key_code  
LEFT OUTER JOIN attr4_mst at4 (NOLOCK) ON at4.attr4_key_code=A.attr4_key_code  
LEFT OUTER JOIN attr5_mst at5 (NOLOCK) ON at5.attr5_key_code=A.attr5_key_code  
LEFT OUTER JOIN attr6_mst at6 (NOLOCK) ON at6.attr6_key_code=A.attr6_key_code  
LEFT OUTER JOIN attr7_mst at7 (NOLOCK) ON at7.attr7_key_code=A.attr7_key_code  
LEFT OUTER JOIN attr8_mst at8 (NOLOCK) ON at8.attr8_key_code=A.attr8_key_code  
LEFT OUTER JOIN attr9_mst at9 (NOLOCK) ON at9.attr9_key_code=A.attr9_key_code  
LEFT OUTER JOIN attr10_mst at10 (NOLOCK) ON at10.attr10_key_code=A.attr10_key_code  
LEFT OUTER JOIN attr11_mst at11 (NOLOCK) ON at11.attr11_key_code=A.attr11_key_code  
LEFT OUTER JOIN attr12_mst at12 (NOLOCK) ON at12.attr12_key_code=A.attr12_key_code  
LEFT OUTER JOIN attr13_mst at13 (NOLOCK) ON at13.attr13_key_code=A.attr13_key_code  
LEFT OUTER JOIN attr14_mst at14 (NOLOCK) ON at14.attr14_key_code=A.attr14_key_code  
LEFT OUTER JOIN attr15_mst at15 (NOLOCK) ON at15.attr15_key_code=A.attr15_key_code  
LEFT OUTER JOIN attr16_mst at16 (NOLOCK) ON at16.attr16_key_code=A.attr16_key_code  
LEFT OUTER JOIN attr17_mst at17 (NOLOCK) ON at17.attr17_key_code=A.attr17_key_code  
LEFT OUTER JOIN attr18_mst at18 (NOLOCK) ON at18.attr18_key_code=A.attr18_key_code  
LEFT OUTER JOIN attr19_mst at19 (NOLOCK) ON at19.attr19_key_code=A.attr19_key_code  
LEFT OUTER JOIN attr20_mst at20 (NOLOCK) ON at20.attr20_key_code=A.attr20_key_code  
LEFT OUTER JOIN attr21_mst at21 (NOLOCK) ON at21.attr21_key_code=A.attr21_key_code  
LEFT OUTER JOIN attr22_mst at22 (NOLOCK) ON at22.attr22_key_code=A.attr22_key_code  
LEFT OUTER JOIN attr23_mst at23 (NOLOCK) ON at23.attr23_key_code=A.attr23_key_code  
LEFT OUTER JOIN attr24_mst at24 (NOLOCK) ON at24.attr24_key_code=A.attr24_key_code  
LEFT OUTER JOIN attr25_mst at25(NOLOCK) ON at25.attr25_key_code=A.attr25_key_code  
LEFT OUTER JOIN Location lOC(NOLOCK) ON a.DEPT_ID= LOC.DEPT_ID  
WHERE B.MEMO_NAME= '''+@Tiles+'''   
and  TARGET_DT BETWEEN ''' +@cFrom + ''' and '''+@cTo +'''  
group by  loc.Dept_id, ' + @Names + '    
UNION ALL   
  
Select loc.Dept_id, ' + @Names + ',CAST (0 AS NUMERIC(14,0)) AS TARGET_QTY,CAST (0 AS NUMERIC(14,0)) AS TARGET_VALUE ,  
SUM (QUANTITY)AS SALE_QTY,SUM(rfnet) AS SALE_VALUE  
FROM  CMD01106  A (NOLOCK)  
JOIN  CMM01106  B (NOLOCK)  ON A.CM_ID= B.CM_ID  
JOIN SKU S  (NOLOCK) ON A.PRODUCT_CODE= S.PRODUCT_CODE  
JOIN ARTICLE E (NOLOCK) ON S.ARTICLE_CODE= E.ARTICLE_CODE  
LEFT OUTER JOIN SECTIOND  D  (NOLOCK) ON E.SUb_SECTION_CODE= D.SUB_SECTION_CODE  
LEFT OUTER JOIN SECTIONM  C  (NOLOCK) ON D.SECTION_CODE= C.SECTION_CODE  
LEFT OUTER JOIN PARA1  P1 (NOLOCK) ON S.PARA1_CODE= P1.PARA1_CODE  
LEFT OUTER JOIN PARA2  P2 (NOLOCK) ON S.PARA2_CODE= P2.PARA2_CODE  
LEFT OUTER JOIN PARA3  P3 (NOLOCK) ON S.PARA3_CODE= P3.PARA3_CODE  
LEFT OUTER JOIN PARA4  P4 (NOLOCK) ON S.PARA4_CODE= P4.PARA4_CODE  
LEFT OUTER JOIN PARA5  P5 (NOLOCK) ON S.PARA5_CODE= P5.PARA5_CODE  
LEFT OUTER JOIN PARA6  P6 (NOLOCK) ON S.PARA6_CODE= P6.PARA6_CODE  
LEFT OUTER JOIN EMPLOYEE  EMP (NOLOCK) ON A.EMP_CODE= EMP.EMP_CODE  
LEFT OUTER JOIN article_fix_attr ATTR  (NOLOCK) ON E.article_code = ATTR.ARTICLE_CODE   
LEFT OUTER JOIN attr1_mst at1 (NOLOCK) ON at1.attr1_key_code=ATTR.attr1_key_code  
LEFT OUTER JOIN attr2_mst at2 (NOLOCK) ON at2.attr2_key_code=ATTR.attr2_key_code  
LEFT OUTER JOIN attr3_mst at3 (NOLOCK) ON at3.attr3_key_code=ATTR.attr3_key_code  
LEFT OUTER JOIN attr4_mst at4 (NOLOCK) ON at4.attr4_key_code=ATTR.attr4_key_code  
LEFT OUTER JOIN attr5_mst at5 (NOLOCK) ON at5.attr5_key_code=ATTR.attr5_key_code  
LEFT OUTER JOIN attr6_mst at6 (NOLOCK) ON at6.attr6_key_code=ATTR.attr6_key_code  
LEFT OUTER JOIN attr7_mst at7 (NOLOCK) ON at7.attr7_key_code=ATTR.attr7_key_code  
LEFT OUTER JOIN attr8_mst at8 (NOLOCK) ON at8.attr8_key_code=ATTR.attr8_key_code  
LEFT OUTER JOIN attr9_mst at9 (NOLOCK) ON at9.attr9_key_code=ATTR.attr9_key_code  
LEFT OUTER JOIN attr10_mst at10 (NOLOCK) ON at10.attr10_key_code=ATTR.attr10_key_code  
LEFT OUTER JOIN attr11_mst at11 (NOLOCK) ON at11.attr11_key_code=ATTR.attr11_key_code  
LEFT OUTER JOIN attr12_mst at12 (NOLOCK) ON at12.attr12_key_code=ATTR.attr12_key_code  
LEFT OUTER JOIN attr13_mst at13 (NOLOCK) ON at13.attr13_key_code=ATTR.attr13_key_code  
LEFT OUTER JOIN attr14_mst at14 (NOLOCK) ON at14.attr14_key_code=ATTR.attr14_key_code  
LEFT OUTER JOIN attr15_mst at15 (NOLOCK) ON at15.attr15_key_code=ATTR.attr15_key_code  
LEFT OUTER JOIN attr16_mst at16 (NOLOCK) ON at16.attr16_key_code=ATTR.attr16_key_code  
LEFT OUTER JOIN attr17_mst at17 (NOLOCK) ON at17.attr17_key_code=ATTR.attr17_key_code  
LEFT OUTER JOIN attr18_mst at18 (NOLOCK) ON at18.attr18_key_code=ATTR.attr18_key_code  
LEFT OUTER JOIN attr19_mst at19 (NOLOCK) ON at19.attr19_key_code=ATTR.attr19_key_code  
LEFT OUTER JOIN attr20_mst at20 (NOLOCK) ON at20.attr20_key_code=ATTR.attr20_key_code  
LEFT OUTER JOIN attr21_mst at21 (NOLOCK) ON at21.attr21_key_code=ATTR.attr21_key_code  
LEFT OUTER JOIN attr22_mst at22 (NOLOCK) ON at22.attr22_key_code=ATTR.attr22_key_code  
LEFT OUTER JOIN attr23_mst at23 (NOLOCK) ON at23.attr23_key_code=ATTR.attr23_key_code  
LEFT OUTER JOIN attr24_mst at24 (NOLOCK) ON at24.attr24_key_code=ATTR.attr24_key_code  
LEFT OUTER JOIN attr25_mst at25(NOLOCK) ON at25.attr25_key_code=ATTR.attr25_key_code  
LEFT OUTER JOIN locATION lOC(NOLOCK) ON LEFT(B.CM_ID,2)= LOC.DEPT_ID  
  
  
WHERE   B.CANCELLED=0 AND B.CM_DT BETWEEN ''' +@cFrom + ''' and '''+@cTo +'''  
 group by loc.Dept_id,  ' + @Names + '  
  
) A  group by  Dept_id,' + @Names + '  HAVING (SUM(TARGET_QTY) +SUM(TARGET_VALUE)) <>0    ORDER BY  Dept_id,' + @Names + '  
'  
--  
Print @cCmd  
  
Exec (@cCmd )  
  
END  
  
  
  