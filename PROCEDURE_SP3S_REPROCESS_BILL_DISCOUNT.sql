CREATE PROCEDURE DBO.SP3S_REPROCESS_BILL_DISCOUNT
(
 @CXN_TYPE VARCHAR(10)='PUR',
 @CMEMO_ID VARCHAR(100),
 @NSPID varchar(40)=''
,@ERRMSG VARCHAR(MAX) OUTPUT
)
AS
BEGIN
 BEGIN TRY
       
       DECLARE @CTMPMASTERTABLE VARCHAR(100),@CTMPDETAILTABLE VARCHAR(100),
       @NTOTAL_DISCOUNT_AMOUNT NUMERIC(10,2),@NITEM_DISCOUNT_AMOUNT NUMERIC(10,2),@DTSQL NVARCHAR(MAX),
       @NTOTALDIFF NUMERIC(10,2),@CIN_VALUE NUMERIC(10,2),
       @NNEWDIFF NUMERIC(10,2),@NPREVDIFF NUMERIC(10,2),@CTEMPDBNAME VARCHAR(100)

	   SET @CTEMPDBNAME = ''
       SET @NPREVDIFF=0
       
       IF @CXN_TYPE='PUR'
       BEGIN
           SET @CTMPMASTERTABLE='PUR_PIM01106_UPLOAD'
           SET @CTMPDETAILTABLE='PUR_PID01106_UPLOAD'
     
      
		   SET @DTSQL=N' SELECT   @NTOTAL_DISCOUNT_AMOUNT= ISNULL(DISCOUNT_AMOUNT,0)  FROM '+@CTMPMASTERTABLE+' A WHERE SP_ID='''+LTRIM(RTRIM((@NSPID)))+''''
		   EXEC SP_EXECUTESQL @DTSQL,N'@NTOTAL_DISCOUNT_AMOUNT NUMERIC(10,2) OUTPUT ',@NTOTAL_DISCOUNT_AMOUNT=@NTOTAL_DISCOUNT_AMOUNT OUTPUT
		   PRINT @DTSQL 
	       
	      
		   LBLCALCULATE: 
	         
		   SET @DTSQL=N' SELECT  @NITEM_DISCOUNT_AMOUNT= SUM(ISNULL(PIMDISCOUNTAMOUNT,0))  FROM '+@CTMPDETAILTABLE+' A WHERE SP_ID='''+LTRIM(RTRIM((@NSPID)))+''''
		   EXEC SP_EXECUTESQL @DTSQL,N'@NITEM_DISCOUNT_AMOUNT NUMERIC(10,2) OUTPUT ',@NITEM_DISCOUNT_AMOUNT=@NITEM_DISCOUNT_AMOUNT OUTPUT
		   PRINT @DTSQL   
	         
			SET @NNEWDIFF=ABS( ISNULL(@NTOTAL_DISCOUNT_AMOUNT,0)-ISNULL(@NITEM_DISCOUNT_AMOUNT,0))
	        
			IF ISNULL(@NPREVDIFF,0)=ISNULL(@NNEWDIFF,0)
			GOTO END_PROC
	        
			SET @NTOTALDIFF=ABS( ISNULL(@NTOTAL_DISCOUNT_AMOUNT,0)-ISNULL(@NITEM_DISCOUNT_AMOUNT,0))*100
	        
		   IF (@NTOTAL_DISCOUNT_AMOUNT=0   OR @NTOTALDIFF=0)
		   GOTO END_PROC
	      
	     
	      
		  IF ISNULL(@NTOTAL_DISCOUNT_AMOUNT,0)>ISNULL(@NITEM_DISCOUNT_AMOUNT,0)
			  SET @CIN_VALUE=.01
		  ELSE
			  SET @CIN_VALUE=-.01
	          
	    
			SET @DTSQL=N';WITH CTE AS
			(SELECT A.*,SR=ROW_NUMBER() OVER (ORDER BY ROW_ID)
			 FROM  '+@CTMPDETAILTABLE+' A WHERE SP_ID='''+LTRIM(RTRIM((@NSPID)))+'''
			 ) 
	         
			 UPDATE CTE SET PIMDISCOUNTAMOUNT=PIMDISCOUNTAMOUNT+'+RTRIM(LTRIM(STR(@CIN_VALUE,10,2)))+' WHERE SR<='''+STR(@NTOTALDIFF)+''''
		   EXEC SP_EXECUTESQL @DTSQL
		   PRINT @DTSQL
	       
		  --SET @NPREVDIFF=@NNEWDIFF
		  --GOTO LBLCALCULATE  
		  
		  GOTO END_PROC
     END
     ELSE IF @CXN_TYPE='WSL'
     BEGIN
         
		  SELECT  @NTOTAL_DISCOUNT_AMOUNT= ISNULL(DISCOUNT_AMOUNT,0)  FROM #tMstTable-- (NOLOCK)
		  
	      SELECT  @NITEM_DISCOUNT_AMOUNT= SUM(ISNULL(INMDISCOUNTAMOUNT,0))  FROM #tDetTable-- (NOLOCK)
		  
	      SET @NNEWDIFF=ABS( ISNULL(@NTOTAL_DISCOUNT_AMOUNT,0)-ISNULL(@NITEM_DISCOUNT_AMOUNT,0))
	       
		  IF ISNULL(@NPREVDIFF,0)=ISNULL(@NNEWDIFF,0)
			 GOTO END_PROC 
			 
			 SET @NTOTALDIFF=ABS( ISNULL(@NTOTAL_DISCOUNT_AMOUNT,0)-ISNULL(@NITEM_DISCOUNT_AMOUNT,0))*100
	        
		  IF (@NTOTAL_DISCOUNT_AMOUNT=0   OR @NTOTALDIFF=0)
		      GOTO END_PROC

		  IF ISNULL(@NTOTAL_DISCOUNT_AMOUNT,0)>ISNULL(@NITEM_DISCOUNT_AMOUNT,0)
			  SET @CIN_VALUE=.01
		  ELSE
			  SET @CIN_VALUE=-.01

			;WITH CTE AS
			(
			 SELECT A.*,SR=ROW_NUMBER() OVER (ORDER BY ROW_ID)
			 FROM  #tdEtTable  A
			 ) 
			 UPDATE CTE SET INMDISCOUNTAMOUNT=INMDISCOUNTAMOUNT+RTRIM(LTRIM(STR(@CIN_VALUE,10,2))) WHERE SR<=@NTOTALDIFF
			
			EXEC SP_EXECUTESQL @DTSQL
		   
		  
		  GOTO END_PROC
     
     END
     ELSE IF @CXN_TYPE IN('PRT')
     BEGIN
           SET @CTMPMASTERTABLE='PRT_RMM01106_UPLOAD'
           SET @CTMPDETAILTABLE='PRT_RMD01106_UPLOAD'
     		
		   --SET @CTMPMASTERTABLE	= @CTEMPDBNAME +'TEMP_RMM01106_'+LTRIM(RTRIM(STR(@NSPID)))
		   --SET @CTMPDETAILTABLE	= @CTEMPDBNAME + 'TEMP_RMD01106_'+LTRIM(RTRIM(STR(@NSPID)))
    
		   SET @DTSQL=N' SELECT   @NTOTAL_DISCOUNT_AMOUNT= ISNULL(DISCOUNT_AMOUNT,0)  FROM '+@CTMPMASTERTABLE+' A WHERE SP_ID='''+LTRIM(RTRIM((@NSPID)))+''''
		   EXEC SP_EXECUTESQL @DTSQL,N'@NTOTAL_DISCOUNT_AMOUNT NUMERIC(10,2) OUTPUT ',@NTOTAL_DISCOUNT_AMOUNT=@NTOTAL_DISCOUNT_AMOUNT OUTPUT
		   PRINT @DTSQL 
	       
		  LBLCALCULATE_PRT: 
	      
	      IF @CXN_TYPE='PRT'	
		  BEGIN   
			   SET @DTSQL=N' SELECT  @NITEM_DISCOUNT_AMOUNT= SUM(ISNULL(RMMDISCOUNTAMOUNT,0))  FROM '+@CTMPDETAILTABLE+' A  WHERE SP_ID='''+LTRIM(RTRIM((@NSPID)))+''''
			   EXEC SP_EXECUTESQL @DTSQL,N'@NITEM_DISCOUNT_AMOUNT NUMERIC(10,2) OUTPUT ',@NITEM_DISCOUNT_AMOUNT=@NITEM_DISCOUNT_AMOUNT OUTPUT
			   PRINT @DTSQL 
		  END  
	      
			SET @NNEWDIFF=ABS( ISNULL(@NTOTAL_DISCOUNT_AMOUNT,0)-ISNULL(@NITEM_DISCOUNT_AMOUNT,0))
	        
			IF ISNULL(@NPREVDIFF,0)=ISNULL(@NNEWDIFF,0)
			GOTO END_PROC
	        
			SET @NTOTALDIFF=ABS( ISNULL(@NTOTAL_DISCOUNT_AMOUNT,0)-ISNULL(@NITEM_DISCOUNT_AMOUNT,0))*100
	        
		   IF (@NTOTAL_DISCOUNT_AMOUNT=0   OR @NTOTALDIFF=0)
		   GOTO END_PROC
	      
	     
	      
		  IF ISNULL(@NTOTAL_DISCOUNT_AMOUNT,0)>ISNULL(@NITEM_DISCOUNT_AMOUNT,0)
			  SET @CIN_VALUE=.01
		  ELSE
			  SET @CIN_VALUE=-.01
	          
	      
			SET @DTSQL=N';WITH CTE AS
			(SELECT A.*,SR=ROW_NUMBER() OVER (ORDER BY ROW_ID)
			 FROM  '+@CTMPDETAILTABLE+' A 
			 WHERE SP_ID='''+LTRIM(RTRIM((@NSPID)))+'''
			 ) 
	         
			 UPDATE CTE SET RMMDISCOUNTAMOUNT=RMMDISCOUNTAMOUNT+'+RTRIM(LTRIM(STR(@CIN_VALUE,10,2)))+' WHERE SR<='''+STR(@NTOTALDIFF)+''''
		   EXEC SP_EXECUTESQL @DTSQL
		   PRINT @DTSQL
	       
		  --SET @NPREVDIFF=@NNEWDIFF
		  --GOTO LBLCALCULATE_PRT  
		  
		  GOTO END_PROC
     
     END
     ELSE IF @CXN_TYPE IN('WSR')
     BEGIN
           		--LTRIM(RTRIM(STR(@NSPID)))
		   SET @CTMPMASTERTABLE	= 'WSR_CNM01106_UPLOAD'
		   SET @CTMPDETAILTABLE	= 'WSR_CND01106_UPLOAD'
    
		   SET @DTSQL=N' SELECT   @NTOTAL_DISCOUNT_AMOUNT= ISNULL(DISCOUNT_AMOUNT,0)  FROM '+@CTMPMASTERTABLE+' A WHERE SP_ID='''+LTRIM(RTRIM((@NSPID)))+''''
		   EXEC SP_EXECUTESQL @DTSQL,N'@NTOTAL_DISCOUNT_AMOUNT NUMERIC(10,2) OUTPUT ',@NTOTAL_DISCOUNT_AMOUNT=@NTOTAL_DISCOUNT_AMOUNT OUTPUT
		   PRINT @DTSQL 
	       
		   LBLCALCULATE_WSR: 
	      
	      IF @CXN_TYPE='WSR'	
		  BEGIN   
			   SET @DTSQL=N' SELECT  @NITEM_DISCOUNT_AMOUNT= SUM(ISNULL(CNMDISCOUNTAMOUNT,0))  FROM '+@CTMPDETAILTABLE+' A WHERE SP_ID='''+LTRIM(RTRIM((@NSPID)))+''''
			   EXEC SP_EXECUTESQL @DTSQL,N'@NITEM_DISCOUNT_AMOUNT NUMERIC(10,2) OUTPUT ',@NITEM_DISCOUNT_AMOUNT=@NITEM_DISCOUNT_AMOUNT OUTPUT
			   PRINT @DTSQL 
		  END  
	      
			SET @NNEWDIFF=ABS( ISNULL(@NTOTAL_DISCOUNT_AMOUNT,0)-ISNULL(@NITEM_DISCOUNT_AMOUNT,0))
	        
			IF ISNULL(@NPREVDIFF,0)=ISNULL(@NNEWDIFF,0)
			GOTO END_PROC
	        
			SET @NTOTALDIFF=ABS( ISNULL(@NTOTAL_DISCOUNT_AMOUNT,0)-ISNULL(@NITEM_DISCOUNT_AMOUNT,0))*100
	        
		   IF (@NTOTAL_DISCOUNT_AMOUNT=0   OR @NTOTALDIFF=0)
				GOTO END_PROC
	      
	     
	      
		  IF ISNULL(@NTOTAL_DISCOUNT_AMOUNT,0)>ISNULL(@NITEM_DISCOUNT_AMOUNT,0)
			  SET @CIN_VALUE=.01
		  ELSE
			  SET @CIN_VALUE=-.01
	          
	      
			SET @DTSQL=N';WITH CTE AS
			(SELECT A.*,SR=ROW_NUMBER() OVER (ORDER BY ROW_ID)
			 FROM  '+@CTMPDETAILTABLE+' A 
			 WHERE SP_ID='''+LTRIM(RTRIM((@NSPID)))+'''
			 ) 
	         
			 UPDATE CTE SET CNMDISCOUNTAMOUNT=CNMDISCOUNTAMOUNT+'+RTRIM(LTRIM(STR(@CIN_VALUE,10,2)))+' WHERE SR<='''+STR(@NTOTALDIFF)+''''
		   EXEC SP_EXECUTESQL @DTSQL
		   PRINT @DTSQL
	       
		  --SET @NPREVDIFF=@NNEWDIFF
		  --GOTO LBLCALCULATE_WSR 
		  
		  GOTO END_PROC
     
     END
    

END TRY
BEGIN CATCH
  SET @ERRMSG =' SPID : '+LTRIM(RTRIM((@NSPID)))+' || ERROR IN PROCEDURE || SP3S_REPROCESS_BILL_DISCOUNT ERROR MESSAGE || '+ ERROR_MESSAGE();
END CATCH

END_PROC:
END