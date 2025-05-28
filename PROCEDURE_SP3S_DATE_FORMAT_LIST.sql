CREATE PROCEDURE SP3S_DATE_FORMAT_LIST
AS
BEGIN
	SELECT '---SELECT---' AS [Date Format],'' AS [Date Value] ,CAST(0 AS int) AS SRNO
	UNION 
	SELECT 'dd-MM-yyyy ['+	 CONVERT(VARCHAR(20),getdate(), 105)+']' ,'dd-MM-yyyy' ,CAST(1 AS int) AS SRNO
	UNION 
	SELECT 'MM-dd-yyyy ['+	 CONVERT(VARCHAR(20),getdate(), 110)+  ']' ,'MM-dd-yyyy' ,CAST(2 AS int) AS SRNO
	UNION 
	SELECT 'dd MMM yyyy ['+	 CONVERT(VARCHAR(20),getdate(), 106)+  ']' ,'dd MMM yyyy' ,CAST(3 AS int) AS SRNO
	UNION 
	SELECT 'yyyy-MM-dd ['+	 CONVERT(VARCHAR(20),getdate(), 23)+ ']' ,'yyyy-MM-dd' ,CAST(4 AS int) AS SRNO
	UNION 
	SELECT 'MMM dd yyyy ['+	 CONVERT(VARCHAR(20),getdate(), 107)+ ']' ,'MMM dd yyyy ' ,CAST(5 AS int) AS SRNO
	UNION 
	SELECT 'dd-MM-yy ['+	 CONVERT(VARCHAR(20),getdate(), 105)+']' ,'dd-MM-yy' ,CAST(6 AS int) AS SRNO
	ORDER BY SRNO
END
