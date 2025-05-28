CREATE PROCEDURE SP3S_SHRINKLOG_forcly
@nMode NUMERIC(1,0)=0
AS
BEGIN
	declare @cCmd nvarchar(max),@cRecoveryModel varchar(20),@cBkpFileName VARCHAR(500)

	if exists (select top 1 * from schedule WHERE bkp_type='TRN') AND @nMode IN (0,1)
	BEGIN
		declare @cDbname varchar(200)
		select @cDbname=db_name()
		SET @cRecoveryModel=''

		select @cRecoveryModel=recovery_model_desc from sys.databases where name=@cDbname

		if @cRecoveryModel<>'simple' 
		BEGIN
			SELECT top 1 @cBkpFileName=physical_device_name
			FROM  msdb.dbo.backupmediafamily bmf (NOLOCK)
			INNER JOIN msdb.dbo.backupset bs (NOLOCK) ON bmf.media_set_id = bs.media_set_id 
			JOIN sys.database_recovery_status drs (NOLOCK) on drs.database_guid=bs.database_guid
			JOIN sys.databases db (nolock) on db.database_id=drs.database_id
			WHERE db.name =@cDbname AND bs.type ='d'
			order by backup_finish_date desc
			
			IF isnull(@cBkpFileName,'')='' OR @nMode=1
			BEGIN
				set @cCmd=N'BACKUP DATABASE '+@CdBnAME+' TO DISK=''NUL:'''
				print @cCmd
				EXEC SP_EXECUTESQL @cCmd
			END

			set @cCmd=N'BACKUP LOG '+@CdBnAME+' TO DISK=''NUL:'''
			print @cCmd
			EXEC SP_EXECUTESQL @cCmd
		end
		exec sp_shrinklogfile @cDbname=@cDbname
	END

	if exists (select top 1 * from schedule WHERE bkp_type='TRN') AND @nMode IN (0,2)
	BEGIN

		set @cDbname=db_name()+'_image'
		SET @cRecoveryModel=''
		select @cRecoveryModel=recovery_model_desc from sys.databases where name=@cDbname

		if ISNULL(@cRecoveryModel,'') not in ('simple','')
		begin
			SET @cBkpFileName=''

			SELECT top 1 @cBkpFileName=physical_device_name
			FROM  msdb.dbo.backupmediafamily bmf (NOLOCK)
			INNER JOIN msdb.dbo.backupset bs (NOLOCK) ON bmf.media_set_id = bs.media_set_id 
			JOIN sys.database_recovery_status drs (NOLOCK) on drs.database_guid=bs.database_guid
			JOIN sys.databases db (nolock) on db.database_id=drs.database_id
			WHERE db.name =@cDbname AND bs.type ='d'
			order by backup_finish_date desc
			
			IF isnull(@cBkpFileName,'')=''
			BEGIN
				set @cCmd=N'BACKUP DATABASE '+@CdBnAME+' TO DISK=''NUL:'''
				print @cCmd
				EXEC SP_EXECUTESQL @cCmd
			END

			set @cCmd=N'BACKUP LOG '+@CdBnAME+' TO DISK=''NUL:'''
			print @cCmd
			EXEC SP_EXECUTESQL @cCmd
		end
		
		exec sp_shrinklogfile @cDbname=@cDbname



		set @cDbname=db_name()+'_pmt'
		SET @cRecoveryModel=''

		select @cRecoveryModel=recovery_model_desc from sys.databases where name=@cDbname

		if ISNULL(@cRecoveryModel,'') not in ('simple','') AND @nMode IN (0,3)
		begin
			SET @cBkpFileName=''

			SELECT top 1 @cBkpFileName=physical_device_name
			FROM  msdb.dbo.backupmediafamily bmf (NOLOCK)
			INNER JOIN msdb.dbo.backupset bs (NOLOCK) ON bmf.media_set_id = bs.media_set_id 
			JOIN sys.database_recovery_status drs (NOLOCK) on drs.database_guid=bs.database_guid
			JOIN sys.databases db (nolock) on db.database_id=drs.database_id
			WHERE db.name =@cDbname AND bs.type ='d'
			order by backup_finish_date desc
			
			IF isnull(@cBkpFileName,'')=''
			BEGIN
				set @cCmd=N'BACKUP DATABASE '+@CdBnAME+' TO DISK=''NUL:'''

				print @cCmd
				EXEC SP_EXECUTESQL @cCmd
			END

			set @cCmd=N'BACKUP LOG '+@CdBnAME+' TO DISK=''NUL:'''
			print @cCmd
			EXEC SP_EXECUTESQL @cCmd
		end
		exec sp_shrinklogfile @cDbname=@cDbname
	END

	IF @nMode IN (0,4)
	BEGIN
		SET @cRecoveryModel=''
		set @cDbname=db_name()+'_temp'
		select @cRecoveryModel=recovery_model_desc from sys.databases where name=@cDbname

		if ISNULL(@cRecoveryModel,'') not in ('simple','') 
		begin
		
			SET @cBkpFileName=''

			SELECT top 1 @cBkpFileName=physical_device_name
			FROM  msdb.dbo.backupmediafamily bmf (NOLOCK)
			INNER JOIN msdb.dbo.backupset bs (NOLOCK) ON bmf.media_set_id = bs.media_set_id 
			JOIN sys.database_recovery_status drs (NOLOCK) on drs.database_guid=bs.database_guid
			JOIN sys.databases db (nolock) on db.database_id=drs.database_id
			WHERE db.name =@cDbname AND bs.type ='d'
			order by backup_finish_date desc
			
			IF isnull(@cBkpFileName,'')=''
			BEGIN
				set @cCmd=N'BACKUP DATABASE '+@CdBnAME+' TO DISK=''NUL:'''
				print @cCmd
				EXEC SP_EXECUTESQL @cCmd
			END

			set @cCmd=N'BACKUP LOG '+@CdBnAME+' TO DISK=''NUL:'''
			print @cCmd
			EXEC SP_EXECUTESQL @cCmd
		end

		exec sp_shrinklogfile @cDbname=@cDbname
	END
END