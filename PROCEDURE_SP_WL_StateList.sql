

-- GET ALL DEFINED CUSTOMER MASTER
CREATE PROCEDURE SP_WL_STATELIST
--WITH ENCRYPTION
AS

	SELECT A.STATE_CODE , A.STATE ,B.REGION_CODE ,B.REGION_NAME  
	FROM STATE  AS A  
	JOIN REGIONM AS B ON A.REGION_CODE = B.REGION_CODE 
	--WHERE STATE_CODE<>'0000000'
	ORDER BY B.REGION_NAME ,A.STATE 
