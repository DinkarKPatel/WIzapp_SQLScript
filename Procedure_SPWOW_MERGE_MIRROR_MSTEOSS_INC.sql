CREATE PROCEDURE SPWOW_MERGE_MIRROR_MSTEOSS_INC
(  
 @NMODE INT		----  0. CLEAR THE TEMP TABLES DATA
				----  1. UPDATE THE INFORMATION FOR ALL SCHEME SETUP MEMOS ONLY RELATED TO TARGET LOCATION
				----  2. UPDATE THE INFORMATION FOR ALL ACTIVE SCHEME SETUP TITLES ONLY RELATED TO TARGET LOCATION
				----  3. UPDATE THE DATA RELATED TO A GIVEN TITLE AT TARGET LOCATION	
)  
----WITH ENCRYPTION
AS  
BEGIN  
   
 BEGIN TRY  
	
  DECLARE @CERRORMSG VARCHAR(1000),@CCURDEPTID CHAR(2),@CHODEPTID CHAR(2),@CCMD NVARCHAR(MAX),
          @NSTEP INT,@CFILTERCONDITION VARCHAR(100),@CMEMOID varchar(50),@cSchemeRowId VARCHAR(100),
		  @CTEMPMASTERTABLENAME varchar(100),@CTEMPDETAILTABLENAME varchar(100),@CTEMPlocDETAILTABLENAME VARCHAR(200),
		  @CTEMPSCHEMESETUPSLABSDET varchar(100),@CTEMPSchemeSetupslsbcget varchar(100), 
		  @CTEMPSchemeSetupslsbcbuy varchar(100),@CTEMPSchemeSetupslsbcflat varchar(100),
		  @CTEMPwow_SchemeSetupparacombinationbuyflat varchar(100), @CTEMPSchemeSetupparacombinationconfig varchar(100), 
		  @CTEMPwow_SchemeSetup_para_combination_flat varchar(100), @CTEMPwow_SchemeSetup_para_combination_get varchar(100)

		
			  
			 
  
    
  SET @NSTEP=10  
  
  SET @cSchemeRowId=''
  DECLARE @TRETMSG TABLE  (MEMO_ID VARCHAR(40),ERRMSG VARCHAR(MAX))  
     
  
  
    
  SET @NSTEP=30  
    
  SET @CFILTERCONDITION=''  
     
  SELECT TOP 1 @CCURDEPTID = VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='LOCATION_ID'  
  SELECT TOP 1 @CHODEPTID = VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='HO_LOCATION_ID'  

  IF @CCURDEPTID=@CHODEPTID
  BEGIN
	  SET @CERRORMSG='P:SPwow_MERGE_MIRROR_MSTEOSS_INC, CANNOT CALL MERGING PROC AT HEAD OFFICE'
	  GOTO END_PROC
  END					
      


		
  IF @NMODE=0
	GOTO END_PROC

  BEGIN TRANSACTION
      
  SET @CMEMOID='MSTEOSS'  
    
LBLMERGEBEFORE:  
	
	SET @NSTEP=40  

	IF OBJECT_ID('TEMPDB..#TMPFILTERCHANGE','U') IS NOT NULL
		DROP TABLE #TMPFILTERCHANGE	  
	
	SELECT ROW_ID INTO #TMPFILTERCHANGE FROM SCHEME_SETUP_DET WHERE 1=2
	     
	SELECT	   @CTEMPMASTERTABLENAME='MSTEOSS_wow_SchemeSetup_Mst_MIRROR',  
			   @CTEMPDETAILTABLENAME='MSTEOSS_wow_SchemeSetup_Title_Det_MIRROR',  
			   @CTEMPlocDETAILTABLENAME='MSTEOSS_wow_SchemeSetup_LOCS_MIRROR',  
			   @CTEMPSCHEMESETUPSLABSDET='MSTEOSS_wow_SchemeSetup_slabs_Det_MIRROR',  
			   @CTEMPSchemeSetupslsbcget='MSTEOSS_wow_SchemeSetup_slsbc_get_MIRROR',  
			   @CTEMPSchemeSetupslsbcbuy='MSTEOSS_wow_SchemeSetup_slsbc_buy_MIRROR',  
			   @CTEMPSchemeSetupslsbcflat='MSTEOSS_wow_SchemeSetup_slsbc_flat_MIRROR',  
			   @CTEMPwow_SchemeSetupparacombinationbuyflat='MSTEOSS_wow_SchemeSetup_para_combination_buy_MIRROR',  -- buy_filter_mode=3 and scheme_mode in (1,2)  for para_combination_buy
			   @CTEMPSchemeSetupparacombinationconfig='MSTEOSS_wow_SchemeSetup_para_combination_config_MIRROR' ,--(buy_filter_mode=3 or (get_filter_mode=3 and scheme_mode=3))
			   @CTEMPwow_SchemeSetup_para_combination_flat='MSTEOSS_wow_SchemeSetup_para_combination_flat_MIRROR' ,--scheme mode 1  and buy filter mode=3
			   @CTEMPwow_SchemeSetup_para_combination_get='MSTEOSS_wow_SchemeSetup_para_combination_get_MIRROR' --get_filter_mode=3 and scheme_mode=3 for para_combination_get
			 
			

	     	   
