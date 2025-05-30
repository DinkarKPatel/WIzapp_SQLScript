CREATE PROCEDURE SP3S_CONFIG_BUYERORDER
AS
BEGIN
    

	        DECLARE @CPARA1NAME VARCHAR(5),@CPARA2NAME VARCHAR(5),@CPARA3NAME VARCHAR(5)
		   ,@CPARA4NAME VARCHAR(5),@CPARA5NAME VARCHAR(5),@CPARA6NAME VARCHAR(5)

	        			 
			SELECT A.SR_NO,A.COLUMN_NAME,
			CASE WHEN A.COLUMN_NAME=C.COLUMN_NAME THEN C.VALUE ELSE   A.COLUMN_CAPTION END AS COLUMN_CAPTION
			,A.OPEN_KEY 
			FROM CONFIG_BUYERORDER A			
			LEFT JOIN
			(
			SELECT TOP 1 VALUE,'PARA1_NAME' AS COLUMN_NAME FROM CONFIG WHERE CONFIG_OPTION='PARA1_caption' UNION ALL
			SELECT TOP 1 VALUE,'PARA2_NAME' AS COLUMN_NAME FROM CONFIG WHERE CONFIG_OPTION='PARA2_caption' UNION ALL
			SELECT TOP 1 VALUE,'PARA3_NAME' AS COLUMN_NAME FROM CONFIG WHERE CONFIG_OPTION='PARA3_caption' UNION ALL
			SELECT TOP 1 VALUE,'PARA4_NAME' AS COLUMN_NAME FROM CONFIG WHERE CONFIG_OPTION='PARA4_caption' UNION ALL
			SELECT TOP 1 VALUE,'PARA5_NAME' AS COLUMN_NAME FROM CONFIG WHERE CONFIG_OPTION='PARA5_caption' UNION ALL
			SELECT TOP 1 VALUE,'PARA6_NAME' AS COLUMN_NAME FROM CONFIG WHERE CONFIG_OPTION='PARA6_caption' 

			) C ON A.COLUMN_NAME=C.COLUMN_NAME
			 WHERE A.COLUMN_NAME NOT LIKE 'ATTR%'  
			 AND A.COLUMN_NAME NOT IN ('SECTION_NAME','SUB_SECTION_NAME') ORDER BY  SR_NO
		

END
