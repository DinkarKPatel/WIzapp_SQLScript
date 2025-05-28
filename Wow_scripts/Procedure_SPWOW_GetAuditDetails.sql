
create Procedure SPWOW_GetAuditDetails
(
  @cXnType varchar(10),
  @cXnId varchar(50)=''

)
as
BEGIN
      
	  SET NOCOUNT ON 
	  Print '##Statrt'+convert(varchar(10),getdate(),121)

	  Declare @ctableName varchar(100),@cjoin varchar(100),@dtsql nvarchar(max),
	          @cTranName varchar(100)

      if @cXnType='WPS'
	  begin
	      
		  SET @CTABLENAME='WPS_MST'
		  set @cTranName='WSl PackSlip'
		  set @cjoin=' b.ps_id'

	  end

	 
	SET @DTSQL=N';WITH XN_AUDIT AS 
		(
		SELECT  A.XN_ID,AUDITED_ON [Edited Date and Time] ,CWIZUSERNAME,b.Ps_dt [Memo date],b.ps_no [Memo no],
		       SR=Dense_rank() OVER ( partition by a.xn_id ,a.FIELD_NAME ORDER BY AUDITED_ON) ,
			   Product_Code [Product Code] ,
			   FiledName= FIELD_NAME,
			   [Original Value]= OLDVAL,
			   [Current Value]=NEWVAL,u.username  as [Original User],
			   a.COMPUTER_NAME [Edited On Device],
			   CWIZUSERNAME  [Edited By (User)]
			 
		FROM XN_AUDIT_TRIAL_DET A
		JOIN '+@CTABLENAME+' B (NOLOCK) ON A.XN_ID ='+@cjoin+'
		Left join users u on u.user_code =b.user_code 
		WHERE XN_TYPE ='''+@cXnType+''' and xn_id='''+@cXnId+'''
		
		)

		SELECT '''+@cTranName+''' [Transaction Type],  [Memo date], [Memo no] ,
				[Product Code],FiledName [Field Name],[Original Value],[Current Value]  ,
				[Original User],[Edited By (User)],[Edited On Device],[Edited Date and Time]
		FROM XN_AUDIT A 
		where FiledName<>''AC_CODE'' and sr=1
		union all
		SELECT '''+@cTranName+''' [Transaction Type],  [Memo date], [Memo no] ,
				[Product Code],''PartyName'' as FiledName,LM.AC_NAME [OriginalValue],LM1.AC_NAME [Currentvalue]  ,
				[Original User],[Edited By (User)],[Edited On Device],[Edited Date and Time]
		FROM XN_AUDIT A 
		JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE =A.[Original Value]
		JOIN LM01106 LM1 (NOLOCK) ON LM1.AC_CODE =A.[Current Value]
		where FiledName=''AC_CODE'' and sr=1 '

		print @DTSQL
		exec sp_executesql @DTSQL

		

	  Print '##END'++convert(varchar(10),getdate(),121)



END
