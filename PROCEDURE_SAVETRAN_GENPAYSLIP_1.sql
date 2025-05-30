create PROCEDURE SAVETRAN_GENPAYSLIP_1
(                      
 @NUPDATEMODE INT=1,
 @CREFID VARCHAR(20),                       
 @NYEAR INT,                       
 @NMONTH INT,
 @CFINYEAR VARCHAR(10),
 @CUSERCODE CHAR(7)='0000000',
 @NSPID INT=0,
 @cLocId char(4)=''                   
)      
--WITH ENCRYPTION                
AS                      
BEGIN                      
                       
 --LOG ABSENT STATUS - 1.WEEKLY OFF,2.ABSENT,3.LEAVE,4.BIRTHDAY OFF                      
                       
BEGIN TRY                      
                       
	 DECLARE @CERRORMSG VARCHAR(MAX),@CTEMPMASTERTABLE VARCHAR(200),@CTEMPMASTERTABLENAME VARCHAR(200),
	 @CTEMPDETAILTABLE VARCHAR(200),@CTEMPDETAILTABLENAME VARCHAR(200),
	 @CTEMPDBNAME VARCHAR(400),@CMASTERTABLENAME VARCHAR(200),@CDETAILTABLENAME VARCHAR(200),
	 @NSTEP INT,@CCMD NVARCHAR(MAX),@CLOCATIONID VARCHAR(5),@CPAYSLIPID VARCHAR(20),@CEMPID CHAR(7),
	 @DPAYSLIPDATE DATETIME,@NMONTHDAYS INT,@NPREVMONTH INT,@DFROMDT DATETIME,@NGROSSSALARY NUMERIC(10,2),
	 @NWORKINGDAYS INT,@DTODT DATETIME,@NSALARYDAYS NUMERIC(10,2),@NNEXTMONTH INT,
	 @CESIPCT VARCHAR(20),@NESIPCT NUMERIC(7,3),@CPFPCT VARCHAR(20),@NPFPCT NUMERIC(7,3),@NTOTALEARNINGS NUMERIC(10,2),
	 @CPAYSLIPVERSION VARCHAR(2),@NLOANEMIAMT NUMERIC(10,2),@NPFBASE NUMERIC(10,2),@NESIBASE NUMERIC(10,2),@BPTENABLED BIT,
	 @NPTBASE NUMERIC(10,2),@NPTAMOUNT NUMERIC(5,0),@NEMPLOYERPFAMT NUMERIC(10,2),@NEMPLOYERPFPCT NUMERIC(7,3),
	 @NEMPLOYERESIAMT NUMERIC(10,2),@NEMPLOYERESIPCT NUMERIC(7,3),@NPFAMT NUMERIC(10,2),
	 @NNEXTYEAR INT

	 
	 SET @NSTEP = 10
	 
	
		SET @CLOCATIONID=@CLOCID
	
	-- TEMPORARY DATABASE Discarded now onwards as per Meeting on 30-10-2020 mentioned in Client issues List
	SET @CTEMPDBNAME = '' 
	 
	 SET @NSTEP = 20
	
	 SET @CMASTERTABLENAME = 'EMP_PAYSLIP_MST'  
	 SET @CDETAILTABLENAME = 'EMP_PAYSLIP_DET'  
	 
	 IF @NUPDATEMODE = 1
		SET @NSPID = @@SPID
	 
	 SET @NSTEP = 30	 
	 
	 SET @CTEMPMASTERTABLENAME = 'TEMP_'+@CMASTERTABLENAME+'_'+LTRIM(RTRIM(STR(@NSPID)))  
	 SET @CTEMPDETAILTABLENAME = 'TEMP_'+@CDETAILTABLENAME+'_'+LTRIM(RTRIM(STR(@NSPID)))  
	 
	 SET @CTEMPMASTERTABLE = @CTEMPDBNAME + @CTEMPMASTERTABLENAME  
	 SET @CTEMPDETAILTABLE = @CTEMPDBNAME + @CTEMPDETAILTABLENAME  
	 
	 SET @NSTEP = 40	 
	 
	 SELECT TOP 1 @CEMPID=EMP_ID,@NGROSSSALARY=BASIC_SALARY FROM EMP_MST (NOLOCK) WHERE REF_ID=@CREFID
	 
	 DECLARE @TLEAVESINFO TABLE (OPS NUMERIC(10,2),ABSENT_DAYS NUMERIC(10,2),LEAVE_DR_FL NUMERIC(10,2),
	 LEAVE_DR_HL NUMERIC(10,2),LEAVE_DR_SL NUMERIC(10,2),LEAVE_CR_FL NUMERIC(10,2),LEAVE_CR_HL NUMERIC(10,2),
	 LEAVE_CR_SL NUMERIC(10,2),LEAVES_TAKEN NUMERIC(10,2),LEAVES_CREDITED NUMERIC(10,2),CBS  NUMERIC(10,2),
	 LWP_DAYS NUMERIC(10,2),PRESENT_DAYS NUMERIC(10,2),WEEKLY_OFF_TAKEN NUMERIC(10,2),SALARY_DAYS NUMERIC(10,2),
	 WORKING_DAYS NUMERIC(10,2),ATD_EARLY_GOING NUMERIC(10,2),ATD_LATE_COMING NUMERIC(10,2),ATD_HALFDAY NUMERIC(10,2),
	 ERRMSG VARCHAR(MAX) )	 

	 DECLARE @TRETMSG TABLE (MEMO_ID VARCHAR(40),ERRMSG VARCHAR(MAX))
	 
