CREATE PROC [DBO].SP_JOBWORK_RECIEVE_6    
@NQUERYID INT,                          
@CWHERE NVARCHAR(4000)='',            
@NMODE INT=0,    
@BWIP BIT=0,    
@NISSUE_MODE BIT=0,    
@cLocID VARCHAR(5)=''    
AS                          
BEGIN       
 
    
  DECLARE @CCMD NVARCHAR(MAX)    
   SET @CCMD=N'SELECT receipt_id,receipt_no,receipt_dt FROM JOBWORK_RECEIPT_MST (NOLOCK) WHERE 1=1 '+REPLACE(@CWHERE,'WHERE',' AND ') + ' ORDER BY RECEIPT_DT,RECEIPT_NO'               
  PRINT @CCMD            
  EXEC SP_EXECUTESQL @CCMD            
    
END 
