CREATE PROCEDURE SP3S_POSTSALE_JOBWORK_RECEIPT  
(  
  @DFROM_DT DATETIME  
 ,@DTO_DT DATETIME  
 ,@AGENCYCODE VARCHAR(20)=''  
 ,@CANCELLED NUMERIC(1)=2--0 FOR UN-CANCELLED 1 FOR UN-CANCELLED 2 FOR ALL  
 ,@LOC VARCHAR(5)=''  
   
)  
--WITH ENCRYPTION  
AS  
BEGIN     
     
    SELECT A.RECEIPT_NO ,A.RECEIPT_ID AS MEMO_ID,  
    RECEIPT_DT=CONVERT(VARCHAR,A.RECEIPT_DT,105) ,    
 SUM(B.QUANTITY) AS QUANTITY,A.SUBTOTAL,A.TDS ,A.OTHER_CHARGES ,sum(b.job_rate) AS NET_AMOUNT ,  
 --,A.NET_AMOUNT ,  
 D.AGENCY_NAME ,  
 F.JOB_NAME,   
 CANCELLED=CASE WHEN A.CANCELLED<>0 THEN 'CANCELLED' ELSE '' END,  
 L.DEPT_NAME ,A.COMPANY_CODE,CONVERT(VARCHAR,A.LAST_UPDATE,105) AS LAST_UPDATE,  
 A.SENT_TO_HO ,A.FIN_YEAR ,A.RECEIVED_BY,A.CHECKED_BY,A.REF_NO ,A.ROUND_OFF ,A.MODE,   
 U.USERNAME,A.BIN_ID  
 FROM POST_SALES_JOBWORK_RECEIPT_MST A (NOLOCK)   
 LEFT OUTER  JOIN POST_SALES_JOBWORK_RECEIPT_DET B (NOLOCK) ON A.RECEIPT_ID = B.RECEIPT_ID   
 LEFT OUTER JOIN POST_SALES_JOBWORK_issue_DET I on B.ref_row_id= I.row_id
 LEFT OUTER  JOIN PRD_AGENCY_MST D (NOLOCK) ON A.AGENCY_CODE = D.AGENCY_CODE    
 LEFT OUTER  JOIN JOBS F (NOLOCK) ON F.JOB_CODE = I.JOB_CODE   
 LEFT OUTER JOIN USERS U (NOLOCK) ON A.USER_CODE=U.USER_CODE   
 JOIN LOCATION L (NOLOCK) ON L.DEPT_ID=A.DEPT_ID   
 WHERE A.RECEIPT_DT BETWEEN @DFROM_DT AND @DTO_DT    
 AND (@CANCELLED=2 OR A.CANCELLED=@CANCELLED)     
  AND (@AGENCYCODE='' OR  A.AGENCY_CODE=@AGENCYCODE)  
  AND (@LOC='' OR A.location_Code=@LOC)   
 GROUP BY A.RECEIPT_NO ,A.RECEIPT_DT ,  
 D.AGENCY_NAME ,  
 F.JOB_NAME,A.CANCELLED,A.SUBTOTAL,A.TDS ,A.OTHER_CHARGES ,A.NET_AMOUNT ,L.DEPT_NAME ,A.COMPANY_CODE,A.LAST_UPDATE,  
 A.SENT_TO_HO ,A.RECEIPT_ID,A.FIN_YEAR ,A.RECEIVED_BY,A.CHECKED_BY,A.REF_NO ,A.ROUND_OFF ,A.MODE, U.USERNAME,A.BIN_ID  
 ORDER BY A.RECEIPT_DT                                
              
  
END  
--END PROCEDURE SP3S_POSTSALE_JOBWORK_RECEIPT  