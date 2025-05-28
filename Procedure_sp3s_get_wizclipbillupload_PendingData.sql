CREATE procedure sp3s_get_wizclipbillupload_PendingData 
@nMode NUMERIC(1,0),
@cCmId VARCHAR(40)='',
@cDtLastUpdate varchar(50)=''
AS
BEGIN
	DECLARE @cCurLocId VARCHAR(5),@cHoLocId VARCHAR(5),@cErr VARCHAR(MAX),@cCutoffDate VARCHAR(20),@cCmd NVARCHAR(MAX)
	
	SELECT TOP 1 @cHoLocId=value FROM  config (NOLOCK) WHERE config_option='HO_location_id'
	SELECT TOP 1 @cCurLocId=value FROM  config (NOLOCK) WHERE config_option='location_id'
	SELECT TOP 1 @cErr=MEMO_ID FROM  WIZCLIP_ERROR (NOLOCK) WHERE ERRMSG <> ''
	SELECT TOP 1 @cCutoffDate=value FROM config(NOLOCK) WHERE config_option='wizclip_bill_upload_cutoffdate'
	SET @cCutoffDate=ISNULL(@cCutoffDate,'')

	IF isnull(@cErr,'') = ''
	BEGIN

		IF @nMode=1 
		BEGIN
			
	
			select dept_id ,enable_epaper_billing into #tmploc from location (NOLOCK) where (server_loc=1 or dept_id=@cCurLocId)
			AND ISNULL(WizClip,0)=1

			IF NOT EXISTS (SELECT TOP 1 * FROM  #tmploc)
				RETURN
			
		
		--	WAITFOR DELAY '00:00:05'

			SET @cCmd=N'SELECT  cm_id,convert(varchar,a.last_update,109) as last_update,
			wizclip_bill_synch_last_update,cm_dt from 
			cmm01106 a with (NOLOCK) --,index=ind_cmm01106_wizclip_bill_synch_lastupdate)  Sir got removed this clause as per suggestion by Dinkar (27-03-2021) when Wizclip server was getting slow on that day
			JOIN #tmploc b (NOLOCK) ON a.location_code=b.dept_id
			WHERE wizclip_bill_synch_last_update<>a.last_update AND customer_code<>''000000000000'' AND 
			cancelled=0	AND wizclip_bill_synch_last_update IS NOT NULL 
			--and (isnull(a.ebills_tinyurl,'''') <> ''''  or isnull(b.enable_epaper_billing,0)=0)  -- Puts this condition as problem of partial data getting uploaded on Wizclip
																	   -- Decided after discussion with Sir in Evening meeting (29-03-2022)
			AND '+ (case when @cCutoffDate='' then ' DATEDIFF(dd,cm_dt,convert(date,getdate()))<=2 ' ELSE ' cm_dt>='''+@cCutoffDate+'''' END)+
			---- Put the above condition after discussion on 15-09-2022 with Sir and Sonu When problem started coming on Wizclip server
			---- due to Cobb's 500 locations started sending their Pending Wizclip data after a 2 months gap (Ticket#09-1301)
			---- AS per Sir Cutoff date shall be maintained at Location end not from Head office--
					
			' order by cm_dt,cm_id'
			PRINT @cCmd
			EXEC SP_EXECUTESQL @cCmd
		END	
		ELSE
			UPDATE cmm01106 WITH (ROWLOCK) SET wizclip_bill_synch_last_update=convert(datetime,@cDtLastUpdate) where cm_id=@cCmId

	END
	
END


 