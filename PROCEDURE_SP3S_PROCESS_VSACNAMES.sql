CREATE PROCEDURE SP3S_PROCESS_VSACNAMES
@cTempTable VARCHAR(200),
@cUnqIdCol varchar(100)='',
@cVsAcNameCol VARCHAR(100),
@cDestTempTable VARCHAR(200)=''
AS
BEGIN
  --FOR vs_ac_name ---
  

	 DECLARE @VM_ID VARCHAR(1000), @VSACNAMES VARCHAR(MAX),@cCmd NVARCHAR(MAX),@cStep varchar(10);
     CREATE TABLE #tVsnames (UnqId VARCHAR(50), AC_NAME VARCHAR(500), VSACNAMES VARCHAR(MAX));
 
	  SET @cStep='10'      
	  PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)     
	 
	 SET @cUnqIdCol=(CASE WHEN  @cUnqIdCol='' THEN 'a.VD_ID' ELSE 'A.'+@cUnqIdCol END)

	 IF @cDestTempTable=''
		SET @cDestTempTable=@cTempTable
	
	 SET @cCmd=N'SELECT   '+@cUnqIdCol+' UnqId,AC_NAME=  lm.AC_NAME+'' [''+CAST(CONVERT(NUMERIC(14,2),
	 sum(ISNULL(B.DEBIT_AMOUNT,0)+ISNULL(B.CREDIT_AMOUNT,0))) AS VARCHAR(50)) +B.X_TYPE+'']''
	 FROM '+@cTempTable+' A
	 JOIN VD01106 B (nolock) ON A.VM_ID=B.VM_ID 
	 JOIN LM01106 LM (NOLOCK) ON B.AC_CODE=LM.AC_CODE  
	 WHERE a.vd_id <>b.vd_id 
	 group by  '+@cUnqIdCol+',lm.AC_NAME,B.X_TYPE'
	
	 print @cCmd
	 
	 INSERT #tVsnames (UnqId, AC_NAME)
	 EXEC SP_EXECUTESQL @cCmd


	  SET @cStep='20'      
	  PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)     
	 
	--if @@spid=812
	-- select a.* from #tVsnames a join vd01106 b on a.UnqId=b.vd_id
	-- join vm01106 c on c.vm_id=b.vm_id where voucher_no='P070000001'
 
	UPDATE #tVsnames SET @VSACNAMES = VSACNAMES = COALESCE(
		  CASE COALESCE(@VM_ID, N'') 
		  WHEN UnqId THEN  @VSACNAMES+CHAR(13)+CHAR(10) + N''+ AC_NAME --+CHAR(13)+CHAR(10)
		  ELSE AC_NAME  END , N'') , 
		@VM_ID = UnqId;


	 --if @@spid=812
	 --select a.* from #tVsnames a join vd01106 b on a.UnqId=b.vd_id
	 --join vm01106 c on c.vm_id=b.vm_id where voucher_no='P070000001'
 
	  SET @cStep='30'      
	  PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)     

	 SET @cCmd=N'UPDATE a SET '+@cVsAcNameCol+'=b.VSACNAMES 
	 FROM '+@cDestTempTable+' a
	 JOIN
	 (
		SELECT UnqId, VSACNAMES = VSACNAMES,
		SR =ROW_NUMBER() OVER (PARTITION BY UNQID ORDER BY LEN(VSACNAMES) DESC)
		FROM #tVsnames
	
		) b ON '+@cUnqIdCol+'=b.UnqId and b.SR=1
	 '
	 print @cCmd
	 EXEC SP_EXECUTESQL @cCmd

  --END VS ACNAME       
END