LBLDELETE:  
        
	IF @NMODE IN (1,2,3)
	BEGIN
		SET @NSTEP=50
		IF OBJECT_ID('TEMPDB..#TMPDELSCHEMES','U') IS NOT NULL
			DROP TABLE #TMPDELSCHEMES
		
		SELECT ROW_ID AS SCHEME_SETUP_DET_ROW_ID INTO #TMPDELSCHEMES FROM SCHEME_SETUP_DET (NOLOCK) WHERE 1=2
		
		IF @NMODE=1
			INSERT #TMPDELSCHEMES	( SCHEME_SETUP_DET_ROW_ID )   
			SELECT schemeRowId AS SCHEME_SETUP_DET_ROW_ID
			FROM wow_SchemeSetup_Title_Det A (NOLOCK) 
			LEFT OUTER JOIN MSTEOSS_wow_SchemeSetup_Mst_MIRROR B (NOLOCK) ON A.setupId=B.setupId 
			WHERE B.setupId IS NULL  OR B.inactive=1
		ELSE
		IF @NMODE=2
			INSERT #TMPDELSCHEMES	( SCHEME_SETUP_DET_ROW_ID )  
			SELECT A.schemeRowId AS SCHEME_SETUP_DET_ROW_ID
			FROM wow_SchemeSetup_Title_Det A (NOLOCK) 
			LEFT OUTER JOIN MSTEOSS_WOWSCHEMESINFO_MIRROR B (NOLOCK) ON A.schemeRowId=B.schemeRowId
			WHERE B.schemeRowId IS NULL
		ELSE
		IF @NMODE=3
			INSERT #TMPDELSCHEMES	( SCHEME_SETUP_DET_ROW_ID )  
			SELECT schemeRowId FROM MSTEOSS_wow_SchemeSetup_Title_Det_MIRROR
		
		IF EXISTS (SELECT TOP 1 * FROM #TMPDELSCHEMES)
		BEGIN
			SET @NSTEP=60				
			
			DELETE A FROM  wow_SchemeSetup_para_combination_get A JOIN #TMPDELSCHEMES B ON A.schemeRowId=B.SCHEME_SETUP_DET_ROW_ID
			DELETE A FROM  wow_SchemeSetup_para_combination_flat A JOIN #TMPDELSCHEMES B ON A.schemeRowId=B.SCHEME_SETUP_DET_ROW_ID
			DELETE A FROM  wow_SchemeSetup_para_combination_config A JOIN #TMPDELSCHEMES B ON A.schemeRowId=B.SCHEME_SETUP_DET_ROW_ID
			DELETE A FROM  wow_SchemeSetup_para_combination_buy A  JOIN #TMPDELSCHEMES B ON A.schemeRowId=B.SCHEME_SETUP_DET_ROW_ID
			DELETE A FROM  wow_SchemeSetup_slsbc_flat A  JOIN #TMPDELSCHEMES B ON A.schemeRowId=B.SCHEME_SETUP_DET_ROW_ID
			DELETE A FROM  wow_schemesetup_happyhours A  JOIN #TMPDELSCHEMES B ON A.schemeRowId=B.SCHEME_SETUP_DET_ROW_ID

			DELETE A FROM  wow_SchemeSetup_slsbc_buy A JOIN #TMPDELSCHEMES B ON A.schemeRowId=B.SCHEME_SETUP_DET_ROW_ID
			DELETE A FROM  wow_SchemeSetup_slsbc_get A  JOIN #TMPDELSCHEMES B ON A.schemeRowId=B.SCHEME_SETUP_DET_ROW_ID
			DELETE A FROM  wow_SchemeSetup_slabs_Det A JOIN #TMPDELSCHEMES B ON A.schemeRowId=B.SCHEME_SETUP_DET_ROW_ID 
			DELETE A FROM  wow_SchemeSetup_locs A JOIN #TMPDELSCHEMES B ON A.schemeRowId=B.SCHEME_SETUP_DET_ROW_ID 
			DELETE A FROM  wow_SchemeSetup_Title_Det A JOIN #TMPDELSCHEMES B ON A.schemeRowId=B.SCHEME_SETUP_DET_ROW_ID 
			
			
		    IF @NMODE IN (1,2)
		    BEGIN	
				SET @NSTEP=90
				DELETE A FROM wow_SchemeSetup_Title_Det A JOIN #TMPDELSCHEMES B ON B.SCHEME_SETUP_DET_ROW_ID=A.schemeRowId
				
				IF @NMODE=1
					DELETE A FROM wow_SchemeSetup_Mst A LEFT OUTER JOIN wow_SchemeSetup_Title_Det B ON A.setupId=B.setupId
					WHERE B.setupId IS NULL
			END
		END
				
		IF @NMODE=1 ----- UPDATE THE INFORMATION FOR ALL SCHEME SETUP MEMOS ONLY RELATED TO TARGET LOCATION
		BEGIN
			SET @NSTEP=100
			DELETE FROM MSTEOSS_wow_SchemeSetup_Mst_MIRROR WHERE INACTIVE=1 
			
			UPDATE MSTEOSS_wow_SchemeSetup_title_det_MIRROR SET locApplicableMode=1
			
			

			SET @NSTEP=120
			EXEC UPDATEMASTERXN_OPT 
			@CSOURCEDB='',
			@CSOURCETABLE=@CTEMPMASTERTABLENAME,
			@CDESTDB='',
			@CDESTTABLE='wow_SchemeSetup_Mst',
			@CKEYFIELD1='setupId',
			@CKEYFIELD2='',
			@CKEYFIELD3='',
			@LINSERTONLY=0,
			@CFILTERCONDITION='',
			@LUPDATEONLY=0,
			@BALWAYSUPDATE=1			

							
	
			
		END	
		ELSE
		IF @NMODE=2
		BEGIN   ---- AFTER DELETING TITLES AT LOCATION (WHICH ARE NOT FOUND AT HO OR INACTIVE) 
				---- RETURN THE LIST OF TITLES WHICH ARE NOT FOUND OR MODIFIED
				---- TO BE SYNCH FROM HO ONE BY ONE
			SET @NSTEP=150	
			SELECT A.schemeRowId,A.SCHEMENAME,'' AS ERRMSG FROM MSTEOSS_WOWSCHEMESINFO_MIRROR A
			LEFT OUTER JOIN wow_SchemeSetup_Title_Det B ON A.schemeRowId=B.schemeRowId
			WHERE isnull(A.schemeLastUpdate,'')<>ISNULL(B.schemeLastUpdate,'')
			
		END
		ELSE
		IF @NMODE=3	----- SYNCH THE SCHEME DETAILS FOR A GIVEN TITLE
		BEGIN
			SET @NSTEP=160
			
			SELECT TOP 1 @cSchemeRowId=schemeRowID FROM MSTEOSS_wow_SchemeSetup_Title_Det_MIRROR
			INSERT #TMPFILTERCHANGE (ROW_ID)
			SELECT A.schemeRowId FROM MSTEOSS_wow_SchemeSetup_Title_Det_MIRROR A 

		END				
		
		IF @NMODE IN(1,2)
			GOTO END_PROC
		
	END	
	
LBLMERGE:  
	
    PRINT 'SCHEME_SETUP_MST'
LBLMERGETABLES:

SET @nStep=162
	EXEC SPwow_VALIDATE_EOSSDATA
	@cErrormsg=@CERRORMSG OUTPUT

	
	IF ISNULL(@CERRORMSG,'')<>''
		GOTO END_PROC

	SET @NSTEP=165

	EXEC UPDATEMASTERXN_OPT 
	@CSOURCEDB='',
	@CSOURCETABLE=@CTEMPDETAILTABLENAME,
	@CDESTDB='',
	@CDESTTABLE='wow_SchemeSetup_Title_Det',
	@CKEYFIELD1='schemeRowId',
	@CKEYFIELD2='',
	@CKEYFIELD3='',
	@LINSERTONLY=0,
	@CFILTERCONDITION='',
	@LUPDATEONLY=0,
	@BALWAYSUPDATE=1

	SET @NSTEP=167

	EXEC UPDATEMASTERXN_OPT 
	@CSOURCEDB='',
	@CSOURCETABLE=@CTEMPlocDETAILTABLENAME,
	@CDESTDB='',
	@CDESTTABLE='wow_SchemeSetup_locs',
	@CKEYFIELD1='schemeRowId',
	@CKEYFIELD2='locationId',
	@CKEYFIELD3='',
	@LINSERTONLY=0,
	@CFILTERCONDITION='',
	@LUPDATEONLY=0,
	@BALWAYSUPDATE=1
	

	SET @NSTEP=180
	EXEC UPDATEMASTERXN_OPT 
	@CSOURCEDB='',
	@CSOURCETABLE=@CTEMPSchemeSetupslsbcget,
	@CDESTDB='',
	@CDESTTABLE='wow_SchemeSetup_slsbc_get',
	@CKEYFIELD1='RowId',
	@CKEYFIELD2='',
	@CKEYFIELD3='',
	@LINSERTONLY=0,
	@CFILTERCONDITION='',
	@LUPDATEONLY=0,
	@BALWAYSUPDATE=1

	      
				
	SET @NSTEP=190
	EXEC UPDATEMASTERXN_OPT 
	@CSOURCEDB='',
	@CSOURCETABLE=@CTEMPSCHEMESETUPSLABSDET,
	@CDESTDB='',
	@CDESTTABLE='wow_SchemeSetup_slabs_Det',
	@CKEYFIELD1='RowId',
	@CKEYFIELD2='',
	@CKEYFIELD3='',
	@LINSERTONLY=0,
	@CFILTERCONDITION='',
	@LUPDATEONLY=0,
	@BALWAYSUPDATE=1
	

	SET @NSTEP=200
	EXEC UPDATEMASTERXN_OPT 
	@CSOURCEDB='',
	@CSOURCETABLE=@CTEMPSchemeSetupslsbcbuy,
	@CDESTDB='',
	@CDESTTABLE='wow_SchemeSetup_slsbc_buy',
	@CKEYFIELD1='RowId',
	@CKEYFIELD2='',
	@CKEYFIELD3='',
	@LINSERTONLY=0,
	@CFILTERCONDITION='',
	@LUPDATEONLY=0,
	@BALWAYSUPDATE=1
		
	SET @NSTEP=210
	EXEC UPDATEMASTERXN_OPT 
	@CSOURCEDB='',
	@CSOURCETABLE=@CTEMPSchemeSetupslsbcflat,
	@CDESTDB='',
	@CDESTTABLE='wow_SchemeSetup_slsbc_flat',
	@CKEYFIELD1='RowId',
	@CKEYFIELD2='',
	@CKEYFIELD3='',
	@LINSERTONLY=0,
	@CFILTERCONDITION='',
	@LUPDATEONLY=0,
	@BALWAYSUPDATE=1
		
	SET @NSTEP=220	
	EXEC UPDATEMASTERXN_OPT 
	@CSOURCEDB='',
	@CSOURCETABLE=@CTEMPwow_SchemeSetupparacombinationbuyflat,
	@CDESTDB='',
	@CDESTTABLE='wow_SchemeSetup_para_combination_buy',
	@CKEYFIELD1='RowId',
	@CKEYFIELD2='',
	@CKEYFIELD3='',
	@LINSERTONLY=0,
	@CFILTERCONDITION='',
	@LUPDATEONLY=0,
	@BALWAYSUPDATE=1

		
	SET @NSTEP=230
	EXEC UPDATEMASTERXN_OPT 
	@CSOURCEDB='',
	@CSOURCETABLE=@CTEMPSchemeSetupparacombinationconfig,
	@CDESTDB='',
	@CDESTTABLE='wow_SchemeSetup_para_combination_config',
	@CKEYFIELD1='schemeRowId',
	@CKEYFIELD2='',
	@CKEYFIELD3='',
	@LINSERTONLY=0,
	@CFILTERCONDITION='',
	@LUPDATEONLY=0,
	@BALWAYSUPDATE=1

			
	SET @NSTEP=240
	EXEC UPDATEMASTERXN_OPT 
	@CSOURCEDB='',
	@CSOURCETABLE=@CTEMPwow_SchemeSetup_para_combination_flat,
	@CDESTDB='',
	@CDESTTABLE='wow_SchemeSetup_para_combination_flat',
	@CKEYFIELD1='RowId',
	@CKEYFIELD2='',
	@CKEYFIELD3='',
	@LINSERTONLY=0,
	@CFILTERCONDITION='',
	@LUPDATEONLY=0,
	@BALWAYSUPDATE=1					

	SET @NSTEP=250
	EXEC UPDATEMASTERXN_OPT 
	@CSOURCEDB='',
	@CSOURCETABLE=@CTEMPwow_SchemeSetup_para_combination_get,
	@CDESTDB='',
	@CDESTTABLE='wow_SchemeSetup_para_combination_get',
	@CKEYFIELD1='RowId',
	@CKEYFIELD2='',
	@CKEYFIELD3='',
	@LINSERTONLY=0,
	@CFILTERCONDITION='',
	@LUPDATEONLY=0,
	@BALWAYSUPDATE=1	

	SET @NSTEP=255
	EXEC UPDATEMASTERXN_OPT 
	@CSOURCEDB='',
	@CSOURCETABLE='msteoss_wow_schemesetup_happyhours_mirror',
	@CDESTDB='',
	@CDESTTABLE='wow_schemesetup_happyhours',
	@CKEYFIELD1='RowId',
	@CKEYFIELD2='',
	@CKEYFIELD3='',
	@LINSERTONLY=0,
	@CFILTERCONDITION='',
	@LUPDATEONLY=0,
	@BALWAYSUPDATE=1	

	SET @NSTEP=260
	EXEC UPDATEMASTERXN_OPT 
	@CSOURCEDB='',
	@CSOURCETABLE=@CTEMPMASTERTABLENAME,
	@CDESTDB='',
	@CDESTTABLE='wow_SchemeSetup_Mst',
	@CKEYFIELD1='setupId',
	@CKEYFIELD2='',
	@CKEYFIELD3='',
	@LINSERTONLY=0,
	@CFILTERCONDITION='',
	@LUPDATEONLY=0,
	@BALWAYSUPDATE=1	

	EXEC SPWOW_VALIDATE_EOSSDATA
	@bChkFinalData=1,
	@cSchDetRowId=@cSchemeRowId,
	@cErrormsg=@CERRORMSG OUTPUT

	IF ISNULL(@CERRORMSG,'')<>''
		GOTO END_PROC

	UPDATE location WITH (ROWLOCK) SET eoss_last_updated_on=getdate() WHERE dept_id=@CCURDEPTID


	GOTO END_PROC
												
END TRY			

BEGIN CATCH
	SET @CERRORMSG ='ERROR IN PROCEDURE SP_MERGE_MIRROR_MSTEOSS_INC AT STEP#'+STR(@NSTEP)+' || ' + ERROR_MESSAGE()
END CATCH
    
END_PROC:

	IF @@TRANCOUNT>0
	BEGIN
		IF ISNULL(@CERRORMSG,'')=''
			COMMIT TRANSACTION
		ELSE
			ROLLBACK 	
	END	

		DECLARE @bDonotDelete bit=0

		IF @bDonotDelete=0
		BEGIN
			print 'release'
			DELETE FROM MSTEOSS_wow_SchemeSetup_locs_MIRROR
			DELETE FROM MSTEOSS_wow_SchemeSetup_Title_Det_MIRROR
			DELETE FROM MSTEOSS_wow_SchemeSetup_slabs_Det_MIRROR
			DELETE FROM MSTEOSS_wow_SchemeSetup_slsbc_get_MIRROR
			DELETE FROM MSTEOSS_wow_SchemeSetup_slsbc_buy_MIRROR
			DELETE FROM MSTEOSS_wow_SchemeSetup_slsbc_flat_MIRROR
			DELETE FROM MSTEOSS_wow_SchemeSetup_happyhours_MIRROR
			DELETE FROM MSTEOSS_wow_SchemeSetup_para_combination_buy_MIRROR
			DELETE FROM MSTEOSS_wow_SchemeSetup_para_combination_config_MIRROR 
			DELETE FROM MSTEOSS_wow_SchemeSetup_para_combination_flat_MIRROR 
			DELETE FROM MSTEOSS_wow_SchemeSetup_para_combination_get_MIRROR
			DELETE FROM MSTEOSS_wow_SchemeSetup_Mst_MIRROR
			DELETE FROM MSTEOSS_WOWSCHEMESINFO_MIRROR
		END
	
	--IF  ISNULL(@CERRORMSG,'')<>''
		SELECT 'MSTEOSS' AS MEMO_ID,ISNULL(@CERRORMSG,'') AS ERRMSG    
    
END  
--- END OF CREATING PROCEDURE SP_MERGE_MIRROR_MSTEOSS_INC