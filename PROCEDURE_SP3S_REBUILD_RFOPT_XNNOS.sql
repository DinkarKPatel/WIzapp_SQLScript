
CREATE PROCEDURE SP3S_REBUILD_RFOPT_XNNOS
@cRfTableName VARCHAR(500)
AS
BEGIN
	declare @cErrmsg varchar(1000)

	DECLARE @tErrors TABLE (xn_type VARCHAR(10),errmsg VARCHAR(1000))
	
	SET @cErrmsg=''
	
	IF EXISTS (SELECT TOP 1 xn_id FROM xnnos WHERE xn_type IN ('OPS'))
	BEGIN
		exec sp3sbuildops '',4,' JOIN xnnos on xnnos.xn_id=a.dept_id AND xnnos.xn_type=''OPS''','',@cRfTableName,@cErrmsg output
		
		IF ISNULL(@cErrmsg,'')<>''
			INSERT @tErrors	
			SELECT 'OPS',@cErrmsg
		ELSE
			DELETE FROM xnnos WHERE xn_type IN ('OPS')	
	END	

	IF EXISTS (SELECT TOP 1 xn_id FROM xnnos WHERE xn_type IN ('PRD'))
	BEGIN
		SET @cErrmsg=''
		exec sp3sbuildPRD '',4,' JOIN xnnos on xnnos.xn_id=b.memo_id AND xnnos.xn_type=''PRD''','',@cRfTableName,@cErrmsg output
		
		IF ISNULL(@cErrmsg,'')<>''
			INSERT @tErrors	
			SELECT 'PRD',@cErrmsg
		ELSE
			DELETE FROM xnnos WHERE xn_type IN ('PRD')	
	END	


	IF EXISTS (SELECT TOP 1 xn_id FROM xnnos WHERE xn_type='DCO')
	BEGIN
		SET @cErrmsg=''
		exec sp3sbuilddco '',4,' JOIN xnnos on xnnos.xn_id=b.memo_id AND xnnos.xn_type IN (''DCO'')','',@cRfTableName,@cErrmsg output
		
		IF ISNULL(@cErrmsg,'')<>''
			INSERT @tErrors	
			SELECT 'DCO',@cErrmsg
		ELSE
			DELETE FROM xnnos WHERE xn_type IN ('DCO')

	END	

	IF EXISTS (SELECT TOP 1 xn_id FROM xnnos WHERE LEFT(xn_type,3)='PIM')
	BEGIN
		SET @cErrmsg=''
		EXEC sp3sbuildPUR '',4,' JOIN xnnos on xnnos.xn_id=b.mrr_id AND LEFT(xnnos.xn_type,3)=''pim''','',0,@cRfTableName,@cErrmsg output
		
		IF ISNULL(@cErrmsg,'')<>''
			INSERT @tErrors	
			SELECT 'PIM',@cErrmsg
		ELSE
			DELETE FROM xnnos WHERE  LEFT(xn_type,3)='PIM'				
	END	

	IF EXISTS (SELECT TOP 1 xn_id FROM xnnos WHERE xn_type IN ('GRN'))
	BEGIN
		SET @cErrmsg=''
		EXEC SP3SBuildGRNPS '',4,' JOIN xnnos on xnnos.xn_id=b.memo_id AND xnnos.xn_type=''GRN''','',0,@cRfTableName,@cErrmsg output
		
		IF ISNULL(@cErrmsg,'')<>''
			INSERT @tErrors	
			SELECT 'GRN',@cErrmsg
		ELSE
			DELETE FROM xnnos WHERE  LEFT(xn_type,3)='GRN'				
	END	

	IF EXISTS (SELECT TOP 1 xn_id FROM xnnos WHERE LEFT(xn_type,3)='INM')
	BEGIN
		SET @cErrmsg=''
		EXEC sp3sbuildWSL '',4,' JOIN xnnos on xnnos.xn_id=b.inv_id AND LEFT(xnnos.xn_type,3)=''inm''','',@cRfTableName,@cErrmsg output
		
		IF ISNULL(@cErrmsg,'')<>''
			INSERT @tErrors	
			SELECT 'INM',@cErrmsg
		ELSE
			DELETE FROM xnnos WHERE  LEFT(xn_type,3)='INM'				
	END	

	IF EXISTS (SELECT TOP 1 xn_id FROM xnnos WHERE LEFT(xn_type,3)='RMM')
	BEGIN
		SET @cErrmsg=''
		EXEC sp3sbuildPRT '',4,' JOIN xnnos on xnnos.xn_id=b.rm_id AND LEFT(xnnos.xn_type,3)=''rmm''','',@cRfTableName,@cErrmsg output
		
		IF ISNULL(@cErrmsg,'')<>''
			INSERT @tErrors	
			SELECT 'RMM',@cErrmsg
		ELSE
			DELETE FROM xnnos WHERE  LEFT(xn_type,3)='RMM'							
	END	

	IF EXISTS (SELECT TOP 1 xn_id FROM xnnos WHERE LEFT(xn_type,3)='CNM')
	BEGIN
		SET @cErrmsg=''
		EXEC sp3sbuildWSR '',4,' JOIN xnnos on xnnos.xn_id=b.cn_id AND LEFT(xnnos.xn_type,3)=''cnm''','',0,@cRfTableName,@cErrmsg output
		
		IF ISNULL(@cErrmsg,'')<>''
			INSERT @tErrors	
			SELECT 'CNM',@cErrmsg
		ELSE
			DELETE FROM xnnos WHERE  LEFT(xn_type,3)='CNM'							
	END	
		
	IF EXISTS (SELECT TOP 1 xn_id FROM xnnos WHERE xn_type='SLS')
	BEGIN
		SET @cErrmsg=''
		EXEC sp3sbuildsls '',4,' JOIN xnnos on xnnos.xn_id=b.cm_id AND xnnos.xn_type IN (''SLS'',''SLR'')','',@cRfTableName,@cErrmsg output
		
		IF ISNULL(@cErrmsg,'')<>''
			INSERT @tErrors	
			SELECT 'SLS',@cErrmsg
		ELSE
			DELETE FROM xnnos WHERE  LEFT(xn_type,3)='SLS'							
	END	

	IF EXISTS (SELECT TOP 1 xn_id FROM xnnos WHERE LEFT(xn_type,3)='APP')
	BEGIN
		SET @cErrmsg=''
		EXEC sp3sbuildAPP '',4,' JOIN xnnos on xnnos.xn_id=b.memo_id AND LEFT(xnnos.xn_type,3)=''APP''','',@cRfTableName,@cErrmsg output
		
		IF ISNULL(@cErrmsg,'')<>''
			INSERT @tErrors	
			SELECT 'APP',@cErrmsg
		ELSE
			DELETE FROM xnnos WHERE  LEFT(xn_type,3)='APP'							
	END	

	IF EXISTS (SELECT TOP 1 xn_id FROM xnnos WHERE LEFT(xn_type,3)='APR')
	BEGIN
		SET @cErrmsg=''
		EXEC sp3sbuildAPR '',4,' JOIN xnnos on xnnos.xn_id=b.memo_id AND LEFT(xnnos.xn_type,3)=''APR''','',@cRfTableName,@cErrmsg output
		
		IF ISNULL(@cErrmsg,'')<>''
			INSERT @tErrors	
			SELECT 'APR',@cErrmsg
		ELSE
			DELETE FROM xnnos WHERE  LEFT(xn_type,3)='APR'							
	END	

	IF EXISTS (SELECT TOP 1 xn_id FROM xnnos WHERE LEFT(xn_type,3)='CNC')
	BEGIN
		SET @cErrmsg=''
		EXEC sp3sbuildCNC '',4,' JOIN xnnos on xnnos.xn_id=b.cnc_memo_id AND LEFT(xnnos.xn_type,3)=''CNC''','',@cRfTableName,@cErrmsg output
		
		IF ISNULL(@cErrmsg,'')<>''
			INSERT @tErrors	
			SELECT 'CNC',@cErrmsg
		ELSE
			DELETE FROM xnnos WHERE  LEFT(xn_type,3)='CNC'							
	END		

	IF EXISTS (SELECT TOP 1 xn_id FROM xnnos WHERE LEFT(xn_type,3)='WPS')
	BEGIN
		SET @cErrmsg=''
		EXEC sp3sbuildWPI '',4,' JOIN xnnos on xnnos.xn_id=b.ps_id AND LEFT(xnnos.xn_type,3)=''WPS''','',@cRfTableName,@cErrmsg output
		
		IF ISNULL(@cErrmsg,'')<>''
			INSERT @tErrors	
			SELECT 'WPS',@cErrmsg
		ELSE
			DELETE FROM xnnos WHERE  LEFT(xn_type,3)='WPS'							
	END		

	IF EXISTS (SELECT TOP 1 xn_id FROM xnnos WHERE LEFT(xn_type,3)='DNP')
	BEGIN
		SET @cErrmsg=''
		EXEC SP3SBuildDNPI '',4,' JOIN xnnos on xnnos.xn_id=b.ps_id AND LEFT(xnnos.xn_type,3)=''DNP''','',@cRfTableName,@cErrmsg output
		
		IF ISNULL(@cErrmsg,'')<>''
			INSERT @tErrors	
			SELECT 'DNPI',@cErrmsg
		ELSE
			DELETE FROM xnnos WHERE  LEFT(xn_type,3)='DNP'							
	END		
	

	IF EXISTS (SELECT TOP 1 xn_id FROM xnnos WHERE LEFT(xn_type,3)='IRM')
	BEGIN
		SET @cErrmsg=''
		EXEC SP3SBuildIRR '',4,' JOIN xnnos on xnnos.xn_id=b.irm_memo_id AND LEFT(xnnos.xn_type,3)=''IRM''','',@cRfTableName,@cErrmsg output
		
		IF ISNULL(@cErrmsg,'')<>''
			INSERT @tErrors	
			SELECT 'IRM',@cErrmsg
		ELSE
			DELETE FROM xnnos WHERE  LEFT(xn_type,3)='IRM'										
	END		

	IF EXISTS (SELECT TOP 1 xn_id FROM xnnos WHERE LEFT(xn_type,3)='SCM')
	BEGIN
		SET @cErrmsg=''
		EXEC sp3sbuildSCM '',4,' JOIN xnnos on xnnos.xn_id=b.memo_id AND LEFT(xnnos.xn_type,3)=''SCM''','',@cRfTableName,@cErrmsg output
		
		IF ISNULL(@cErrmsg,'')<>''
			INSERT @tErrors	
			SELECT 'SCM',@cErrmsg
		ELSE
			DELETE FROM xnnos WHERE  LEFT(xn_type,3)='SCM'										
	END		

	IF EXISTS (SELECT TOP 1 xn_id FROM xnnos WHERE LEFT(xn_type,3)='JWI')
	BEGIN
		SET @cErrmsg=''
		EXEC sp3sbuildJWI '',4,' JOIN xnnos on xnnos.xn_id=b.issue_id AND LEFT(xnnos.xn_type,3)=''JWI''','',@cRfTableName,@cErrmsg output
		
		IF ISNULL(@cErrmsg,'')<>''
			INSERT @tErrors	
			SELECT 'JWI',@cErrmsg
		ELSE
			DELETE FROM xnnos WHERE  LEFT(xn_type,3)='JWI'										
	END		

	IF EXISTS (SELECT TOP 1 xn_id FROM xnnos WHERE LEFT(xn_type,3)='JWR')
	BEGIN
		SET @cErrmsg=''
		EXEC sp3sbuildJWR '',4,' JOIN xnnos on xnnos.xn_id=b.receipt_id AND LEFT(xnnos.xn_type,3)=''JWR''','',@cRfTableName,@cErrmsg output
		
		IF ISNULL(@cErrmsg,'')<>''
			INSERT @tErrors	
			SELECT 'JWR',@cErrmsg
		ELSE
			DELETE FROM xnnos WHERE  LEFT(xn_type,3)='JWR'										
	END		

	IF EXISTS (SELECT TOP 1 xn_id FROM xnnos WHERE LEFT(xn_type,3)='SNC')
	BEGIN
		SET @cErrmsg=''
		EXEC sp3sbuildSnc '',4,' JOIN xnnos on xnnos.xn_id=b.memo_id AND LEFT(xnnos.xn_type,3)=''SNC''','',@cRfTableName,@cErrmsg output
		
		IF ISNULL(@cErrmsg,'')<>''
			INSERT @tErrors	
			SELECT 'SNC',@cErrmsg
		ELSE
			DELETE FROM xnnos WHERE  LEFT(xn_type,3)='SNC'													
	END		

	IF EXISTS (SELECT TOP 1 xn_id FROM xnnos WHERE LEFT(xn_type,3)='TTM')
	BEGIN
		SET @cErrmsg=''
		EXEC sp3sbuildttm '',4,' JOIN xnnos on xnnos.xn_id=b.memo_id AND LEFT(xnnos.xn_type,3)=''TTM''','',0,@cRfTableName,@cErrmsg output
		
		IF ISNULL(@cErrmsg,'')<>''
			INSERT @tErrors	
			SELECT 'TTM',@cErrmsg
		ELSE
			DELETE FROM xnnos WHERE  LEFT(xn_type,3)='TTM'													
	END		
	
	SELECT * FROM @tErrors	
END
