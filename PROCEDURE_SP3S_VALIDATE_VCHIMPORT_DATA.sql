CREATE PROCEDURE SP3S_VALIDATE_VCHIMPORT_DATA
(
	@cTempTableName  VARCHAR(MAX) ,
	@nMode			NUMERIC(1)
)
AS
BEGIN
			DECLARE @ERR BIT=0,@ERROR_MSG VARCHAR(1000)='',@cCMD NVARCHAR(MAX)

			BEGIN TRY
			if (@nMode IN (0,2))
			BEGIN
				SET @cCMD=N'update A  SET ERR_MSG=ISNULL(ERR_MSG,'''')+CHAR(13)+''Invalid excel format. Ref No should not be blank'' 
				FROM '+@cTempTableName+' A
				WHERE ISNULL(REFNO,'''')='''''
				PRINT @cCMD
				EXEC SP_EXECUTESQL @cCMD


				if (@nMode IN (2))
				BEGIN
					SET @cCMD=N'update A  SET A.BILL_NO=A.REFNO
					FROM '+@cTempTableName+' A
					WHERE ISNULL(A.BILL_NO,'''')='''''
					PRINT @cCMD
					EXEC SP_EXECUTESQL @cCMD
				END


            
				SET @cCMD=N'update A  SET ERR_MSG=ISNULL(ERR_MSG,'''')+CHAR(13)+''Invalid Excel Format. Voucher type should not be blank'' 
				FROM '+@cTempTableName+' A
				WHERE ISNULL(VOUCHERTYPE,'''')='''''
				PRINT @cCMD
				EXEC SP_EXECUTESQL @cCMD
				if (@nMode IN (0))
				BEGIN
					SET @cCMD=N'update A  SET ERR_MSG=ISNULL(ERR_MSG,'''')+CHAR(13)+''Invalid Excel Format. XN type should not be blank'' 
					FROM '+@cTempTableName+' A
					WHERE ISNULL(XNTYPE,'''')='''''
					PRINT @cCMD
					EXEC SP_EXECUTESQL @cCMD
				END
				SET @cCMD=N'update A  SET ERR_MSG=ISNULL(ERR_MSG,'''')+CHAR(13)+''Invalid Excel Format. AMOUNT should not be blank'' 
				FROM '+@cTempTableName+' A
				WHERE ISNULL(AMOUNT,'''')='''''
				PRINT @cCMD
				EXEC SP_EXECUTESQL @cCMD

				SET @cCMD=N'update A  SET ERR_MSG=ISNULL(ERR_MSG,'''')+CHAR(13)+''Invalid Excel Format. Location ID is not valid '' 
				FROM '+@cTempTableName+' A
				LEFT OUTER JOIN location b on b.dept_id=ISNULL(COSTCENTER,'''')
				WHERE ISNULL(COSTCENTER,'''')<>'''' AND b.DEPT_ID IS NULL'
				PRINT @cCMD
				EXEC SP_EXECUTESQL @cCMD

				 SET @cCMD=N'update A  SET ERR_MSG=ISNULL(ERR_MSG,'''')+CHAR(13)+''Invalid Excel Format. Voucher Type is not valid '' 
				FROM '+@cTempTableName+' A
				LEFT OUTER JOIN vchtype b on b.voucher_type=A.VOUCHERTYPE
				WHERE b.VOUCHER_CODE IS NULL'
				PRINT @cCMD
				EXEC SP_EXECUTESQL @cCMD
				
			END

			SET @cCMD=N'update A  SET ERR_MSG=ISNULL(ERR_MSG,'''')+CHAR(13)+''Invalid Excel Format. Voucher date should not be blank'' 
			FROM '+@cTempTableName+' A
			WHERE ISNULL(VOUCHERDATE,'''')='''''
			PRINT @cCMD
			EXEC SP_EXECUTESQL @cCMD

			SET @cCMD=N'update A  SET ERR_MSG=ISNULL(ERR_MSG,'''')+CHAR(13)+''Invalid Excel Format. Ledger Name should not be blank'' 
			FROM '+@cTempTableName+' A
			WHERE ISNULL(ACCOUNTNAME,'''')='''''
			PRINT @cCMD
			EXEC SP_EXECUTESQL @cCMD         

			SET @cCMD=N'update A  SET ERR_MSG=ISNULL(ERR_MSG,'''')+CHAR(13)+''Invalid Excel Format. Ledger Name is not valid '' 
			FROM '+@cTempTableName+' A
			LEFT OUTER JOIN lm01106 b on
			REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(b.ac_name,CHAR(39),''''),''&'',''''),''.'',''''),''@'',''''),'' '',''''),''_'',''''),''('',''''),'')'',''''),''-'','''')
			=REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(a.accountname,CHAR(39),''''),''&'',''''),''.'',''''),''@'',''''),'' '',''''),''_'',''''),''('',''''),'')'',''''),''-'','''')
			WHERE b.AC_CODE IS NULL'
			-- REPLACE(b.ac_name,'' '','''')=REPLACE(a.accountname  ,'' '','''') 
			PRINT @cCMD
			EXEC SP_EXECUTESQL @cCMD


			SET @cCMD=N'update A  SET ERR_MSG=ISNULL(ERR_MSG,'''')+CHAR(13)+''Invalid Excel Format.Bill By Bill Reference should not be blank'' 
			FROM '+@cTempTableName+' A
			JOIN LMV01106 B (NOLOCK) ON REPLACE(b.ac_name,'' '','''')=REPLACE(a.accountname  ,'' '','''') 
			WHERE B.BILL_BY_BILL=1 AND ISNULL(A.ACCOUNTNAME,'''')<>'''' AND ISNULL(BILL_NO,'''')=''''' 
			PRINT @cCMD
			EXEC SP_EXECUTESQL @cCMD

			END TRY
			BEGIN CATCH
				SET @ERROR_MSG=N'ERROR IN SP3S_VALIDATE_VCHIMPORT_DATA : '+ERROR_MESSAGE()
			END CATCH

			IF ISNULL(@ERROR_MSG,'')<>''
			BEGIN
				SET @cCMD=N'SELECT TOP 1 '''' REFNO,'''' VOUCHERDATE,'''' VOUCHERTYPE,'''' XNTYPE,'''' ACCOUNTNAME,0 AMOUNT,'''' NARRATION,'''' COSTCENTER ,'''+isnull(@ERROR_MSG,'')+''' ERR_MSG
				FROM '+@cTempTableName
			END
			ELSE
			BEGIN
				SET @cCMD=N'SELECT REFNO,VOUCHERDATE,VOUCHERTYPE,XNTYPE,ACCOUNTNAME,AMOUNT,NARRATION,COSTCENTER ,ERR_MSG
				FROM '+@cTempTableName+' A
				--WHERE ISNULL(ERR_MSG,'''')<>''''
				UNION 
				SELECT TOP 1 '''' REFNO,'''' VOUCHERDATE,'''' VOUCHERTYPE,'''' XNTYPE,'''' ACCOUNTNAME,null AMOUNT,'''' NARRATION,'''' COSTCENTER ,'''+isnull(@ERROR_MSG,'')+''' ERR_MSG
				FROM '+@cTempTableName+' A
				WHERE ISNULL(ERR_MSG,'''')='''' '--or '''''+isnull(@ERROR_MSG,'''')+'<>'''''
			END
			PRINT @cCMD
			EXEC SP_EXECUTESQL @cCMD

END

/*This is for forex related update
CREATE PROCEDURE SP3S_VALIDATE_VCHIMPORT_DATA
(
	@iDateMode		INT,
	@cTempTableName  VARCHAR(MAX) ,
	@nMode			NUMERIC(1)
)
AS
BEGIN
			DECLARE @ERR BIT=0,@ERROR_MSG VARCHAR(1000)='',@cCMD NVARCHAR(MAX)




			BEGIN TRY

			if(@iDateMode IN (1,6))
			BEGIN
				SET @cCMD=N'update '+@cTempTableName+' SET VOUCHERDATE=CONVERT(DATETIME,VOUCHERDATE,105)  '
				PRINT @cCMD
				EXEC SP_EXECUTESQL @cCMD
			END
			if(@iDateMode=5)
			BEGIN
				SET @cCMD=N'update '+@cTempTableName+' SET VOUCHERDATE=CONVERT(DATETIME,memo_dt,110)  '
				PRINT @cCMD
				EXEC SP_EXECUTESQL @cCMD
			END

			if (@nMode IN (0,2))
			BEGIN
				SET @cCMD=N'update A  SET ERR_MSG=ISNULL(ERR_MSG,'''')+CHAR(13)+''Invalid excel format. Ref No should not be blank'' 
				FROM '+@cTempTableName+' A
				WHERE ISNULL(REFNO,'''')='''''
				PRINT @cCMD
				EXEC SP_EXECUTESQL @cCMD


				if (@nMode IN (2))
				BEGIN
					SET @cCMD=N'update A  SET A.BILL_NO=A.REFNO
					FROM '+@cTempTableName+' A
					WHERE ISNULL(A.BILL_NO,'''')='''''
					PRINT @cCMD
					EXEC SP_EXECUTESQL @cCMD
				END


            
				SET @cCMD=N'update A  SET ERR_MSG=ISNULL(ERR_MSG,'''')+CHAR(13)+''Invalid Excel Format. Voucher type should not be blank'' 
				FROM '+@cTempTableName+' A
				WHERE ISNULL(VOUCHERTYPE,'''')='''''
				PRINT @cCMD
				EXEC SP_EXECUTESQL @cCMD
				if (@nMode IN (0))
				BEGIN
					SET @cCMD=N'update A  SET ERR_MSG=ISNULL(ERR_MSG,'''')+CHAR(13)+''Invalid Excel Format. XN type should not be blank'' 
					FROM '+@cTempTableName+' A
					WHERE ISNULL(XNTYPE,'''')='''''
					PRINT @cCMD
					EXEC SP_EXECUTESQL @cCMD
				END
				SET @cCMD=N'update A  SET ERR_MSG=ISNULL(ERR_MSG,'''')+CHAR(13)+''Invalid Excel Format. AMOUNT should not be blank'' 
				FROM '+@cTempTableName+' A
				WHERE ISNULL(AMOUNT,'''')='''''
				PRINT @cCMD
				EXEC SP_EXECUTESQL @cCMD

				SET @cCMD=N'update A  SET ERR_MSG=ISNULL(ERR_MSG,'''')+CHAR(13)+''Invalid Excel Format. Location ID is not valid '' 
				FROM '+@cTempTableName+' A
				LEFT OUTER JOIN location b on b.dept_id=ISNULL(COSTCENTER,'''')
				WHERE ISNULL(COSTCENTER,'''')<>'''' AND b.DEPT_ID IS NULL'
				PRINT @cCMD
				EXEC SP_EXECUTESQL @cCMD

				 SET @cCMD=N'update A  SET ERR_MSG=ISNULL(ERR_MSG,'''')+CHAR(13)+''Invalid Excel Format. Voucher Type is not valid '' 
				FROM '+@cTempTableName+' A
				LEFT OUTER JOIN vchtype b on b.voucher_type=A.VOUCHERTYPE
				WHERE b.VOUCHER_CODE IS NULL'
				PRINT @cCMD
				EXEC SP_EXECUTESQL @cCMD
				
			END

			SET @cCMD=N'update A  SET ERR_MSG=ISNULL(ERR_MSG,'''')+CHAR(13)+''Invalid Excel Format. Voucher date should not be blank'' 
			FROM '+@cTempTableName+' A
			WHERE ISNULL(VOUCHERDATE,'''')='''''
			PRINT @cCMD
			EXEC SP_EXECUTESQL @cCMD

			SET @cCMD=N'update A  SET ERR_MSG=ISNULL(ERR_MSG,'''')+CHAR(13)+''Invalid Excel Format. Ledger Name should not be blank'' 
			FROM '+@cTempTableName+' A
			WHERE ISNULL(ACCOUNTNAME,'''')='''''
			PRINT @cCMD
			EXEC SP_EXECUTESQL @cCMD         

			SET @cCMD=N'update A  SET ERR_MSG=ISNULL(ERR_MSG,'''')+CHAR(13)+''Invalid Excel Format. Ledger Name is not valid '' 
			FROM '+@cTempTableName+' A
			LEFT OUTER JOIN lm01106 b on
			REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(b.ac_name,CHAR(39),''''),''&'',''''),''.'',''''),''@'',''''),'' '',''''),''_'',''''),''('',''''),'')'',''''),''-'','''')
			=REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(a.accountname,CHAR(39),''''),''&'',''''),''.'',''''),''@'',''''),'' '',''''),''_'',''''),''('',''''),'')'',''''),''-'','''')
			WHERE b.AC_CODE IS NULL'
			-- REPLACE(b.ac_name,'' '','''')=REPLACE(a.accountname  ,'' '','''') 
			PRINT @cCMD
			EXEC SP_EXECUTESQL @cCMD


			SET @cCMD=N'update A  SET ERR_MSG=ISNULL(ERR_MSG,'''')+CHAR(13)+''Invalid Excel Format.Bill By Bill Reference should not be blank'' 
			FROM '+@cTempTableName+' A
			JOIN LMV01106 B (NOLOCK) ON REPLACE(b.ac_name,'' '','''')=REPLACE(a.accountname  ,'' '','''') 
			WHERE B.BILL_BY_BILL=1 AND ISNULL(A.ACCOUNTNAME,'''')<>'''' AND ISNULL(BILL_NO,'''')=''''' 
			PRINT @cCMD
			EXEC SP_EXECUTESQL @cCMD

			END TRY
			BEGIN CATCH
				SET @ERROR_MSG=N'ERROR IN SP3S_VALIDATE_VCHIMPORT_DATA : '+ERROR_MESSAGE()
			END CATCH

			IF ISNULL(@ERROR_MSG,'')<>''
			BEGIN
				SET @cCMD=N'SELECT TOP 1 '''' REFNO,'''' VOUCHERDATE,'''' VOUCHERTYPE,'''' XNTYPE,'''' ACCOUNTNAME,0 AMOUNT,'''' NARRATION,'''' COSTCENTER ,'''+isnull(@ERROR_MSG,'')+''' ERR_MSG
				FROM '+@cTempTableName
			END
			ELSE
			BEGIN
				SET @cCMD=N'SELECT REFNO,VOUCHERDATE,VOUCHERTYPE,XNTYPE,ACCOUNTNAME,AMOUNT,NARRATION,COSTCENTER ,ERR_MSG
				FROM '+@cTempTableName+' A
				WHERE ISNULL(ERR_MSG,'''')<>''''
				UNION 
				SELECT TOP 1 '''' REFNO,'''' VOUCHERDATE,'''' VOUCHERTYPE,'''' XNTYPE,'''' ACCOUNTNAME,null AMOUNT,'''' NARRATION,'''' COSTCENTER ,'''+isnull(@ERROR_MSG,'')+''' ERR_MSG
				FROM '+@cTempTableName+' A
				WHERE ISNULL(ERR_MSG,'''')='''' '--or '''''+isnull(@ERROR_MSG,'''')+'<>'''''
			END
			PRINT @cCMD
			EXEC SP_EXECUTESQL @cCMD

END
*/
