CREATE PROC SP3S_RPS_FILTER
(
	@CCUSTOMERCODE	NVARCHAR(20)='',
	@DTFROM			VARCHAR(15)	='',
	@DTTO			VARCHAR(15)	='',
	@CMEMOTYPE		VARCHAR(3)	='0',
	@CMEMOSTATUS	NUMERIC(3)	=0,
	@CDEPTID		VARCHAR(5)	='',
	@BCANCELLED		NUMERIC(1)	=0,
	@NORDERTYPE		NUMERIC(3)=0,
	@CSALESPERSON VARCHAR(10)='',
	@NHOLDBACK NUMERIC(1)=0,	 /*0 FOR ALL, 1 FOR WITHOUT HOLDBACK AND 2 FOR WITH HOLDBACK*/
	@NEST NUMERIC(1)=0,
	@LOC VARCHAR(5)='',
	@CUSER_CODE VARCHAR(7)=''
)  
AS  
BEGIN  
  DECLARE @QUERY NVARCHAR(MAX)  ,@QUERY1 NVARCHAR(MAX)

  if @CUSER_CODE=''
  set @CUSER_CODE='0000000'

  SET @QUERY = N'
SELECT DISTINCT A.CM_NO AS PS_NO,A.CM_DT AS PS_DT,CMM.CM_NO AS CASHMEMO_NO,CMM.CM_DT AS CASHMEMO_DT,A.SUBTOTAL,A.NET_AMOUNT,
	A.DISCOUNT_AMOUNT,NULL QUANTITY,C.CUSTOMER_FNAME+'' ''+C.CUSTOMER_LNAME AS CUSTOMER_NAME,C.USER_CUSTOMER_CODE,
	A.FIN_YEAR,A.CANCELLED,A.CM_ID AS MEMO_ID,CMM.NET_AMOUNT AS CASHMEMO_NET_AMOUNT,U.username as PACKSLIP_USER_NAME
FROM RPS_MST A  (NOLOCK)
JOIN USERS U (NOLOCK) ON U.user_code=A.USER_CODE
JOIN CUSTDYM C  (NOLOCK) ON A.CUSTOMER_CODE=C.CUSTOMER_CODE  
LEFT JOIN cmm01106 CMM (nolock) ON CMM.cm_id=A.Ref_cm_id
Where a.cm_dt between '''+@DTFROM+''' and '''+@DTTO +'''
and '+(case when @LOC='' THEN '1=1' ELSE ' a.location_code='''+@loc+'''' END)+
' AND A.CANCELLED = '+(CASE WHEN @BCANCELLED = 2 THEN 'A.CANCELLED'
										WHEN @BCANCELLED = 1 THEN '1'
										WHEN @BCANCELLED = 0 THEN '0' END )+
' AND '+ (CASE WHEN @cMemoStatus = 2 THEN ' isnull(A.Ref_cm_id,'''')<>'''' '  WHEN @cMemoStatus = 1 THEN ' isnull(A.Ref_cm_id,'''')=''''  ' ELSE ' 1=1 ' END)


PRINT ISNULL(@QUERY,'NULL QUERY,THUS NO RESULT.')
  PRINT ISNULL(@QUERY1,'NULL QUERY1,THUS NO RESULT.')
  DECLARE @QUERY_ALL NVARCHAR(MAX)
  SET @QUERY_ALL=ISNULL(@QUERY,'') + ISNULL(@QUERY1,'')
  EXEC SP_EXECUTESQL @QUERY_ALL
END