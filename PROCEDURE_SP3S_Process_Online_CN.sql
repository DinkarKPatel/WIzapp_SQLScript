CREATE PROC SP3S_Process_Online_CN
 (
  @nMode int
 ,@Cust_Code varchar (100)
 ,@cLocID varchar(100)
 ,@cUnknownPara VARCHAR(5)=''
 ,@cCNID varchar(100)=''
 )
--WITH ENCRYPTION  
AS
BEGIN
  SET NOCOUNT ON
  DECLARE @MESSAGE VARCHAR(1000)
    
  SET @MESSAGE='0'
  IF @nMode=1
     --Show Pending CN of the customer
     BEGIN
       IF LEN(ISNULL(@cCNID,''))=0
           --ALL CN
           SELECT O.CN_ID,C.CM_NO,C.CM_DT,ABS(P.AMOUNT) AS AMOUNT,0 [BIT]
		   FROM ONLINE_CN_REDEEMPTION O WITH (NOLOCK)
		   JOIN CMM01106 C WITH (NOLOCK) ON O.CN_ID=C.CM_ID
		   JOIN PAYMODE_XN_DET P WITH (NOLOCK) ON O.CN_ID=P.MEMO_ID --AND P.XN_TYPE='SLS'
		   LEFT JOIN PAYMODE_XN_DET CN WITH (NOLOCK) ON O.CN_ID=CN.ADJ_MEMO_ID --AND CN.XN_TYPE!='SLS'
		   WHERE P.PAYMODE_CODE='0000004'--CN Issued
		   AND LTRIM(RTRIM(ISNULL(O.Redeemed_AT,''))) IN ('',LTRIM(RTRIM(@cLocID)))
		   AND LTRIM(RTRIM(C.CUSTOMER_CODE))=LTRIM(RTRIM(@Cust_Code))
		   AND LTRIM(RTRIM(ISNULL(O.Redeemption_Bill_NO,'')))=''--Not Redeemed
		   AND C.CANCELLED=0 AND ISNULL(CN.ADJ_MEMO_ID,'')=''
		   AND SUBSTRING(C.CM_NO,5,1)='N'
       ELSE
           --Specific CN
           SELECT O.CN_ID,C.CM_NO,C.CM_DT,ABS(P.AMOUNT) AS AMOUNT,0 [BIT]
		   FROM ONLINE_CN_REDEEMPTION O WITH (NOLOCK)
		   JOIN CMM01106 C WITH (NOLOCK) ON O.CN_ID=C.CM_ID
		   JOIN PAYMODE_XN_DET P WITH (NOLOCK) ON O.CN_ID=P.MEMO_ID --AND P.XN_TYPE='SLS'
		   LEFT JOIN PAYMODE_XN_DET CN WITH (NOLOCK) ON O.CN_ID=CN.ADJ_MEMO_ID --AND CN.XN_TYPE!='SLS'
		   WHERE P.PAYMODE_CODE='0000004'--CN Issued
		   AND LTRIM(RTRIM(ISNULL(O.Redeemed_AT,''))) IN ('',LTRIM(RTRIM(@cLocID)))
		   AND LTRIM(RTRIM(C.CUSTOMER_CODE))=LTRIM(RTRIM(@Cust_Code))
		   AND LTRIM(RTRIM(C.CM_NO))=LTRIM(RTRIM(@cCNID))--Specific
           AND LTRIM(RTRIM(ISNULL(O.Redeemption_Bill_NO,'')))=''--Not Redeemed
		   AND C.CANCELLED=0 AND ISNULL(CN.ADJ_MEMO_ID,'')=''
		   AND SUBSTRING(C.CM_NO,5,1)='N'
		   
       IF @@ERROR!=0
          SET @MESSAGE='1001'
     END
  
  
  ELSE IF @nMode=2
     BEGIN
       BEGIN TRAN
       UPDATE O SET O.Redeemed_AT=U.Dept_ID,O.Last_Updated=GETDATE()
       FROM ONLINE_CN_REDEEMPTION O WITH (ROWLOCK)
       JOIN UPLOAD_Online_CN_Redeemption U (NOLOCK) ON O.CN_ID=U.CN_ID
       WHERE U.Dept_ID=@cLocID

       --IF Online_CN_Reemption updated successfully;
       --then only delete from Upload_Online_CN_Redeemption
       IF @@ERROR!=0
          BEGIN
            ROLLBACK TRAN
            SET @MESSAGE='2001'
          END
       ELSE
          BEGIN
            DELETE UPLOAD_Online_CN_Redeemption WITH (ROWLOCK) WHERE Dept_ID=@cLocID
            IF @@ERROR!=0
               BEGIN
                 ROLLBACK TRAN
                 SET @MESSAGE='2002'
               END
            ELSE
               COMMIT TRAN   
          END  
     END         
  
  
  ELSE IF @nMode=3
     --Update Online_CN_Redeemption Set CN_ID for the Bill No 
     --from UPLOAD_Online_CN_Redeemption
     BEGIN
       BEGIN TRAN
       UPDATE O SET O.Redeemption_Bill_NO=U.CM_NO
				   ,O.Redeemption_Bill_Date=U.CM_DT
				   ,O.Redeemed_AT=U.Dept_ID
				   ,O.Last_Updated=GETDATE()
				   ,o.cm_id=u.cm_id
       FROM Online_CN_Redeemption O WITH (ROWLOCK)
       JOIN UPLOAD_Online_CN_Redeemption U (NOLOCK) ON O.CN_ID=U.CN_ID
       WHERE U.Dept_ID=@cLocID
       
       --IF Online_CN_Reemption updated successfully
       --then only delete from Upload_Online_CN_Redeemption
      IF @@ERROR!=0
      BEGIN
          ROLLBACK TRAN
          SET @MESSAGE='3001'
      END
      ELSE
      BEGIN
         DELETE UPLOAD_Online_CN_Redeemption WITH (ROWLOCK) WHERE Dept_ID=@cLocID
         IF @@ERROR!=0
         BEGIN
             ROLLBACK TRAN
             SET @MESSAGE='3002'
         END
         ELSE
			 COMMIT TRAN   
      END
  END 


  --Started - 10 Sep 2018: AS IT IS FOUND MISSING	
  ELSE IF @nMode=4--Cancel the payment/billing to redeem the CN-ID
     BEGIN
       BEGIN TRAN
       UPDATE O SET O.Redeemed_AT=NULL,O.Last_Updated=GETDATE()
       FROM ONLINE_CN_REDEEMPTION O WITH (ROWLOCK)
       WHERE ISNULL(O.Redeemed_AT,'')=@cLocID AND O.CN_ID=@cCNID

       IF @@ERROR!=0
          BEGIN
            ROLLBACK TRAN
            SET @MESSAGE='4001'
          END
       ELSE
          COMMIT TRAN   
     END         
  --Finished - ADDED 10 Sep 2018: AS IT IS FOUND MISSING	
  
  RETURN @MESSAGE	         
  SET NOCOUNT OFF
END
