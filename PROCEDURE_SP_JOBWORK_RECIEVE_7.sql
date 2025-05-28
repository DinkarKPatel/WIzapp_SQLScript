create PROC [DBO].SP_JOBWORK_RECIEVE_7  
@NQUERYID INT,                        
@CWHERE NVARCHAR(4000)='',          
@NMODE INT=0,  
@BWIP BIT=0,  
@NISSUE_MODE BIT=0,  
@cLocID VARCHAR(5)=''  
AS                        
BEGIN     
 --(dinkar) Replace  left(memoid,2) to Location_code 
  
  DECLARE @CCMD NVARCHAR(100)  
   SELECT Q.ISSUE_ID AS MEMO_ID            
 FROM JOBWORK_RECEIPT_MST A (NOLOCK)                           
 JOIN JOBWORK_RECEIPT_DET B (NOLOCK) ON A.RECEIPT_ID = B.RECEIPT_ID              
 JOIN JOBWORK_ISSUE_DET M (NOLOCK) ON M.ROW_ID = B.REF_ROW_ID           
 JOIN JOBWORK_ISSUE_MST Q (NOLOCK) ON Q.ISSUE_ID = M.ISSUE_ID                   
 WHERE A.RECEIPT_ID = @CWHERE          
  
END 
