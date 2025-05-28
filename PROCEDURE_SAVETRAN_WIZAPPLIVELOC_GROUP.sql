create PROCEDURE SAVETRAN_WIZAPPLIVELOC_GROUP
(
  @NSPID INT,
  @CLOC_ID CHAR(4)
)

AS
BEGIN
--changes by Dinkar in location id varchar(4)..
    DECLARE @CCMD NVARCHAR(MAX),@CERRMSG AS VARCHAR(MAX),@NSTEP INT
       
        SET @NSTEP = 10              
		   IF ISNULL(@NSPID,'') = ''              
			  BEGIN              
				SET @CERRMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' SPID REQUIRED .....CANNOT PROCEED'              
				GOTO END_PROC                  
			  END
			  
		  SET @NSTEP = 20              
		   IF ISNULL(@CLOC_ID,'') = ''              
			  BEGIN              
				SET @CERRMSG = 'STEP- ' + LTRIM(STR(@CLOC_ID)) + ' MAJOR_DEPT_ID REQUIRED .....CANNOT PROCEED'              
				GOTO END_PROC                  
			  END
	          
          SET @NSTEP = 20
			 DELETE FROM WIZAPPLIVELOC_GROUP WHERE MAJOR_DEPT_ID=@CLOC_ID
			 SET @CCMD=N'INSERT INTO WIZAPPLIVELOC_GROUP (MAJOR_DEPT_ID,DEPT_ID)
						 SELECT MAJOR_DEPT_ID,DEPT_ID FROM TEMP_WIZAPPLIVELOC_GROUP_'+LTRIM(RTRIM(STR(@NSPID)))
	                     
			 PRINT @CCMD
			 EXEC SP_EXECUTESQL @CCMD 
	         
       
END_PROC:              
              
     SELECT @CERRMSG AS ERRMSG             
     SET @CERRMSG = 'PROCEDURE SAVETRAN_WIZAPPLIVELOC_GROUP: STEP- ' + LTRIM(STR(@NSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()              
         
  
END

--********************* END OF SAVETRAN_WIZAPPLIVELOC_GROUP**********************