--	 IF @NUPDATEMODE=1 AND NOT EXISTS (SELECT TOP 1 A.PAY_ID FROM HR_EMP_PAY A
--	 JOIN EMP_MST B ON A.EMP_ID=B.EMP_ID WHERE A.EMP_ID=@CEMPID
--	 AND XN_MONTH=@NMONTH AND XN_YEAR=@NYEAR)
--	 BEGIN
--		SET @CERRORMSG='ADDITION/DEDUCTION DETAILS NOT DEFINED FOR THE EMPLOYEE ID :'+@CREFID+CHAR(13)+CHAR(10)+
--					   ' FOR THE MONTH :'+LTRIM(RTRIM(STR(@NMONTH)))+' AND YEAR :'+LTRIM(RTRIM(STR(@NYEAR)))
--		GOTO END_PROC			   
--						
--	 END	
--	 
--	 
	 
	 BEGIN TRANSACTION                      
	 
	 IF @NUPDATEMODE=1
	 BEGIN
		 SET @NSTEP = 50
		 
		 PRINT 'STEP#'+LTRIM(RTRIM(STR(@NSTEP)))
		 INSERT @TLEAVESINFO
		 EXEC SP_EMP_PAYSLIP_LEAVESCALC_MAIN @CEMPID,@NYEAR,@NMONTH
		 
		 
		 IF EXISTS (SELECT TOP 1 * FROM @TLEAVESINFO WHERE ERRMSG<>'')
		 BEGIN
			SELECT @CERRORMSG=ERRMSG FROM @TLEAVESINFO
			GOTO END_PROC
		 END	

		 IF ISNULL(@CLOCATIONID,'')=''
		 BEGIN
			SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' LOCATION ID CAN NOT BE BLANK  '  
			GOTO END_PROC    
		 END
			  
		 SET @NSTEP = 60
		 
		 PRINT 'STEP#'+LTRIM(RTRIM(STR(@NSTEP)))
		 EXEC GETNEXTKEY @CMASTERTABLENAME,'PAYSLIP_ID',10,@CLOCATIONID,1,@CFINYEAR,2,@CPAYSLIPID OUTPUT   
		 
		 SET @NSTEP = 70			 
		 
		 PRINT 'STEP#'+LTRIM(RTRIM(STR(@NSTEP)))
		 SET @NNEXTMONTH=(CASE WHEN @NMONTH=12 THEN 1 ELSE @NMONTH+1 END)
		 SET @NNEXTYEAR=(CASE WHEN @NMONTH=12 THEN @NYEAR+1 ELSE @NYEAR END)
		 		 
		 SET @DTODT = CONVERT(DATETIME,LTRIM(RTRIM(STR(@NNEXTYEAR)))+'-'+LTRIM(RTRIM(STR(@NNEXTMONTH)))+'-01')
		 
		 SET @DFROMDT = CONVERT(DATETIME,LTRIM(RTRIM(STR(@NYEAR)))+'-'+LTRIM(RTRIM(STR(@NMONTH)))+'-01')
		 
		 SET @DPAYSLIPDATE = CONVERT(DATETIME,CONVERT(VARCHAR,GETDATE(),110))
		 
	 
		 SELECT @NMONTHDAYS= DATEDIFF(DD,@DFROMDT,@DTODT)
		 
		 UPDATE EMP_PAYSLIP_MST SET CANCELLED=1 WHERE EMP_ID=@CEMPID AND PAYSLIP_MONTH=@NMONTH AND PAYSLIP_YEAR=@NYEAR
		 
		 PRINT 'STEP#'+LTRIM(RTRIM(STR(@NSTEP)))
		 SET @NSTEP = 80
		 
		 INSERT EMP_PAYSLIP_MST	( PAYSLIP_ID, EMP_ID, PAYSLIP_DATE, PAYSLIP_MONTH, 
		 PAYSLIP_YEAR, BASIC_SALARY, EARNINGS, DEDUCTIONS, WORK_DAYS, LOAN_ADJ, 
		 NET_SALARY, USER_CODE, EDIT_USER_CODE, CANCELLED_USER_CODE, MODIFIED_ON, 
		 CANCELLED_ON, PAYSLIP_STATUS, CANCELLED, FINALIZED, MONTH_DAYS, SALARY_DAYS, 
		 ATD_PRESENT, ATD_HALFDAY, ATD_EARLY_GOING, ATD_LATE_COMING, ATD_ABSENT, 
		 LEAVE_DR_FL, LEAVE_DR_HL, LEAVE_DR_SL, LEAVE_CR_FL, LEAVE_CR_HL, LEAVE_CR_SL, 
		 LEAVE_OPS, LEAVE_CBS, ARREAR_AMT, LWP_DAYS, EMPLOYER_PF_AMOUNT, 
		 EMPLOYER_ESI_AMOUNT, ABSENT_DAYS ) 
		 SELECT @CPAYSLIPID AS PAYSLIP_ID,EMP_ID,@DPAYSLIPDATE AS PAYSLIP_DATE,
		 @NMONTH AS PAYSLIP_MONTH,@NYEAR AS PAYSLIP_YEAR,
		 A.BASIC_SALARY,0 AS EARNINGS,0 AS DEDUCTIONS,B.WORKING_DAYS AS WORK_DAYS,
		 0 AS LOAN_ADJ,0 AS NET_SALARY,@CUSERCODE AS USER_CODE,@CUSERCODE AS EDIT_USER_CODE,
		 @CUSERCODE AS CANCELLED_USER_CODE,'' AS MODIFIED_ON,'' AS CANCELLED_ON,
		 1 AS PAYSLIP_STATUS,0 AS CANCELLED,0 AS FINALIZED,@NMONTHDAYS AS MONTH_DAYS,
		 B.SALARY_DAYS,B.PRESENT_DAYS AS ATD_PRESENT,B.ATD_HALFDAY,B.ATD_EARLY_GOING, 
		 B.ATD_LATE_COMING,B.ABSENT_DAYS AS ATD_ABSENT,B.LEAVE_DR_FL,B.LEAVE_DR_HL,B.LEAVE_DR_SL,
		 B.LEAVE_CR_FL,B.LEAVE_CR_HL,B.LEAVE_CR_SL,B.OPS AS LEAVE_OPS,B.CBS AS LEAVE_CBS,
		 0 AS ARREAR_AMT,B.LWP_DAYS,(CASE WHEN PF_ENABLED=1 THEN A.PF_AMOUNT ELSE 0 END) AS EMPLOYER_PF_AMOUNT,
		 0 AS EMPLOYER_ESI_AMOUNT,B.ABSENT_DAYS FROM EMP_MST A JOIN @TLEAVESINFO B ON 1=1 
		 WHERE REF_ID=@CREFID
		 
		 SET @NSTEP = 90
		 SELECT @NSALARYDAYS=SALARY_DAYS FROM @TLEAVESINFO
		 
		 SELECT TOP 1 @CESIPCT=VALUE FROM CONFIG WHERE CONFIG_OPTION='ESI'
		 
		 IF ISNULL(@CESIPCT,'')<>''
			SET @NESIPCT=@CESIPCT
		 ELSE
			SET @NESIPCT=0

		 SELECT TOP 1 @CPFPCT=VALUE FROM CONFIG WHERE CONFIG_OPTION='PF_EMPLOYEE_SHARE'
		 
		 IF ISNULL(@CPFPCT,'')<>''
			SET @NPFPCT=@CPFPCT
		 ELSE
			SET @NPFPCT=0					
		 
		 SET @NSTEP = 95
		 INSERT EMP_PAYSLIP_DET	( ROW_ID, PAYSLIP_ID, PAY_ID, LOAN_ID, PAY_TYPE, AMOUNT, ORG_AMOUNT )
		 SELECT  @CLOCATIONID+CONVERT(VARCHAR(40),NEWID()) AS ROW_ID,@CPAYSLIPID AS PAYSLIP_ID,
		 A.PAY_ID,'' AS LOAN_ID, PAY_TYPE,AMOUNT,AMOUNT AS ORG_AMOUNT 
		 FROM HR_EMP_PAY A
		 JOIN EMP_PAY B ON A.PAY_ID=B.PAY_ID
		 WHERE A.EMP_ID=@CEMPID AND A.PAY_ID NOT IN ('PAY0002','PAY0001','0000001','PAY0004','0000001')  
		 AND A.XN_MONTH=@NMONTH AND A.XN_YEAR=@NYEAR AND (PAY_TYPE<>2 OR A.PAY_ID='0000016')
		 UNION
 		 SELECT  @CLOCATIONID+CONVERT(VARCHAR(40),NEWID()) AS ROW_ID,@CPAYSLIPID AS PAYSLIP_ID,
		 A.PAY_ID,'' AS LOAN_ID, PAY_TYPE,(ISNULL(AMOUNT,0)/@NMONTHDAYS)*@NSALARYDAYS,ISNULL(AMOUNT,0) AS ORG_AMOUNT 
		 FROM EMP_SALARY_PROFILE A
		 JOIN EMP_PAY B ON A.PAY_ID=B.PAY_ID
		 WHERE A.EMP_ID=@CEMPID AND A.PAY_ID NOT IN ('PAY0002','PAY0001','0000016','PAY0004','0000001')   
		 AND PAY_TYPE=2 
		 

		 INSERT EMP_PAYSLIP_DET	( ROW_ID, PAYSLIP_ID, PAY_ID, LOAN_ID, PAY_TYPE, AMOUNT, ORG_AMOUNT )
		 SELECT  @CLOCATIONID+CONVERT(VARCHAR(40),NEWID()) AS ROW_ID,@CPAYSLIPID AS PAYSLIP_ID,
		 'PAY0004' AS PAY_ID, LOAN_ID,1 AS PAY_TYPE,EMI_AMOUNT,EMI_AMOUNT AS ORG_AMOUNT 
		 FROM EMP_LOAN_MST WHERE EMP_ID=@CEMPID AND 
		 (@DTODT<=DATEADD(MM,TENURE,LOAN_DATE) OR DATEADD(MM,TENURE,LOAN_DATE) BETWEEN @DFROMDT AND @DTODT)
		 AND SETTLED=0 AND LOAN_STATUS=1
		 AND ISNULL(APPROVED_AMOUNT,0)>0

		 SET @NSTEP = 98
		
		 IF EXISTS (SELECT TOP 1 PAY_ID FROM EMP_SALARY_PROFILE A WHERE EMP_ID=@CEMPID AND PAY_ID='0000001' AND AMOUNT<>0)
		 	 SET @BPTENABLED=1
		 ELSE
			 SET @BPTENABLED=0	 
		 	 
		 SELECT @NTOTALEARNINGS=SUM(AMOUNT) FROM EMP_PAYSLIP_DET
		 WHERE PAYSLIP_ID=@CPAYSLIPID AND PAY_TYPE=2
		 
		 SET @NTOTALEARNINGS=((@NGROSSSALARY/@NMONTHDAYS)*@NSALARYDAYS)+ISNULL(@NTOTALEARNINGS,0)
		 
		 SET @NESIBASE=@NTOTALEARNINGS
		 
		 SET @NPTBASE=@NESIBASE
		 
		 SET @NPTAMOUNT=(CASE WHEN @NPTBASE<5000 THEN 0 WHEN @NPTBASE BETWEEN 5000 AND 10000 THEN 175 ELSE 200 END)
		 
		 IF @NGROSSSALARY<15000
		 BEGIN
			 SET @NPFBASE= (@NGROSSSALARY/@NMONTHDAYS)*@NSALARYDAYS
			 SET @NPFAMT = ROUND(ISNULL(@NPFBASE,0)*ISNULL(@NPFPCT,0)/100,0) 
		 END
		 ELSE
		 	 SET @NPFAMT = ROUND((1800*@NSALARYDAYS)/@NMONTHDAYS,0)
		 
		 INSERT EMP_PAYSLIP_DET	( ROW_ID, PAYSLIP_ID, PAY_ID, LOAN_ID, PAY_TYPE, AMOUNT, ORG_AMOUNT )
		 SELECT  @CLOCATIONID+CONVERT(VARCHAR(40),NEWID()) AS ROW_ID,@CPAYSLIPID AS PAYSLIP_ID,
		 'PAY0002' AS PAY_ID,'' AS LOAN_ID,1 AS PAY_TYPE,ROUND(ISNULL(@NESIBASE,0)*ISNULL(@NESIPCT,0)/100,0) AS AMOUNT,@NESIBASE*@NESIPCT/100 
		 AS ORG_AMOUNT 
		 FROM EMP_MST A WHERE A.EMP_ID=@CEMPID AND ESI_ENABLED=1
		 UNION
		 SELECT  @CLOCATIONID+CONVERT(VARCHAR(40),NEWID()) AS ROW_ID,@CPAYSLIPID AS PAYSLIP_ID,
		 'PAY0001' AS PAY_ID,'' AS LOAN_ID,1 AS PAY_TYPE,@NPFAMT AS AMOUNT,@NPFAMT AS ORG_AMOUNT 
		 FROM EMP_MST A WHERE A.EMP_ID=@CEMPID AND PF_ENABLED=1
		 UNION
		 SELECT  @CLOCATIONID+CONVERT(VARCHAR(40),NEWID()) AS ROW_ID,@CPAYSLIPID AS PAYSLIP_ID,
		 '0000001' AS PAY_ID,'' AS LOAN_ID,1 AS PAY_TYPE,@NPTAMOUNT AS AMOUNT,@NPTAMOUNT
		 AS ORG_AMOUNT 
		 FROM EMP_MST A WHERE A.EMP_ID=@CEMPID AND @BPTENABLED=1
		 
		 SELECT TOP 1 @NEMPLOYERPFPCT=VALUE FROM CONFIG WHERE CONFIG_OPTION='PF_EMPLOYER_SHARE'

		 SELECT TOP 1 @NEMPLOYERESIPCT=VALUE FROM CONFIG WHERE CONFIG_OPTION='EMPLOYER_ESI'

		 SELECT @NEMPLOYERPFAMT=ROUND(@NPFBASE*@NEMPLOYERPFPCT/100,0),
				@NEMPLOYERESIAMT=ROUND(@NESIBASE*@NEMPLOYERESIPCT/100,0)
		 
	 END
	 ELSE
	 BEGIN	 
		 SET @NSTEP = 100
		 
		 EXEC UPDATEMASTERXN   
		 @CSOURCEDB = @CTEMPDBNAME  
	   , @CSOURCETABLE = @CTEMPMASTERTABLENAME  
	   , @CDESTDB  = ''  
	   , @CDESTTABLE = @CMASTERTABLENAME  
	   , @CKEYFIELD1 = 'PAYSLIP_ID'
	   , @BALWAYSUPDATE = 1  
		
		 SET @NSTEP = 110
		 EXEC UPDATEMASTERXN   
		 @CSOURCEDB = @CTEMPDBNAME  
	   , @CSOURCETABLE = @CTEMPDETAILTABLENAME  
	   , @CDESTDB  = ''  
	   , @CDESTTABLE = @CDETAILTABLENAME
	   , @CKEYFIELD1 = 'ROW_ID'
	   , @BALWAYSUPDATE = 1	   	 
		
		SET @NSTEP = 115
		SET @CCMD=N'SELECT @CPAYSLIPID=PAYSLIP_ID FROM '+@CTEMPMASTERTABLENAME
		EXEC SP_EXECUTESQL @CCMD,N'@CPAYSLIPID VARCHAR(20) OUTPUT',@CPAYSLIPID=@CPAYSLIPID OUTPUT
	 END

     SET @NSTEP = 120
     
	 UPDATE A SET EARNINGS=B.EARNINGS,DEDUCTIONS=B.DEDUCTIONS,
	 BASIC_SALARY=(CASE WHEN @NUPDATEMODE=1 THEN (A.BASIC_SALARY/@NMONTHDAYS)*@NSALARYDAYS ELSE A.BASIC_SALARY END),
	 EMPLOYER_PF_AMOUNT=(CASE WHEN  @NUPDATEMODE=1 AND PF_ENABLED=1 THEN @NEMPLOYERPFAMT ELSE EMPLOYER_PF_AMOUNT END),
	 EMPLOYER_ESI_AMOUNT=(CASE WHEN  @NUPDATEMODE=1 AND ESI_ENABLED=1 THEN @NEMPLOYERESIAMT ELSE EMPLOYER_ESI_AMOUNT END)

	 FROM EMP_PAYSLIP_MST A JOIN (SELECT A.PAYSLIP_ID,SUM(CASE WHEN PAY_TYPE=2 THEN AMOUNT ELSE 0 END) AS EARNINGS,
		   SUM(CASE WHEN PAY_TYPE=1 THEN AMOUNT ELSE 0 END) AS DEDUCTIONS,
		   SUM(CASE WHEN A.PAY_ID='PAY0001' THEN AMOUNT ELSE 0 END) AS PF_AMOUNT,
		   SUM(CASE WHEN A.PAY_ID='PAY0002' THEN AMOUNT ELSE 0 END) AS ESI_AMOUNT FROM  	
		   EMP_PAYSLIP_DET A JOIN EMP_PAYSLIP_MST B ON A.PAYSLIP_ID=B.PAYSLIP_ID
		   WHERE A.PAYSLIP_ID=@CPAYSLIPID GROUP BY A.PAYSLIP_ID) B
	 ON B.PAYSLIP_ID=A.PAYSLIP_ID
	 JOIN EMP_MST C ON C.EMP_ID=A.EMP_ID
	 
	 SET @NSTEP = 130
	 UPDATE EMP_PAYSLIP_MST SET NET_SALARY=BASIC_SALARY+EARNINGS-DEDUCTIONS
	 WHERE PAYSLIP_ID=@CPAYSLIPID
	 	  
     GOTO END_PROC           

END TRY
	 
BEGIN CATCH
	
	PRINT 'UNTRAPPED ERROR'		
	SELECT @CERRORMSG='PROCEDURE SAVETRAN_GENPAYSLIP_1 STEP :'+STR(ISNULL(@NSTEP,0))+ ' LINE NO. :'+
	ISNULL(LTRIM(RTRIM(STR(ERROR_LINE()))),'NULL LINE')+'MSG :'+ISNULL(ERROR_MESSAGE(),'NULL MSG')
	
	GOTO END_PROC
END CATCH

			
END_PROC:

	IF @@TRANCOUNT>0
	BEGIN
		IF ISNULL(@CERRORMSG,'')=''
			COMMIT TRANSACTION
		ELSE
			ROLLBACK 	
	END	

    INSERT @TRETMSG    
    SELECT @CPAYSLIPID AS MEMO_ID,@CERRORMSG    

    SELECT * FROM @TRETMSG    

END               
--*************************************** END OF PROCEDURE SAVETRAN_GENPAYSLIP_1
