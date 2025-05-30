CREATE PROCEDURE VALIDATEXN_MIRROR_SLS_BATCH_SINGLE  
 @CMEMOID VARCHAR(40),
 @BCHECKTEMPDATA BIT=0
-- WITH ENCRYPTION
AS  
BEGIN  
	 DECLARE @NCMDGROSS NUMERIC(10,2),@NCMDNET NUMERIC (10,2), @NCMDTOT NUMERIC (10,2),  
		@NCMDDISC NUMERIC (10,2),@NCMMDISC NUMERIC (10,2),@NCMMNET NUMERIC (10,2),  
		@NCMMSTOT NUMERIC(10,2),@LCANCELLED BIT,@NCMMODE NUMERIC(1), @NCMMDISCPER NUMERIC (10,3),@CCMMCC CHAR(2),  
		@NCMDNETWOTAX NUMERIC (10,2), @NCMDEXCLTAX NUMERIC(10,2), @NCALCDISCOUNTAMT NUMERIC(14,2),@NDISCOUNTAMT NUMERIC(14,2),  
		@NPAYMODECRAMT NUMERIC(10,2), @NPAYMODETOTAMT NUMERIC(10,2),@CITEMNAME VARCHAR(100),@NATDCHARGES NUMERIC(10,2),
		@CERRITEMCODE VARCHAR(50),@NMINPRICE NUMERIC(10,2),@NITEMNET NUMERIC(10,2),@DTSQLERRORMSG VARCHAR(MAX) ,
		@DTSQL NVARCHAR(MAX),@NTOTAMOUNT NUMERIC(14,2),@NGROSSVAL NUMERIC(10,2),@CCHK_TABLE VARCHAR(50),
		@CCMMTABLE VARCHAR(500),@CCMDTABLE VARCHAR(500),@CPAYMODETABLE VARCHAR(500),@CFILTERCONDITION VARCHAR(1000)   
	 DECLARE @ERRMSS VARCHAR(MAX)
	 
	 IF OBJECT_ID('#ERROR','U') IS NOT NULL
		DROP TABLE #ERROR
	
	 SELECT @ERRMSS AS ERRMSS INTO #ERROR	
	 
	 SET @CFILTERCONDITION=' CM_ID='''+@CMEMOID+''''
	 
 	 INSERT MIRROR_SYNCH_LOG (XN_TYPE,DEPT_ID,MEMO_ID,ERRMSG,LAST_UPDATE)
	 SELECT 'SLS',A.location_Code/*LEFT(@CMEMOID,2)*//*Rohit 07-11-2024*/ AS DEPT_ID,A.CM_ID,'MISMATCH BETWEEN BILL MASTER SUBTOTAL :'+
	 LTRIM(RTRIM(STR((ISNULL(A.SUBTOTAL,0)+ISNULL(A.SUBTOTAL_R,0)),10,2)))+' & DETAIL '+LTRIM(RTRIM(STR(ISNULL(B.NET,0),10,2))) AS ERRMSG,
	 GETDATE() AS LAST_UPDATE
	 FROM CMM01106  A (NOLOCK)
	 LEFT OUTER JOIN
	 (SELECT A.CM_ID,SUM(NET) AS NET FROM CMD01106 A (NOLOCK)
	  WHERE A.CM_ID=@CMEMOID
	  GROUP BY A.CM_ID
	 ) B ON A.CM_ID=B.CM_ID
	 WHERE A.CM_ID=@CMEMOID
	 AND ABS((ISNULL(A.SUBTOTAL,0)+ISNULL(A.SUBTOTAL_R,0))-ISNULL(B.NET,0))>1
	 
	 INSERT MIRROR_SYNCH_LOG (XN_TYPE,DEPT_ID,MEMO_ID,ERRMSG,LAST_UPDATE)
	 SELECT 'SLS',A.location_Code/*LEFT(@CMEMOID,2)*//*Rohit 07-11-2024*/ AS DEPT_ID,A.CM_ID,'NET AMOUNT :'+LTRIM(RTRIM(STR(A.NET_AMOUNT,14,2)))+' SHOULD BE EQUAL TO THE SUM OF ALL PAYMENT MODES :'+LTRIM(RTRIM(STR(ISNULL(B.AMOUNT,0),14,2))),
	 GETDATE() AS LAST_UPDATE
	 FROM CMM01106 A (NOLOCK)
	 LEFT OUTER JOIN
	 (SELECT A.MEMO_ID,SUM(AMOUNT) AS AMOUNT FROM  PAYMODE_XN_DET A 
	  WHERE A.MEMO_ID=@CMEMOID AND XN_TYPE='SLS' GROUP BY A.MEMO_ID) B ON A.CM_ID=B.MEMO_ID
	 WHERE A.CM_ID=@CMEMOID AND A.NET_AMOUNT<>ISNULL(B.AMOUNT,0) 
	 
	 --EXEC SP3S_REVALIDATE_GST @CMEMOID,@CERRMSGGST=@ERRMSS OUTPUT
  --   IF ISNULL(@ERRMSS,'')<>''
  --   BEGIN
		-- INSERT MIRROR_SYNCH_LOG (XN_TYPE,DEPT_ID,MEMO_ID,ERRMSG,LAST_UPDATE)
		-- SELECT 'SLS',LEFT(@CMEMOID,2) AS DEPT_ID,A.CM_ID,@ERRMSS,
		-- GETDATE() AS LAST_UPDATE
		-- FROM CMM01106 A (NOLOCK) WHERE CM_ID=@CMEMOID
  --   END		

END_PROC:  
	 
END  
--*************************************** END OF PROCEDURE VALIDATEXN_MIRROR_SLS_BATCH_SINGLE
