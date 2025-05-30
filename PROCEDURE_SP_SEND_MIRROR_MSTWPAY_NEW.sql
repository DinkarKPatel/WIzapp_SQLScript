CREATE PROCEDURE DBO.SP_SEND_MIRROR_MSTWPAY_NEW
(
   @CTARGETLOCID VARCHAR(5)=''
)
AS
-----WITH ENCRYPTION
BEGIN
  BEGIN TRY
   --DECLARE LOCAL VARIABLE
   DECLARE @CERRORMSG VARCHAR(MAX)
          ,@NSTEP INT,@NSPID INT,@CCURDEPTID VARCHAR(5),@CHODEPTID VARCHAR(5)
          ,@CSLSSETLUPD VARCHAR(50),@CHOUSRMSTLASTUPDATE VARCHAR(50),@BPROCEED BIT
          ,@NMEMONOLEN INT,@CRETCMD NVARCHAR(MAX),@CMEMOID VARCHAR(100),@CXNTYPE VARCHAR(50)
          ,@BEMPHEADSUPDATED BIT,@BHOLOC BIT,@NLOCTYPE INT,@BPURLOC BIT
          ,@CTABLENAME VARCHAR(200),@CTEMPTABLENAME VARCHAR(500),@CKEYFIELD VARCHAR(200)
          ,@CJOINSTR VARCHAR(1000),@CFILTERCONDITION VARCHAR(100)
          ,@CTMPLOCUSERSTABLENAME VARCHAR(500),@CTMPUSERTABLENAME VARCHAR(500),@CTMPUSERROLETABLENAME VARCHAR(500)
          ,@CTMPBINUSERTABLENAME VARCHAR(500)
   DECLARE @TXNSSENDINFO AS TABLE(ORG_TABLENAME VARCHAR(100),TMP_TABLENAME VARCHAR(100),ERRMSG VARCHAR(MAX),SP_ID INT)
   SET @NSPID = @@SPID
   SET @NSTEP = 1;
   
   
   --SELECT LOCAUTION
   SELECT @CCURDEPTID = VALUE FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID'
   SELECT @CHODEPTID = VALUE FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID'
   
   SET @NSTEP = 2;


	IF @CCURDEPTID<>@CHODEPTID
	BEGIN
		SELECT '' AS LAST_UPDATE,'' AS ERRMSG
		RETURN
	END		
	
    IF ISNULL(@CTARGETLOCID,'') = ''
       BEGIN
            SET @NSTEP = 4;
			SET @CERRORMSG = 'TARGET LOCATION ID SHOULD NOT BE BLANK'
			RETURN
       END
				
	    SELECT @CERRORMSG='',@BPROCEED=1,@NMEMONOLEN=10,@CRETCMD='',@CMEMOID='',@CXNTYPE='MSTWPAY',@BEMPHEADSUPDATED=0
				
		
		SET @NSTEP=5		
		SELECT @NLOCTYPE=LOC_TYPE,@BPURLOC=PUR_LOC FROM DBO.LOCATION (NOLOCK) WHERE DEPT_ID=@CCURDEPTID
        --INSERT ORIGINAL TABLE IN XNINFO TABLE
       
    
		----INSERT INTO EMP_MST TABLE-----------
		SET @NSTEP=7
		SET @CTABLENAME='EMP_MST'
	   SELECT  DISTINCT   'MSTWPAY_EMP_MST_MIRROR' AS TARGET_TABLENAME,EMP_MST.*,1 AS PICK_FROM_CURRENT_DB 
	   FROM [EMP_MST]  (NOLOCK)  WHERE  DEPT_ID=@CTARGETLOCID  OR MARKETING_EMP = 1 



		----INSERT INTO DESIGNATION TABLE-----------
		SET @NSTEP=9
		SET @CTABLENAME='EMP_DESIG'
		SELECT  DISTINCT   'MSTWPAY_EMP_DESIG_MIRROR' AS TARGET_TABLENAME,EMP_DESIG.*,1 AS PICK_FROM_CURRENT_DB 
		FROM [EMP_DESIG]  (NOLOCK)  JOIN EMP_MST SRC ON SRC.DESIG_ID=EMP_DESIG.DESIG_ID 
		WHERE  SRC.DEPT_ID=@CTARGETLOCID  OR SRC.MARKETING_EMP = 1 


		----INSERT INTO EMP_DEPARTMENT TABLE-----------
		SET @NSTEP=11
		SET @CTABLENAME='EMP_DEPARTMENT'

		 SELECT  DISTINCT   'MSTWPAY_EMP_DEPARTMENT_MIRROR' AS TARGET_TABLENAME,EMP_DEPARTMENT.*,1 AS PICK_FROM_CURRENT_DB 
		 FROM [EMP_DEPARTMENT]  (NOLOCK)  
		 JOIN EMP_MST SRC ON SRC.DEPARTMENT_ID=EMP_DEPARTMENT.DEPARTMENT_ID 
		 WHERE  SRC.DEPT_ID=@CTARGETLOCID  OR SRC.MARKETING_EMP = 1 

		
		----INSERT INTO EMP_SHIFT_LOC TABLE-----------
		SET @NSTEP=13
		SET @CTABLENAME='EMP_SHIFT_LOC'
	     SELECT  DISTINCT   'MSTWPAY_EMP_SHIFT_LOC_MIRROR' AS TARGET_TABLENAME,EMP_SHIFT_LOC.*,1 AS PICK_FROM_CURRENT_DB 
		 FROM EMP_SHIFT_LOC  (NOLOCK)  WHERE  DEPT_ID=@CTARGETLOCID

		----INSERT INTO EMP_SHIFTS TABLE-----------
		SET @NSTEP=15
		SET @CTABLENAME='EMP_SHIFTS'

		  SELECT  DISTINCT   'MSTWPAY_EMP_SHIFTS_MIRROR' AS TARGET_TABLENAME,EMP_SHIFTS.*,1 AS PICK_FROM_CURRENT_DB 
		 FROM [EMP_SHIFTS]  (NOLOCK)  
		 JOIN 
		(   
		   SELECT SHIFT_ID FROM   [EMP_MST]  (NOLOCK)  WHERE  DEPT_ID=@CTARGETLOCID  OR MARKETING_EMP = 1  
		   UNION 
		  SELECT SHIFT_ID  FROM EMP_SHIFT_LOC  (NOLOCK)  WHERE  DEPT_ID=@CTARGETLOCID 
		 )SRC ON SRC.SHIFT_ID=EMP_SHIFTS.SHIFT_ID 



		----INSERT INTO EMP_SALARY_MST TABLE-----------
		SET @NSTEP=17
		SET @CTABLENAME='EMP_SALARY_MST'

		 SELECT  DISTINCT   'MSTWPAY_EMP_SALARY_MST_MIRROR' AS TARGET_TABLENAME,EMP_SALARY_MST.*,1 AS PICK_FROM_CURRENT_DB 
		 FROM [EMP_SALARY_MST]  (NOLOCK)  JOIN EMP_MST SRC ON SRC.SALARY_PROFILE_ID=EMP_SALARY_MST.SALARY_PROFILE_ID 
		 WHERE  SRC.DEPT_ID=@CTARGETLOCID  OR SRC.MARKETING_EMP = 1  


		----INSERT INTO AREA TABLE-----------
		SET @NSTEP=19
		SET @CTABLENAME='AREA'

		  SELECT  DISTINCT   'MSTWPAY_AREA_MIRROR' AS TARGET_TABLENAME,AREA.*,1 AS PICK_FROM_CURRENT_DB  
		  FROM [AREA]  (NOLOCK)  JOIN EMP_MST SRC ON SRC.AREA_CODE=AREA.AREA_CODE  
		  WHERE  SRC.DEPT_ID=@CTARGETLOCID  OR SRC.MARKETING_EMP = 1  


		   ----INSERT INTO CITY TABLE-----------
	    SET @NSTEP=21		
		SET @CTABLENAME='CITY'

		  SELECT  DISTINCT   'MSTWPAY_CITY_MIRROR' AS TARGET_TABLENAME,CITY.*,1 AS PICK_FROM_CURRENT_DB  FROM CITY
		  JOIN [AREA]  (NOLOCK)  ON AREA.city_code =CITY .CITY_CODE 
		  JOIN EMP_MST SRC ON SRC.AREA_CODE=AREA.AREA_CODE  
		  WHERE  SRC.DEPT_ID=@CTARGETLOCID  OR SRC.MARKETING_EMP = 1  

		
	
		----INSERT INTO STATE TABLE-----------
		SET @NSTEP=23
		SET @CTABLENAME='STATE'

		 SELECT  DISTINCT   'MSTWPAY_STATE_MIRROR' AS TARGET_TABLENAME,STATE.*,1 AS PICK_FROM_CURRENT_DB  FROM STATE
		 JOIN CITY ON CITY.state_code =state .state_code 
		  JOIN [AREA]  (NOLOCK)  ON AREA.city_code =CITY .CITY_CODE 
		  JOIN EMP_MST SRC ON SRC.AREA_CODE=AREA.AREA_CODE  
		  WHERE  SRC.DEPT_ID=@CTARGETLOCID  OR SRC.MARKETING_EMP = 1  

		
		----INSERT INTO REGIONM TABLE-----------
		SET @NSTEP=25
		SET @CTABLENAME='REGIONM'

		 SELECT  DISTINCT   'MSTWPAY_REGIONM_MIRROR' AS TARGET_TABLENAME,REGIONM.*,1 AS PICK_FROM_CURRENT_DB  FROM REGIONM
		 JOIN STATE ON state .region_code =regionM .region_code
		 JOIN CITY ON CITY.state_code =state .state_code 
		  JOIN [AREA]  (NOLOCK)  ON AREA.city_code =CITY .CITY_CODE 
		  JOIN EMP_MST SRC ON SRC.AREA_CODE=AREA.AREA_CODE  
		  WHERE  SRC.DEPT_ID=@CTARGETLOCID  OR SRC.MARKETING_EMP = 1 
  

  END TRY
  BEGIN CATCH
  SELECT [ERRMSG]='PROCEDURE SP_SEND_MIRROR_MSTWPAY : STEP: '+STR(@NSTEP)+' LINE NO. :'+
		ISNULL(LTRIM(RTRIM(STR(ERROR_LINE()))),'NULL LINE')+'MSG :'+ISNULL(ERROR_MESSAGE(),'NULL MSG') 
  END CATCH

   PROC_END:
  SELECT ISNULL(@CERRORMSG,'') AS ERRMSG
  
END
