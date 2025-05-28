CREATE procedure sp3s_get_wizclipbillupload
@nMode NUMERIC(1,0),
@cCmId VARCHAR(40)='',
@cDtLastUpdate varchar(50)=''
AS
BEGIN
	DECLARE @cCurLocId VARCHAR(2),@cHoLocId VARCHAR(4),@cErr VARCHAR(MAX)
	
	SELECT TOP 1 @cHoLocId=value FROM  config (NOLOCK) WHERE config_option='HO_location_id'
	SELECT TOP 1 @cCurLocId=value FROM  config (NOLOCK) WHERE config_option='location_id'
	SELECT TOP 1 @cErr=MEMO_ID FROM  WIZCLIP_ERROR (NOLOCK) WHERE ERRMSG <> ''

	IF isnull(@cErr,'') = ''
	BEGIN

		IF @nMode=1 
		BEGIN
			select dept_id into #tmploc from location (NOLOCK) where (server_loc=1 or dept_id=@cCurLocId)
			AND ISNULL(WizClip,0)=1

			IF NOT EXISTS (SELECT TOP 1 * FROM  #tmploc)
				RETURN

			--waitfor delay '00:00:05'

			SELECT TOP 1 cm_id,convert(varchar,a.last_update,109) as last_update,
			wizclip_bill_synch_last_update,cm_dt from 
			cmm01106 a with (NOLOCK) --,index=ind_cmm01106_wizclip_bill_synch_lastupdate)  Sir got removed this clause as per suggestion by Dinkar (27-03-2021) when Wizclip server was getting slow on that day
			JOIN #tmploc b (NOLOCK) ON a.location_Code =b.dept_id
			WHERE isnull(wizclip_bill_synch_last_update,'')<>a.last_update AND customer_code<>'000000000000' AND 
			cancelled=0	   
			order by cm_dt,cm_id
		END	
		ELSE
			UPDATE cmm01106 WITH (ROWLOCK) SET wizclip_bill_synch_last_update=convert(datetime,@cDtLastUpdate) where cm_id=@cCmId

	END
	
END



--exec sp3s_get_wizclipbillupload 1