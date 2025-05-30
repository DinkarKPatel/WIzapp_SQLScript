CREATE PROCEDURE SP3S_SEARCH_MRN
@CFINYEAR	VARCHAR(10),
@CSEARCHTEXT	VARCHAR(MAX)
AS
BEGIN
	SELECT TOP 50 MRR_NO+'['+CONVERT(VARCHAR(20),INV_DT,105)+']' AS MRR_NO,MRR_ID,AC_NAME AS [SUPPLIER],B.ALIAS,D.AREA_NAME+'/'+E.CITY+'/'+F.STATE AS [ADDRESS]
	,INV_DT
	FROM PIM01106 A
	JOIN LM01106 B ON B.AC_CODE=A.AC_CODE
	JOIN LMP01106 C ON C.AC_CODE=B.AC_CODE
	JOIN AREA D ON D.AREA_CODE=C.AREA_CODE
	JOIN CITY E ON E.CITY_CODE=D.CITY_CODE
	JOIN STATE F ON F.STATE_CODE=E.STATE_CODE
	WHERE A.INV_MODE=1 AND A.FIN_YEAR=@CFINYEAR AND A.CANCELLED=0
	AND  MRR_NO LIKE @CSEARCHTEXT+'%'
	UNION 
	SELECT TOP 50 MRR_NO+'['+CONVERT(VARCHAR(20),INV_DT,105)+']' AS MRR_NO,MRR_ID,AC_NAME AS [SUPPLIER],B.ALIAS,D.AREA_NAME+'/'+E.CITY+'/'+F.STATE AS [ADDRESS]
	,INV_DT
	FROM PIM01106 A
	JOIN LM01106 B ON B.AC_CODE=A.AC_CODE
	JOIN LMP01106 C ON C.AC_CODE=B.AC_CODE
	JOIN AREA D ON D.AREA_CODE=C.AREA_CODE
	JOIN CITY E ON E.CITY_CODE=D.CITY_CODE
	JOIN STATE F ON F.STATE_CODE=E.STATE_CODE
	WHERE A.INV_MODE=1 AND A.FIN_YEAR=@CFINYEAR AND A.CANCELLED=0
	AND (AC_NAME LIKE @CSEARCHTEXT+'%'
	OR B.ALIAS LIKE @CSEARCHTEXT+'%'
	OR D.AREA_NAME LIKE @CSEARCHTEXT+'%'
	OR E.CITY LIKE @CSEARCHTEXT+'%'
	OR F.STATE LIKE @CSEARCHTEXT+'%')
	ORDER BY INV_DT,MRR_NO
END
