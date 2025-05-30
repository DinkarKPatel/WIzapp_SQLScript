CREATE PROCEDURE SP_CRT_LOC_ATTR_VALUE
AS
BEGIN
	DECLARE @CATTRIBUTECODE VARCHAR(7), @CATTRIBUTENAME VARCHAR(50), 
			@NCTR NUMERIC(2), @CALIASC VARCHAR(10), @CALIASD VARCHAR(10),
			@CATTRCOLNAME VARCHAR(MAX), @CATTRJOINSTR VARCHAR(MAX), 
			@CATTRJOINSTRGRP VARCHAR(MAX), @CCMD NVARCHAR(MAX), 
			@CCMD1 NVARCHAR(MAX), @CCMD2 NVARCHAR(MAX), @CCREATEALTER VARCHAR(10),
			@CCMDCRTCUSTVIEW NVARCHAR(MAX), @CCMDCRTCUSTATTRVALUE NVARCHAR(MAX)

	DECLARE ABC CURSOR FOR
	SELECT ATTRIBUTE_CODE, ATTRIBUTE_NAME FROM ATTRM WHERE ATTRIBUTE_TYPE = 4

	SET @NCTR = 1
	SET @CCMD = N''
	SET @CCMD1= N''
	SET @CCMD2= N''

	OPEN ABC
	FETCH NEXT FROM ABC INTO @CATTRIBUTECODE, @CATTRIBUTENAME
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @CALIASC	= 'C' + CONVERT(VARCHAR(2), @NCTR)
		SET @CALIASD	= 'D' + CONVERT(VARCHAR(2), @NCTR)
		
		SET @CCMD = @CCMD + 
					(CASE WHEN @CCMD<>'' THEN ' '+CHAR(13) ELSE '' END) +
					N'[ DBO.FN_ATTR_NAME(''' + @CATTRIBUTECODE + ''', A.DEPT_ID, 4 ) AS '+@CATTRIBUTENAME+'], '

		SET @CCMD1 = @CCMD1 + 
					(CASE WHEN @CCMD1<>'' THEN ' '+CHAR(13) ELSE '' END) +
				    N' (CASE WHEN '+@CALIASC + '.ATTRIBUTE_CODE = ''' + @CATTRIBUTECODE + 
				    ''' THEN ISNULL(' + @CALIASD + '.KEY_NAME,'''') ELSE '''' END ) AS ['+ UPPER(@CATTRIBUTENAME) + '], '

		SET @CCMD2 = @CCMD2 + 
					(CASE WHEN @CCMD2<>'' THEN ' '+CHAR(13) ELSE '' END) +
				   N' LEFT OUTER JOIN LOC_ATTR ' + @CALIASC + ' ON A.DEPT_ID = ' + @CALIASC + 
				   '.DEPT_ID AND ' + @CALIASC + '.ATTRIBUTE_CODE = ''' + @CATTRIBUTECODE + ''''+
				   ' LEFT OUTER JOIN ATTR_KEY ' + @CALIASD + ' ON ' + @CALIASC + '.KEY_CODE = ' + @CALIASD + '.KEY_CODE '
		
		SET @NCTR = @NCTR + 1

		FETCH NEXT FROM ABC INTO @CATTRIBUTECODE, @CATTRIBUTENAME
	END
	CLOSE ABC
	DEALLOCATE ABC
	SET @CATTRCOLNAME	= @CCMD1
	-- SET @CATTRJOINSTR	= @CCMD1
	SET @CATTRJOINSTRGRP= @CCMD2
	

	--********* CREATE VIEW LOC_ATTR_VALUE
	PRINT 'CREATING VIEW LOC_ATTR_VALUE...'

	SET @CCREATEALTER = ''

	IF EXISTS( SELECT NAME FROM SYSOBJECTS WHERE NAME = 'LOC_ATTR_VALUE' )
		SET @CCREATEALTER = 'ALTER'
	ELSE
		SET @CCREATEALTER = 'CREATE'

	SET @CCMDCRTCUSTATTRVALUE = @CCREATEALTER + ' VIEW LOC_ATTR_VALUE ' + CHAR(13)+
								' AS ' + CHAR(13)+
								' SELECT ' + @CATTRCOLNAME + ' A.DEPT_ID
								  FROM LOCATION A '+
								  @CATTRJOINSTRGRP

	EXEC SP_EXECUTESQL @CCMDCRTCUSTATTRVALUE

END		
--************************ END OF PROCEDURE SP_CRT_LOC_ATTR_VALUE
