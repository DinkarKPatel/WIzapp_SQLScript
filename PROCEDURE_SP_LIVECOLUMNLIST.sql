CREATE PROC SP_LIVECOLUMNLIST
AS
BEGIN


DECLARE @CPARA1 VARCHAR(50),@CPARA2 VARCHAR(50),@CPARA3 VARCHAR(50),@CPARA4 VARCHAR(50),
@CPARA5 VARCHAR(50),@CPARA6 VARCHAR(50)

SELECT @CPARA1= VALUE FROM CONFIG WHERE  CONFIG_OPTION= 'PARA1_caption'
SELECT @CPARA2= VALUE FROM CONFIG WHERE CONFIG_OPTION= 'PARA2_caption'
SELECT @CPARA3= VALUE FROM CONFIG WHERE CONFIG_OPTION= 'PARA3_caption'
SELECT @CPARA4= VALUE FROM CONFIG WHERE CONFIG_OPTION= 'PARA4_caption'
SELECT @CPARA5= VALUE FROM CONFIG WHERE CONFIG_OPTION= 'PARA5_caption'
SELECT @CPARA6= VALUE FROM CONFIG WHERE CONFIG_OPTION= 'PARA6_caption
'


SELECT CAST((CASE WHEN ISNULL(B.CALL_EXP,'')= '' THEN 0 ELSE 1 END) AS BIT) AS CHK,A.CALL_HEADER,A.CALL_EXP,
      A.TABLENAME,ISNULL(B.SHOW_ORDER,A.SHOW_ORDER ) AS SHOW_ORDER 
FROM 
(

SELECT    'SECTION NAME' AS CALL_HEADER,'SECTION_NAME' AS CALL_EXP, 'sku_names' AS TABLENAME ,1 AS SHOW_ORDER
UNION ALL
SELECT 'SUB SECTION NAME' AS CALL_HEADER,'SUB_SECTION_NAME' AS CALL_EXP, 'sku_names' AS TABLENAME ,2 AS SHOW_ORDER
UNION ALL
SELECT 'ARTICLE NO.' AS CALL_HEADER,'ARTICLE_NO' AS CALL_EXP, 'sku_names' AS TABLENAME ,3 AS SHOW_ORDER
UNION ALL
SELECT 'ITEM CODE' AS CALL_HEADER,'PRODUCT_CODE' AS CALL_EXP, 'sku_names' AS TABLENAME ,4 AS SHOW_ORDER
UNION ALL
SELECT 'UOM' AS CALL_HEADER,'uom' AS CALL_EXP, 'sku_names' AS TABLENAME ,5 AS SHOW_ORDER
UNION ALL
SELECT @CPARA1 AS CALL_HEADER,'PARA1_NAME' AS CALL_EXP, 'sku_names' AS TABLENAME ,6 AS SHOW_ORDER
UNION ALL 
SELECT @CPARA2 AS CALL_HEADER,'PARA2_NAME' AS CALL_EXP, 'sku_names' AS TABLENAME ,7 AS SHOW_ORDER
UNION ALL 
SELECT @CPARA3 AS CALL_HEADER,'PARA3_NAME' AS CALL_EXP, 'sku_names' AS TABLENAME ,8 AS SHOW_ORDER
UNION ALL 
SELECT @CPARA4 AS CALL_HEADER,'PARA4_NAME' AS CALL_EXP, 'sku_names' AS TABLENAME ,9 AS SHOW_ORDER
UNION ALL 
SELECT  @CPARA5 AS CALL_HEADER,'PARA5_NAME' AS CALL_EXP, 'sku_names' AS TABLENAME ,10 AS SHOW_ORDER
UNION ALL 
SELECT @CPARA6 AS CALL_HEADER,'PARA6_NAME' AS CALL_EXP, 'sku_names' AS TABLENAME ,11 AS SHOW_ORDER
UNION ALL 
SELECT 'MRP' AS CALL_HEADER,'MRP' AS CALL_EXP, 'sku_names' AS TABLENAME ,12 AS SHOW_ORDER
UNION ALL
SELECT 'BIN ID' AS CALL_HEADER,'BIN_ID' AS CALL_EXP, 'BIN' AS TABLENAME ,13 AS SHOW_ORDER
UNION ALL 
SELECT 'BIN NAME' AS CALL_HEADER,'BIN_NAME' AS CALL_EXP, 'BIN' AS TABLENAME ,14 AS SHOW_ORDER
UNION ALL 
SELECT 'LOCATION ID' AS CALL_HEADER,'DEPT_ID' AS CALL_EXP, 'LOC_VIEW' AS TABLENAME ,15 AS SHOW_ORDER
UNION ALL
SELECT 'LOCATION NAME' AS CALL_HEADER,'DEPT_NAME' AS CALL_EXP, 'LOC_VIEW' AS TABLENAME ,16 AS SHOW_ORDER
UNION ALL 
SELECT 'LOCATION AREA' AS CALL_HEADER,'AREA_NAME' AS CALL_EXP, 'LOC_VIEW' AS TABLENAME ,17 AS SHOW_ORDER
UNION ALL   
SELECT 'CBS_QTY' AS CALL_HEADER,'CBS' AS CALL_EXP, '' AS TABLENAME ,18 AS SHOW_ORDER
) A
LEFT OUTER JOIN LIVE_REPORT B ON A.CALL_EXP = B.CALL_EXP 

END
