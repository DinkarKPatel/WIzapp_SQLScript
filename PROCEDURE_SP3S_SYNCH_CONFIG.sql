CREATE PROCEDURE SP3S_SYNCH_CONFIG
AS
BEGIN
	
	BEGIN TRY
		

		BEGIN TRAN
		
				

		DECLARE @CSTEP VARCHAR(5),@CERRORMSG VARCHAR(1000),@cCmd NVARCHAR(max)
		
		SET @CERRORMSG=''
				
		SET @CSTEP='1'
		IF NOT EXISTS(SELECT TOP 1 XN_TYPE FROM STRUCOMP_XNSINFO_COMP)
		   BEGIN
		      SET @CERRORMSG='Table STRUCOMP_XNSINFO_COMP coming empty'
		      GOTO END_PROC
		   END

		IF NOT EXISTS(SELECT TOP 1 TABLENAME FROM STRUCOMP_MIRRORXNSINFO_COMP)
		   BEGIN
		      SET @CERRORMSG='Table STRUCOMP_MIRRORXNSINFO_COMP coming empty'
		      GOTO END_PROC
		   END

		IF NOT EXISTS(SELECT TOP 1 TABLE_NAME FROM STRUCOMP_TABLESTRUINFO_COMP)
		   BEGIN
		   	  SET @CERRORMSG='Table STRUCOMP_TABLESTRUINFO_COMP coming empty'
		      GOTO END_PROC
		   END

		IF NOT EXISTS(SELECT TOP 1 * FROM STRUCOMP_wow_xpert_report_cols_expressions_COMP) OR
		   NOT EXISTS(SELECT TOP 1 * FROM STRUCOMP_wow_xpert_report_cols_xntypewise_COMP) OR
		   NOT EXISTS(SELECT TOP 1 * FROM STRUCOMP_wow_xpert_report_colheaders_COMP)
		BEGIN
		   	SET @CERRORMSG='Xpert Reports columns Info table(s) coming empty'
		    GOTO END_PROC
		END

		SET @CSTEP='10'
		
		DELETE FROM xnsinfo
		DELETE FROM wow_xnsinfo
		DELETE FROM wow_xpert_report_cols_xntypewise
		DELETE FROM wow_xpert_report_colheaders
		DELETE FROM wow_xpert_report_cols_expressions

		EXEC UPDATEMASTERXN   
		 @CSOURCEDB = ''
	   , @CSOURCETABLE = 'STRUCOMP_XNSINFO_COMP'
	   , @CDESTDB  = ''  
	   , @CDESTTABLE = 'XNSINFO'
	   , @CKEYFIELD1 = 'XN_TYPE'
	   , @CKEYFIELD2 = 'TABLENAME'
	   , @BALWAYSUPDATE = 1
		
		SET @cStep='12'

		EXEC UPDATEMASTERXN   
		 @CSOURCEDB = ''
	   , @CSOURCETABLE = 'STRUCOMP_WOW_XNSINFO_COMP'
	   , @CDESTDB  = ''  
	   , @CDESTTABLE = 'WOW_XNSINFO'
	   , @CKEYFIELD1 = 'TABLENAME'
	   , @BALWAYSUPDATE = 1
		   
		SET @CSTEP='15'

		EXEC UPDATEMASTERXN  
		 @CSOURCEDB = ''
	   , @CSOURCETABLE = 'STRUCOMP_MIRRORXNSINFO_COMP'
	   , @CDESTDB  = ''  
	   , @CDESTTABLE = 'MIRRORXNSINFO'
	   , @CKEYFIELD1 = 'TABLENAME'
	   , @BALWAYSUPDATE = 1
	   
		SET @CSTEP='20'

		EXEC UPDATEMASTERXN
		 @CSOURCEDB = ''
	   , @CSOURCETABLE = 'STRUCOMP_TABLESTRUINFO_COMP'
	   , @CDESTDB  = ''  
	   , @CDESTTABLE = 'TABLESTRUINFO'
	   , @CKEYFIELD1 = 'TABLE_NAME'
       , @BALWAYSUPDATE = 1

	   
	   SET @CSTEP='35'	
	   UPDATE a set REMARKS=b.REMARKS,Description=b.Description,GROUP_NAME=b.GROUP_NAME,
	   value_type=b.value_type,set_at_ho=b.set_at_ho
	   FROM config a JOIN STRUCOMP_CONFIG_COMP b on a.config_option=b.config_option
	   
	   SET @CSTEP='40'
		EXEC UPDATEMASTERXN  
		 @CSOURCEDB = ''
	   , @CSOURCETABLE = 'STRUCOMP_CONFIG_COMP'
	   , @CDESTDB  = ''  
	   , @CDESTTABLE = 'CONFIG'
	   , @CKEYFIELD1 = 'CONFIG_OPTION'
	   , @LINSERTONLY = 1
		
		SET @CSTEP='50'
		DELETE A FROM REPORTS A JOIN STRUCOMP_REPORTS_COMP B ON A.MODULE_NAME=B.MODULE_NAME AND A.REPORT_NAME=B.REPORT_NAME
		
		EXEC UPDATEMASTERXN   
		 @CSOURCEDB = ''
	   , @CSOURCETABLE = 'STRUCOMP_REPORTS_COMP'
	   , @CDESTDB  = ''  
	   , @CDESTTABLE = 'REPORTS'
	   , @CKEYFIELD1 = 'MODULE_NAME'
	   , @CKEYFIELD2 = 'REPORT_NAME'
	   , @LINSERTONLY = 1
		
		 DELETE FROM MODULES
		SET @CSTEP='60'
		EXEC UPDATEMASTERXN   
		 @CSOURCEDB = ''
	   , @CSOURCETABLE = 'STRUCOMP_MODULES_COMP'
	   , @CDESTDB  = ''  
	   , @CDESTTABLE = 'MODULES'
	   , @CKEYFIELD1 = 'FORM_NAME'
	   , @CKEYFIELD2 = 'FORM_OPTION'
	   , @LINSERTONLY = 1
	   

		SET @CSTEP='65'

		EXEC UPDATEMASTERXN   
		 @CSOURCEDB = ''
	   , @CSOURCETABLE = 'STRUCOMP_sku_COMP'
	   , @CDESTDB  = ''  
	   , @CDESTTABLE = 'sku'
	   , @CKEYFIELD1 = 'product_code'
	   , @CKEYFIELD2 = ''
	   , @LINSERTONLY = 0

	   
		SET @CSTEP='70'
		EXEC UPDATEMASTERXN   
		 @CSOURCEDB = ''
	   , @CSOURCETABLE = 'STRUCOMP_print_report_type_comp'
	   , @CDESTDB  = ''  
	   , @CDESTTABLE = 'print_report_type'
	   , @CKEYFIELD1 = 'xn_type'
	   , @CKEYFIELD2 = 'Printtype'
	   , @LINSERTONLY = 0
	   , @BALWAYSUPDATE=1

	    DELETE FROM  synch_sku_cols
		SET @CSTEP='80'
		EXEC UPDATEMASTERXN   
		 @CSOURCEDB = ''
	   , @CSOURCETABLE = 'STRUCOMP_synch_sku_cols_comp'
	   , @CDESTDB  = ''  
	   , @CDESTTABLE = 'synch_sku_cols'
	   , @CKEYFIELD1 = 'table_name'
	   , @CKEYFIELD2 = 'COLUMN_NAME'
	   , @LINSERTONLY = 0
	   , @BALWAYSUPDATE=1

		SET @CSTEP='90'
		EXEC UPDATEMASTERXN   
		 @CSOURCEDB = ''
	   , @CSOURCETABLE = 'STRUCOMP_wow_xpert_report_cols_expressions_comp'
	   , @CDESTDB  = ''  
	   , @CDESTTABLE = 'wow_xpert_report_cols_expressions'
	   , @CKEYFIELD1 = 'column_id'
	   , @LINSERTONLY = 0
	   , @BALWAYSUPDATE=1

		SET @CSTEP='100'
		EXEC UPDATEMASTERXN   
		 @CSOURCEDB = ''
	   , @CSOURCETABLE = 'STRUCOMP_wow_xpert_report_colheaders_comp'
	   , @CDESTDB  = ''  
	   , @CDESTTABLE = 'wow_xpert_report_colheaders'
	   , @CKEYFIELD1 = 'major_column_id'
	   , @LINSERTONLY = 0
	   , @BALWAYSUPDATE=1	   


		SET @CSTEP='110'
		EXEC UPDATEMASTERXN   
		 @CSOURCEDB = ''
	   , @CSOURCETABLE = 'STRUCOMP_wow_xpert_report_cols_xntypewise_comp'
	   , @CDESTDB  = ''  
	   , @CDESTTABLE = 'wow_xpert_report_cols_xntypewise'
	   , @CKEYFIELD1 = 'column_id'
	   , @CKEYFIELD2 = 'xn_type'
	   , @CKEYFIELD3 = 'major_column_id'
	   , @LINSERTONLY = 0
	   , @BALWAYSUPDATE=1

	   --- Specially need to run these commands in existing Report column
	   --- because of some wrongly column created against Delivery challan
	   --- because it is not coming right in Stock analysis
	   --- due to newly created column of Delivery challan qty column by Anil
	    update wow_xpert_rep_det set column_id='c1135' where xn_type='dlv_inv' and column_id='c0832'

		update wow_xpert_rep_det set column_id='C1136' where xn_type='dlv_inv' and column_id='C0833' -- pp

		update wow_xpert_rep_det set column_id='C1137' where xn_type='dlv_inv' and column_id='C0834' -- mrp

		update wow_xpert_rep_det set column_id='C1139' where xn_type='dlv_inv' and column_id='C0835' -- wsp

		update wow_xpert_rep_det set column_id='C1138' where xn_type='dlv_inv' and column_id='C0838' -- lc

		update wow_xpert_rep_det set column_id='C1140' where xn_type='dlv_inv' and column_id='C1094' -- Sec Pp

		SET @CSTEP='120'
		DELETE FROM wow_XPERT_XNTYPeS_alias

		EXEC UPDATEMASTERXN   
		 @CSOURCEDB = ''
	   , @CSOURCETABLE = 'STRUCOMP_wow_XPERT_XNTYPeS_alias_comp'
	   , @CDESTDB  = ''  
	   , @CDESTTABLE = 'wow_XPERT_XNTYPeS_alias'
	   , @CKEYFIELD1 = 'xn_type_alias'
	   , @LINSERTONLY = 1

	   SET @CSTEP='125'
	   delete from wow_menu_items

		EXEC UPDATEMASTERXN   
		 @CSOURCEDB = ''
	   , @CSOURCETABLE = 'STRUCOMP_wow_menu_items_comp'
	   , @CDESTDB  = ''  
	   , @CDESTTABLE = 'wow_menu_items'
	   , @CKEYFIELD1 = 'menu_id'
	   , @LINSERTONLY = 1

		EXEC UPDATEMASTERXN   
		 @CSOURCEDB = ''
	   , @CSOURCETABLE = 'STRUCOMP_wowdb_ageingdays_comp'
	   , @CDESTDB  = ''  
	   , @CDESTTABLE = 'wowdb_ageingdays'
	   , @CKEYFIELD1 = 'groupName'
	   , @LINSERTONLY = 1

	 
	   SET @CSTEP='135'
	   
	   UPDATE wow_menu_auth SET auth_option_variable=isnull(auth_option_variable,'')
	   UPDATE STRUCOMP_wow_menu_auth_comp  SET auth_option_variable=isnull(auth_option_variable,'')

	   SET @CSTEP='140'

	   EXEC UPDATEMASTERXN   
		 @CSOURCEDB = ''
	   , @CSOURCETABLE = 'STRUCOMP_wow_menu_auth_comp'
	   , @CDESTDB  = ''  
	   , @CDESTTABLE = 'wow_menu_auth'
	   , @CKEYFIELD1 = 'menu_id'
	   , @CKEYFIELD2 = 'role_id'
	   ,@cKeyfield3 = 'auth_option_variable'
	   , @LINSERTONLY = 1


	   SET @CSTEP='142'

	   ;WITH ADMIN_ROLE
		AS
		(
			SELECT menu_id,role_id AS ADMIN_ROLE_ID,auth_flag,auth_option_variable,OptionDetail 
			from wow_menu_auth where role_id='0000000'
		)
		,ALLUSERS
		AS
		(
			select ROLE_ID  from USER_ROLE_MST  where role_id<>'0000000'
		)
		,ALLDATA
		AS
		(
			SELECT * FROM ADMIN_ROLE,ALLUSERS
		)
		INSERT INTO wow_menu_auth( menu_id,role_id ,auth_flag,auth_option_variable,OptionDetail) 
		SELECT A.menu_id,A.role_id ,0 AS auth_flag,A.auth_option_variable,A.OptionDetail 
		FROM ALLDATA A
		LEFT OUTER JOIN wow_menu_auth B ON B.role_id=A.ROLE_ID AND A.menu_id=B.menu_id AND a.auth_option_variable=b.auth_option_variable
		WHERE B.role_id IS NULL

	   SET @CSTEP='145'

	   DELETE FRom wow_Location_Column

	   EXEC UPDATEMASTERXN   
		 @CSOURCEDB = ''
	   , @CSOURCETABLE = 'STRUCOMP_wow_Location_Column_comp'
	   , @CDESTDB  = ''  
	   , @CDESTTABLE = 'wow_Location_Column'
	   , @CKEYFIELD1 = 'tablename'
	   , @CKEYFIELD2 = 'OrgColumnName'
	   , @LINSERTONLY = 1

	   SET @CSTEP='150'

	   DELETE FRom wow_map_Columns

	   EXEC UPDATEMASTERXN   
		 @CSOURCEDB = ''
	   , @CSOURCETABLE = 'STRUCOMP_wow_map_Columns_comp'
	   , @CDESTDB  = ''  
	   , @CDESTTABLE = 'wow_map_Columns'
	   , @CKEYFIELD1 = 'tablename'
	   , @CKEYFIELD2 = 'OrgColumnName'
	   , @LINSERTONLY = 1

	   SET @CSTEP='160'
	   EXEC UPDATEMASTERXN   
		 @CSOURCEDB = ''
	   , @CSOURCETABLE = 'STRUCOMP_rack_management_category_config_comp'
	   , @CDESTDB  = ''  
	   , @CDESTTABLE = 'rack_management_category_config'
	   , @CKEYFIELD1 = 'baseTable'
	   , @LINSERTONLY = 1

	   SET @CSTEP='170'
	     DELETE FROM wow_auth_mappings
		EXEC UPDATEMASTERXN
		 @CSOURCEDB = ''
	   , @CSOURCETABLE = 'STRUCOMP_wow_auth_mappings_COMP'
	   , @CDESTDB  = ''  
	   , @CDESTTABLE = 'wow_auth_mappings'
	   , @CKEYFIELD1 = 'wow_menu_id'
	   , @CKEYFIELD2 = 'wa_form_name'
       , @LINSERTONLY = 1	   

		SET @CSTEP='180'
	    DELETE FROM wow_xpert_derivedcols_link
		EXEC UPDATEMASTERXN
		 @CSOURCEDB = ''
	   , @CSOURCETABLE = 'STRUCOMP_wow_xpert_derivedcols_link_COMP'
	   , @CDESTDB  = ''  
	   , @CDESTTABLE = 'wow_xpert_derivedcols_link'
	   , @CKEYFIELD1 = 'xn_type'
	   , @CKEYFIELD2 = 'column_id'
	   , @CKEYFIELD3 = 'ref_column_id'
       , @LINSERTONLY = 1	   
	   GOTO END_PROC	
	END TRY
	
	BEGIN CATCH
		SET @CERRORMSG='ERROR IN PROCEDURE SP3S_SYNCH_CONFIG AT STEP#'+@CSTEP+' '+ERROR_MESSAGE()
		GOTO END_PROC 
	END CATCH

END_PROC:
	
	if @@TRANCOUNT>0
	begin
		if isnull(@cErrormsg,'')=''
			commit
		else
			rollback
	end

	SELECT ISNULL(@CERRORMSG,'') AS ERRMSG	   
END