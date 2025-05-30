CREATE PROCEDURE SP3S_GET_UNIQUE_GST(@FROM DATE,@TO DATE)
AS
BEGIN
SELECT DISTINCT CAST(0 AS BIT)CHK,D.GST_PERCENTAGE
FROM CMM01106 M (NOLOCK) JOIN CMD01106 D (NOLOCK) ON M.CM_ID=D.CM_ID
WHERE M.CANCELLED=0 AND M.CM_DT BETWEEN @FROM AND @TO
AND ISNULL(D.GST_PERCENTAGE,0)<>0
END