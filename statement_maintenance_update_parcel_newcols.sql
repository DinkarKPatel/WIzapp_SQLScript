DECLARE @cCmd NVARCHAR(MAX)
IF OBJECT_ID('parcel_mst_backup','u') is  null
BEGIN
	SET @cCmd=N'SELECT parcel_memo_id,ac_code into parcel_mst_backup from parcel_mst' 
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd	
END

IF  EXISTS (SELECT TOP 1 'U' FROM INFORMATION_SCHEMA .COLUMNS WHERE TABLE_NAME ='PARCEL_MST' and COLUMN_NAME ='ac_code')
BEGIN	
	SET @cCmd=N'UPDATE B SET ac_CODE =A.ac_code  FROM parcel_mst A
	JOIN parcel_det B ON A.parcel_memo_id =B.parcel_memo_id
	JOIN lm01106 c on c.ac_code=a.ac_code' 
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd
	
	SET @cCmd=N'UPDATE A SET REF_MEMO_ID =B.ref_memo_id,a.REF_MEMO_NO =b.ref_memo_no   FROM parcel_det A
	JOIN PARCEL_BILLS B ON A.parcel_memo_id=B.parcel_memo_id'
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd
	
	SET @cCmd=N'IF EXISTS (SELECT TOP 1 ''U'' FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE 
				WHERE TABLE_NAME =''PARCEL_MST'' AND CONSTRAINT_NAME =''FK_parcel_mst_lm'' AND COLUMN_NAME =''AC_CODE'')
		ALTER TABLE PARCEL_MST DROP CONSTRAINT FK_parcel_mst_lm'
	PRINT @cCmd	
	EXEC SP_EXECUTESQL @cCmd

	SET @cCmd=N'ALTER TABLE PARCEL_MST DROP COLUMN ac_code'
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd
END
