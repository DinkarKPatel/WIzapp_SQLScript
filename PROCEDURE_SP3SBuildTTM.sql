create PROCEDURE SP3SBUILDTTM  
(  
  @CXNID   VARCHAR(50)  
 ,@NUPDATEMODE NUMERIC(2)  
  ,@CINSJOINSTR   VARCHAR(1000)=''  
 ,@CWHERECLAUSE VARCHAR(1000)=''  
 ,@NSPID   INT=0  
 ,@cRfTableName  varchar(500)=''
 ,@CERRMSG  VARCHAR(MAX) OUTPUT  
)  
AS  
BEGIN  
/*  
XNTYPE FILTER IS REQUIRED DURING DELETION FROM RFOPT TABLE  
,THE INSERTED XN_ID IS THAT OF TRANSFER TO MAIN FROM RAW MATERIAL.  
*/  
 DECLARE @CCMD NVARCHAR(MAX),@CSTEP VARCHAR(10),@CFILTER VARCHAR(1000),@CDELSTR VARCHAR(1000),@CDELJOINSTR VARCHAR(500)  
   
BEGIN TRY  
  
 DECLARE @BBUILDRFOPT BIT  
   
 EXEC SP3S_CHKRFOPT_BUILD @BBUILDRFOPT OUTPUT  
   
 IF @BBUILDRFOPT=0  
  RETURN  
  IF @cRfTableName=''  
 EXEC SP3S_RFDBTABLE 'TTM',@cXnID,@cRFTABLENAME OUTPUT  
   
 --START OF BUILD PROCESS FOR APPROVAL RETURN TRANSACTION 
 SET @CFILTER=(CASE WHEN @NUPDATEMODE IN(0,4) THEN '1=1' ELSE 'A.MEMO_ID='''+@CXNID+'''' END)+@CWHERECLAUSE      
  IF @NUPDATEMODE<>1  
  BEGIN  
   SET @CSTEP = 230
   
	   IF @NUPDATEMODE IN (3)	  
	   BEGIN 
			 SET @CCMD=N'UPDATE A SET TTM_QTY=A.TTM_QTY-B.TTM_QTY FROM 
			  '+@cRFTABLEName+' A
			  JOIN
			  ( 
				SELECT LEFT(A.MEMO_ID,2) AS DEPT_ID,    
				 A.MEMO_DT AS XN_DT,    
				 B.PRODUCT_CODE,    
				 SUM(ABS(B.QTY)) AS TTM_QTY,     
				 ,''000''  AS [BIN_ID] 
				FROM PRD_TRANSFER_MAIN_MST A (NOLOCK)    
				JOIN PRD_TRANSFER_MAIN_DET B (NOLOCK)ON A.MEMO_ID = B.MEMO_ID    
				'+@CINSJOINSTR+'  
				WHERE  A.CANCELLED = 0 AND '+@CFILTER +'
				GROUP BY GROUP BY LEFT(A.MEMO_ID,2) , A.MEMO_DT , B.PRODUCT_CODE 
				) B ON  A.PROduct_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id
				 ' 
	  
			  PRINT @CCMD   
			  EXEC SP_EXECUTESQL @CCMD  
		        
		        
				 SET @CCMD=N'UPDATE A SET TTM_QTY=A.TTM_QTY-B.TTM_QTY FROM 
				  '+@cRFTABLEName+' A
				  (
					SELECT LEFT(A.MEMO_ID,2) AS DEPT_ID,    
					 A.MEMO_DT AS XN_DT,    
					 B.PRODUCT_CODE,      
					 SUM(ABS(B.QUANTITY)) AS TTM_QTY,     
					 ''000''  AS [BIN_ID]
					FROM PPC_TRANSFER_TO_TRADING_MST A (NOLOCK)    
					JOIN PPC_TRANSFER_TO_TRADING_DET B (NOLOCK)ON A.MEMO_ID = B.MEMO_ID    
					'+@CINSJOINSTR+'  
					WHERE  A.CANCELLED = 0 AND '+@CFILTER  +'
					GROUP BY GROUP BY LEFT(A.MEMO_ID,2) , A.MEMO_DT , B.PRODUCT_CODE
				) B ON  A.PROduct_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id '
		  
			  PRINT @CCMD   
			  EXEC SP_EXECUTESQL @CCMD  
		        
		     
		        
				 SET @CCMD=N'UPDATE A SET TTM_QTY=A.TTM_QTY-B.TTM_QTY FROM 
				 '+@cRFTABLEName+' A
				 JOIN
				 (  
					 SELECT LEFT(A.MEMO_ID,2) AS DEPT_ID,      
					 A.MEMO_DT AS XN_DT,    
					 B.PRODUCT_CODE,    
					 SUM(ABS(B.QUANTITY))  AS TTM_QTY,      
					 ''000''  AS [BIN_ID]
					FROM TRANSFER_TO_TRADING_MST A (NOLOCK)    
					JOIN TRANSFER_TO_TRADING_DET B (NOLOCK)ON A.MEMO_ID = B.MEMO_ID    
					'+@CINSJOINSTR+'  
					WHERE  A.CANCELLED = 0 AND '+@CFILTER  +' 
					GROUP BY GROUP BY LEFT(A.MEMO_ID,2) , A.MEMO_DT , B.PRODUCT_CODE
				) B ON  A.PROduct_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
		  
			  PRINT @CCMD   
			  EXEC SP_EXECUTESQL @CCMD  
	   END  
    
  END  
    
  IF @NUPDATEMODE<>3  
  BEGIN  
   SET @CSTEP =  240  
      
      
       SET @CCMD=N'UPDATE A SET TTM_QTY=A.TTM_QTY+B.TTM_QTY FROM 
			  '+@cRFTABLEName+' A
			  JOIN
			  ( 
				SELECT LEFT(A.MEMO_ID,2) AS DEPT_ID,    
				 A.MEMO_DT AS XN_DT,    
				 B.PRODUCT_CODE,    
				 SUM(ABS(B.QTY)) AS TTM_QTY,     
				 ,''000''  AS [BIN_ID] 
				FROM PRD_TRANSFER_MAIN_MST A (NOLOCK)    
				JOIN PRD_TRANSFER_MAIN_DET B (NOLOCK)ON A.MEMO_ID = B.MEMO_ID    
				'+@CINSJOINSTR+'  
				WHERE  A.CANCELLED = 0 AND '+@CFILTER +'
				GROUP BY GROUP BY LEFT(A.MEMO_ID,2) , A.MEMO_DT , B.PRODUCT_CODE 
				) B ON  A.PROduct_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id
				 ' 
	  
			  PRINT @CCMD   
			  EXEC SP_EXECUTESQL @CCMD  
		        
		        
				 SET @CCMD=N'UPDATE A SET TTM_QTY=A.TTM_QTY+B.TTM_QTY FROM 
				  '+@cRFTABLEName+' A
				  (
					SELECT LEFT(A.MEMO_ID,2) AS DEPT_ID,    
					 A.MEMO_DT AS XN_DT,    
					 B.PRODUCT_CODE,      
					 SUM(ABS(B.QUANTITY)) AS TTM_QTY,     
					 ''000''  AS [BIN_ID]
					FROM PPC_TRANSFER_TO_TRADING_MST A (NOLOCK)    
					JOIN PPC_TRANSFER_TO_TRADING_DET B (NOLOCK)ON A.MEMO_ID = B.MEMO_ID    
					'+@CINSJOINSTR+'  
					WHERE  A.CANCELLED = 0 AND '+@CFILTER  +'
					GROUP BY GROUP BY LEFT(A.MEMO_ID,2) , A.MEMO_DT , B.PRODUCT_CODE
				) B ON  A.PROduct_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id '
		  
			  PRINT @CCMD   
			  EXEC SP_EXECUTESQL @CCMD  
		        
		     
		        
				 SET @CCMD=N'UPDATE A SET TTM_QTY=A.TTM_QTY+B.TTM_QTY FROM 
				 '+@cRFTABLEName+' A
				 JOIN
				 (  
					 SELECT LEFT(A.MEMO_ID,2) AS DEPT_ID,      
					 A.MEMO_DT AS XN_DT,    
					 B.PRODUCT_CODE,    
					 SUM(ABS(B.QUANTITY))  AS TTM_QTY,      
					 ''000''  AS [BIN_ID]
					FROM TRANSFER_TO_TRADING_MST A (NOLOCK)    
					JOIN TRANSFER_TO_TRADING_DET B (NOLOCK)ON A.MEMO_ID = B.MEMO_ID    
					'+@CINSJOINSTR+'  
					WHERE  A.CANCELLED = 0 AND '+@CFILTER  +' 
					GROUP BY GROUP BY LEFT(A.MEMO_ID,2) , A.MEMO_DT , B.PRODUCT_CODE
				) B ON  A.PROduct_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
		  
			  PRINT @CCMD   
			  EXEC SP_EXECUTESQL @CCMD  
      
      
      SET @CCMD=N'INSERT '+@cRFTABLEName+'   
      (DEPT_ID,XN_DT,PRODUCT_CODE ,TTM_QTY,BIN_ID)
      SELECT XN.DEPT_ID,XN.XN_DT,XN.PRODUCT_CODE ,XN.TTM_QTY,XN.BIN_ID 
      FROM
      (  
        SELECT LEFT(A.MEMO_ID,2) AS DEPT_ID,    
         A.MEMO_DT AS XN_DT,    
         B.PRODUCT_CODE,         
         SUM(ABS(B.QTY)) AS TTM_QTY,      
         ''000''  AS [BIN_ID]    
        FROM PRD_TRANSFER_MAIN_MST A (NOLOCK)    
        JOIN PRD_TRANSFER_MAIN_DET B (NOLOCK)ON A.MEMO_ID = B.MEMO_ID    
        '+@CINSJOINSTR+'  
        WHERE  A.CANCELLED = 0 AND '+@CFILTER  +' 
        GROUP BY LEFT(A.MEMO_ID,2) , A.MEMO_DT , B.PRODUCT_CODE
        ) XN
        LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
	    AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
	    WHERE b.product_code IS NULL '
  
      PRINT @CCMD   
      SELECT @CCMD
      EXEC SP_EXECUTESQL @CCMD  
        
        SET @CSTEP =  250
         SET @CCMD=N'INSERT '+@cRFTABLEName+'   
      (DEPT_ID,XN_DT,PRODUCT_CODE ,TTM_QTY,BIN_ID)  
        
        SELECT XN.DEPT_ID,XN.XN_DT,XN.PRODUCT_CODE ,XN.TTM_QTY,XN.BIN_ID  FROM 
        (
        SELECT LEFT(A.MEMO_ID,2) AS DEPT_ID,       
         A.MEMO_DT AS XN_DT,    
         B.PRODUCT_CODE,     
         SUM(ABS(B.QUANTITY)) AS TTM_QTY,     
         ''000''  AS [BIN_ID]
        FROM PPC_TRANSFER_TO_TRADING_MST A (NOLOCK)    
        JOIN PPC_TRANSFER_TO_TRADING_DET B (NOLOCK)ON A.MEMO_ID = B.MEMO_ID    
        '+@CINSJOINSTR+'  
        WHERE  A.CANCELLED = 0 AND '+@CFILTER +'
        GROUP BY LEFT(A.MEMO_ID,2) , A.MEMO_DT , B.PRODUCT_CODE
        ) XN
        LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
	    AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
	    WHERE b.product_code IS NULL ' 
  
      PRINT @CCMD   
      EXEC SP_EXECUTESQL @CCMD  
        
     
        
         SET @CCMD=N'INSERT '+@cRFTABLEName+'   
      (DEPT_ID,XN_DT,PRODUCT_CODE ,TTM_QTY,BIN_ID) 
      SELECT XN.DEPT_ID,XN.XN_DT,XN.PRODUCT_CODE ,XN.TTM_QTY,XN.BIN_ID FROM
      ( 
        SELECT LEFT(A.MEMO_ID,2) AS DEPT_ID,       
         A.MEMO_DT AS XN_DT,    
         B.PRODUCT_CODE,      
         SUM(ABS(B.QUANTITY)) AS XN_QTY,    
         ''000''  AS [BIN_ID]
        FROM TRANSFER_TO_TRADING_MST A (NOLOCK)    
        JOIN TRANSFER_TO_TRADING_DET B (NOLOCK)ON A.MEMO_ID = B.MEMO_ID    
        '+@CINSJOINSTR+'  
        WHERE  A.CANCELLED = 0 AND '+@CFILTER  +' 
        GROUP BY LEFT(A.MEMO_ID,2) ,A.MEMO_DT ,B.PRODUCT_CODE
        ) XN
         LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
	    AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
	    WHERE b.product_code IS NULL '
  
      PRINT @CCMD   
      EXEC SP_EXECUTESQL @CCMD  
  END  
 --END OF BUILD PROCESS FOR APPROVAL RETURN TRANSACTION  
END TRY  
BEGIN CATCH  
 SET @CERRMSG='SP3SBUILDTTM: STEP :'+@CSTEP+',ERROR :'+ERROR_MESSAGE()  
END CATCH   
  
ENDPROC:  
  
END  
