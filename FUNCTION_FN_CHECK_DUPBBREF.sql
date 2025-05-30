CREATE FUNCTION FN_CHECK_DUPBBREF(@CVMID VARCHAR(40),@CVDID VARCHAR(40))  
RETURNS VARCHAR(2000)  
AS  
BEGIN  
 DECLARE @CERRORMSG VARCHAR(2000),@CDUPREFNO VARCHAR(200),@CBILLTYPE VARCHAR(10),@CVCHNO VARCHAR(20),@DVCHDT DATETIME,  
 @NPAMT1 NUMERIC(10,2),@NPAMT2 NUMERIC(10,2),@CDUPACNAME VARCHAR(400),@CDEBTORHEADS VARCHAR(MAX) 
  
   
 IF @CVMID=''  
  SELECT TOP 1 @CVMID=VM_ID FROM VD01106 (NOLOCK) WHERE VD_ID=@CVDID   
   
 SET @CERRORMSG=''  
 
   
 DECLARE @TBBREF TABLE (REF_NO VARCHAR(100),X_TYPE VARCHAR(5),AC_CODE CHAR(10),AMOUNT NUMERIC(20,4))  
   
 DECLARE @TOTHERBBREF TABLE (REF_NO VARCHAR(100),AC_CODE CHAR(10),PENDING_AMT NUMERIC(20,4),VOUCHER_NO VARCHAR(20),VOUCHER_DT DATETIME)  
   
 SELECT @CBILLTYPE=BILL_TYPE FROM VM01106 WHERE VM_ID=@CVMID  
   
 INSERT @TBBREF (REF_NO,X_TYPE ,AC_CODE,AMOUNT)  
 SELECT A.REF_NO,A.X_TYPE,AC_CODE,A.AMOUNT FROM BILL_BY_BILL_REF A  
 JOIN VD01106 B ON A.VD_ID=B.VD_ID    
 JOIN VM01106 C ON C.VM_ID=B.VM_ID  
 WHERE B.VM_ID=@CVMID  AND c.cancelled=0
 AND ISNULL(b.ref_vd_id,'')='' 
      
 IF @CBILLTYPE NOT IN ('PRT','PUR','PBM','SLS','ARC')  
 BEGIN  
  IF EXISTS (SELECT REF_NO FROM @TBBREF GROUP BY REF_NO,AC_CODE,X_TYPE HAVING COUNT(*)>1)  
  BEGIN  
    SELECT TOP 1 @CDUPREFNO=REF_NO,@CDUPACNAME=AC_NAME FROM (SELECT  AC_CODE,REF_NO FROM @TBBREF GROUP BY AC_CODE,REF_NO HAVING COUNT(*)>1) A  
    JOIN LM01106 B ON A.AC_CODE=B.AC_CODE  
    SET @CERRORMSG='(0)DUPLICATE ENTRY OF BILL NO. '+@CDUPREFNO+' FOR LEDGER :'+@CDUPACNAME+' NOT ALLOWED IN THE CURRENT VOUCHER'  
  END   
 END  
   
 IF @CERRORMSG=''  
 BEGIN  
  INSERT @TOTHERBBREF (REF_NO,AC_CODE,PENDING_AMT,VOUCHER_DT)  
  SELECT C.REF_NO,D.AC_CODE,SUM(CASE WHEN C.X_TYPE='CR' THEN -C.AMOUNT ELSE C.AMOUNT END) AS PENDING_AMT,  
  MIN(E.VOUCHER_DT) AS VOUCHER_DT  
  FROM BILL_BY_BILL_REF A  
  JOIN VD01106 B ON A.VD_ID=B.VD_ID    
  JOIN BILL_BY_BILL_REF C ON C.REF_NO=A.REF_NO  
  JOIN VD01106 D ON D.VD_ID=C.VD_ID AND D.AC_CODE=B.AC_CODE  
  JOIN VM01106 E ON E.VM_ID=D.VM_ID  
  WHERE B.VM_ID=@CVMID AND D.VM_ID<>@CVMID AND E.CANCELLED=0  
  GROUP BY C.REF_NO,D.AC_CODE  
    
  IF EXISTS (SELECT TOP 1 REF_NO FROM @TOTHERBBREF)  
  BEGIN  
   SELECT TOP 1 @CDUPREFNO=A.REF_NO,@NPAMT1=A.PENDING_AMT,@DVCHDT=VOUCHER_DT,@NPAMT2=B.PENDING_AMT FROM   
   (SELECT REF_NO,AC_CODE,VOUCHER_DT,SUM(PENDING_AMT) AS PENDING_AMT FROM  @TOTHERBBREF  
    GROUP BY REF_NO,AC_CODE,VOUCHER_DT)  A  
   JOIN   
   (SELECT REF_NO,AC_CODE,SUM(CASE WHEN X_TYPE='DR' THEN AMOUNT ELSE -AMOUNT END) AS PENDING_AMT  
    FROM @TBBREF GROUP BY REF_NO,AC_CODE) B ON A.AC_CODE=B.AC_CODE AND A.REF_NO=B.REF_NO  
   WHERE (CASE WHEN B.PENDING_AMT>0 THEN 'DR' ELSE 'CR' END)=(CASE WHEN A.PENDING_AMT>0 THEN 'DR' ELSE 'CR' END)  
   AND A.PENDING_AMT<>0  
     
   IF ISNULL(@CDUPREFNO,'')<>''  
    SET @CERRORMSG='(1)DUPLICATE ENTRY OF BILL NO. '+@CDUPREFNO+'('+STR(@NPAMT2,10,2)+') FOUND IN OTHER VOUCHER DATED :'+CONVERT(VARCHAR,@DVCHDT,105)+'('+STR(@NPAMT1,10,2)+')'  
     
   IF ISNULL(@CDUPREFNO,'')=''   
   BEGIN  
    SELECT TOP 1 @CDUPREFNO=A.REF_NO,@DVCHDT=A.VOUCHER_DT FROM   
    (SELECT REF_NO,AC_CODE,VOUCHER_DT,SUM(PENDING_AMT) AS PENDING_AMT FROM  @TOTHERBBREF  
     GROUP BY REF_NO,AC_CODE,VOUCHER_DT) A  
    JOIN   
    (SELECT REF_NO,AC_CODE,SUM(CASE WHEN X_TYPE='DR' THEN AMOUNT ELSE -AMOUNT END) AS PENDING_AMT  
     FROM @TBBREF GROUP BY REF_NO,AC_CODE) B ON A.AC_CODE=B.AC_CODE AND A.REF_NO=B.REF_NO  
    WHERE A.PENDING_AMT=0     
  
    IF ISNULL(@CDUPREFNO,'')<>''  
     SET @CERRORMSG='(2)DUPLICATE ENTRY OF BILL NO. '+@CDUPREFNO+' FOUND IN OTHER VOUCHER DATED :'+CONVERT(VARCHAR,@DVCHDT,105)      
   END  
  END    
 END   
   
 RETURN @CERRORMSG   
END