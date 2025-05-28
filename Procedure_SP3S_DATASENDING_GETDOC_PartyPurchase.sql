create PROC SP3S_DATASENDING_GETDOC_PartyPurchase
(
 @CAName  varchar(15)
)
AS   
BEGIN  
		DECLARE @DCUTOFFDATE DATETIME,@cdept_id varchar(4),@cHoDeptId VARCHAR(4)

		SELECT @cdept_id=value  FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID'
		SELECT @cHoDeptId=value FROM config (NOLOCK) WHERE config_option='ho_location_id'

		Delete From xntype_merging_errors where ABS(datediff(minute,last_update,getdate()))>30
		
		if @cdept_id<>@cHoDeptId
		begin
		    select  'Sending allow only from headOffice'		
	        return

		end
		
		SET @DCUTOFFDATE=''

		DECLARE @TBLXNDETAILS TABLE (XN_TYPE VARCHAR(30),XN_ID VARCHAR(50),TABLENAME VARCHAR(100),
		LASTUPDATE DATETIME,SEND_ORDER numeric(5,0) ,COLUMNNAME VARCHAR(50))

		
		INSERT INTO @TBLXNDETAILS(XN_TYPE,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT 'WSL'AS XN_TYPE,INV_ID AS XN_ID,'INM01106' AS TABLENAME,LAST_UPDATE ,115 AS  SEND_ORDER,'INV_ID' AS COLUMNNAME   
		FROM INM01106 A (NOLOCK)  WHERE INV_DT  >=@DCUTOFFDATE AND
		A.INV_MODE =1 and  a.docwsl_PARCEL_MEMO_ID<>''
		
		AND convert(varchar,a.LAST_UPDATE,120)<>ISNULL(convert(varchar,a.doc_synch_last_update,120),'')

		

		SELECT A.XN_TYPE,XN_ID,TABLENAME,convert(varchar,LASTUPDATE,121) as lastupdate,SEND_ORDER,COLUMNNAME 
		FROM @TBLXNDETAILS A
		where DATEDIFF (SS,LASTUPDATE,GETDATE())>15
		ORDER BY SEND_ORDER,a.xn_id

END  


