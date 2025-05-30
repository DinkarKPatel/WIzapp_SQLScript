CREATE PROCEDURE SP3S_GET_LOCATION_FKEYDATA
@CSOURCEDB VARCHAR(200),
@CSOURCETABLE VARCHAR(200),
@CSOURCEKEYFIELD VARCHAR(200),
@CXNTYPE VARCHAR(10),
@CTABLESUFFIX VARCHAR(40),
@CLOCID VARCHAR(5),
@CERRORMSG VARCHAR(MAX) OUTPUT
--WITH ENCRYPTION
AS
BEGIN
	BEGIN TRY
		DECLARE @CCMD NVARCHAR(MAX),@CTEMPTABLE VARCHAR(1000),@CTEMPTABLE1 VARCHAR(1000),@CTEMPTABLE2 VARCHAR(1000),
				@CTEMPTABLE3 VARCHAR(1000),@CTEMPTABLE4 VARCHAR(1000),@CTEMPTABLE5 VARCHAR(1000),
				@CKEYFIELDVAL VARCHAR(40),@CDESTDB VARCHAR(200),@CFILTERCONDITION VARCHAR(MAX),@NSTEP INT
		
		SET @CDESTDB='WIZAPP3S_MIRROR_'+@CLOCID+'.DBO.'
		
		SET @NSTEP=10		
		IF @CSOURCETABLE<>'#TMPMISSINGLOCDATA'
		BEGIN	
			IF OBJECT_ID('TEMPDB..#TMPMISSINGLOCDATA','U') IS NOT NULL
				DROP TABLE #TMPMISSINGLOCDATA
			
			SELECT DEPT_ID INTO #TMPMISSINGLOCDATA FROM LOCATION WHERE 1=2
		END
		
		IF OBJECT_ID('TEMPDB..#TMPMISSINGAREADATA','U') IS NOT NULL
			DROP TABLE #TMPMISSINGAREADATA
		
		SET @NSTEP=20
		SELECT AREA_CODE INTO #TMPMISSINGAREADATA FROM AREA WHERE 1=2

		IF OBJECT_ID('TEMPDB..#TMPMISSINGLMDATA','U') IS NOT NULL
			DROP TABLE #TMPMISSINGLMDATA

		SELECT AC_CODE INTO #TMPMISSINGLMDATA FROM LM01106 WHERE 1=2

		IF OBJECT_ID('TEMPDB..#TMPMISSINGFCDATA','U') IS NOT NULL
			DROP TABLE #TMPMISSINGFCDATA
		
		SELECT FC_CODE INTO #TMPMISSINGFCDATA FROM FC WHERE 1=2
		
		SET @NSTEP=25											
		SET @CTEMPTABLE=(CASE WHEN LEFT(@CSOURCETABLE,1)='#' THEN @CSOURCETABLE ELSE @CSOURCEDB+'TMP_'+@CXNTYPE+'_'+@CSOURCETABLE+'_'+@CTABLESUFFIX END)

		IF @CSOURCETABLE<>'#TMPMISSINGLOCDATA'
		BEGIN	
			SET @CCMD=N'SELECT DISTINCT A.'+@CSOURCEKEYFIELD+' FROM '+@CTEMPTABLE+'  A
						LEFT OUTER JOIN WIZAPP3S_MIRROR_'+@CLOCID+'.DBO.LOCATION B ON B.DEPT_ID=A.'+@CSOURCEKEYFIELD+'
						WHERE B.DEPT_ID IS NULL AND A.'+@CSOURCEKEYFIELD+' IS NOT NULL'

			PRINT @CCMD		
			INSERT #TMPMISSINGLOCDATA
			EXEC SP_EXECUTESQL @CCMD
		END
				
		SET @NSTEP=30
		SET @CCMD=N'SELECT DISTINCT B.AREA_CODE FROM '+@CTEMPTABLE+'  A
					JOIN LOCATION B ON B.DEPT_ID=A.'+@CSOURCEKEYFIELD+'
					LEFT OUTER JOIN WIZAPP3S_MIRROR_'+@CLOCID+'.DBO.AREA C ON C.AREA_CODE=B.AREA_CODE
					WHERE C.AREA_CODE IS NULL'
			
		INSERT #TMPMISSINGAREADATA
		EXEC SP_EXECUTESQL @CCMD
		
		SET @NSTEP=35
		SET @CCMD=N'SELECT DISTINCT B.FC_CODE FROM '+@CTEMPTABLE+'  A
					JOIN LOCATION B ON B.DEPT_ID=A.'+@CSOURCEKEYFIELD+'
					LEFT OUTER JOIN WIZAPP3S_MIRROR_'+@CLOCID+'.DBO.FC C ON C.FC_CODE=B.FC_CODE
					WHERE C.FC_CODE IS NULL'
			
		INSERT #TMPMISSINGFCDATA
		EXEC SP_EXECUTESQL @CCMD

		SET @NSTEP=40
		SET @CCMD=N'SELECT DISTINCT B.DEPT_AC_CODE FROM '+@CTEMPTABLE+'  A
					JOIN LOCATION B ON B.DEPT_ID=A.'+@CSOURCEKEYFIELD+'
					LEFT OUTER JOIN WIZAPP3S_MIRROR_'+@CLOCID+'.DBO.LM01106 C ON C.AC_CODE=B.DEPT_AC_CODE
					WHERE C.AC_CODE IS NULL
					UNION
					SELECT DISTINCT B.CONTROL_AC_CODE FROM '+@CTEMPTABLE+'  A
					JOIN LOCATION B ON B.DEPT_ID=A.'+@CSOURCEKEYFIELD+'
					LEFT OUTER JOIN WIZAPP3S_MIRROR_'+@CLOCID+'.DBO.LM01106 C ON C.AC_CODE=B.CONTROL_AC_CODE
					WHERE C.AC_CODE IS NULL'
			
		INSERT #TMPMISSINGLMDATA
		EXEC SP_EXECUTESQL @CCMD		


		IF EXISTS (SELECT TOP 1 AREA_CODE FROM #TMPMISSINGAREADATA)
		BEGIN
			SET @NSTEP=50
			EXEC SP3S_GET_AREA_FKEYDATA
			@CSOURCEDB='',
			@CSOURCETABLE='#TMPMISSINGAREADATA',
			@CSOURCEKEYFIELD='AREA_CODE',
			@CXNTYPE=@CXNTYPE,
			@CTABLESUFFIX=@CTABLESUFFIX,
			@CLOCID=@CLOCID,
			@CERRORMSG=@CERRORMSG OUTPUT
		END	

		IF EXISTS (SELECT TOP 1 FC_CODE FROM #TMPMISSINGFCDATA)
		BEGIN
			SET @NSTEP=60
			EXEC SP3S_GET_FC_FKEYDATA
			@CSOURCEDB='',
			@CSOURCETABLE='#TMPMISSINGFCDATA',
			@CSOURCEKEYFIELD='FC_CODE',
			@CXNTYPE=@CXNTYPE,
			@CTABLESUFFIX=@CTABLESUFFIX,
			@CLOCID=@CLOCID,
			@CERRORMSG=@CERRORMSG OUTPUT
		END	


		IF EXISTS (SELECT TOP 1 AC_CODE FROM #TMPMISSINGLMDATA)
		BEGIN
			SET @NSTEP=70
			EXEC SP3S_GET_LM01106_FKEYDATA
			@CSOURCEDB='',
			@CSOURCETABLE='#TMPMISSINGLMDATA',
			@CSOURCEKEYFIELD='AC_CODE',
			@CXNTYPE=@CXNTYPE,
			@CTABLESUFFIX=@CTABLESUFFIX,
			@CLOCID=@CLOCID,
			@CERRORMSG=@CERRORMSG OUTPUT
		END	

		
		IF EXISTS (SELECT TOP 1 DEPT_ID FROM #TMPMISSINGLOCDATA)
		BEGIN
			SET @NSTEP=80

			SET @CFILTERCONDITION= 'B.DEPT_ID IN (SELECT DISTINCT MAJOR_DEPT_ID FROM #TMPMISSINGLOCDATA A
									JOIN LOCATION B ON A.DEPT_ID=B.DEPT_ID)'
			
			EXEC UPDATEMASTERXN_MIRROR
			@CSOURCEDB='',
			@CSOURCETABLE='LOCATION',
			@CDESTDB=@CDESTDB,
			@CDESTTABLE='LOCATION',
			@CKEYFIELD1='DEPT_ID',
			@LINSERTONLY=0,
			@CFILTERCONDITION=@CFILTERCONDITION,
			
			
			@LUPDATEONLY=0,
			@BALWAYSUPDATE=1
			
			SET @NSTEP=90			
			SET @CFILTERCONDITION= 'B.DEPT_ID IN (SELECT DEPT_ID FROM #TMPMISSINGLOCDATA)'
			
			EXEC UPDATEMASTERXN_MIRROR
			@CSOURCEDB='',
			@CSOURCETABLE='LOCATION',
			@CDESTDB=@CDESTDB,
			@CDESTTABLE='LOCATION',
			@CKEYFIELD1='DEPT_ID',
			@LINSERTONLY=0,
			@CFILTERCONDITION=@CFILTERCONDITION,
			
			
			@LUPDATEONLY=0,
			@BALWAYSUPDATE=1
		END
							
		GOTO END_PROC									
	END TRY
	
	BEGIN CATCH
		SELECT @CERRORMSG='PROCEDURE SP3S_GET_LOCATION_FKEYDATA : '+ISNULL(ERROR_PROCEDURE(),'NULL P')+'STEP :'+STR(ISNULL(@NSTEP,0))+ ' LINE NO. :'+
		ISNULL(LTRIM(RTRIM(STR(ERROR_LINE()))),'NULL LINE')+'MSG :'+ISNULL(ERROR_MESSAGE(),'NULL MSG')
		
		GOTO END_PROC
	END CATCH
	
END_PROC:
		
END
----'END OF PROCEDURE SP3S_GET_LOCATION_FKEYDATA'
