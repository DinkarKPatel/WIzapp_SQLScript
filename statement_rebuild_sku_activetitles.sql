IF EXISTS (SELECT TOP 1 config_option FROM config (NOLOCK) WHERE config_option='sku_active_titles_rebuilt' AND value='1')
	RETURN

truncate table sku_active_titles
truncate table sku_active_titles_get

--drop table #tmpFilterChange
--select product_code into #tmpcmd from sku where 1=2
select row_id into #tmpFilterChange from scheme_Setup_det a
JOIN scheme_Setup_mst b on a.memo_no=b.memo_no
WHERE convert(date,getdate()) between applicable_from_dt and applicable_to_dt
--select * from  #tmpFilterChange



declare @CERRORMSG varchar(max)
exec SP3S_GETFILTERED_TITLES
@nMode=3,
@CERRORMSG=@CERRORMSG output

--select @CERRORMSG

INSERT config	( config_option, CTRL_NAME, Description, GROUP_NAME, last_update, OPT_SR_NO, REMARKS, row_id, SET_AT_HO, value, VALUE_TYPE )  
SELECT 'sku_active_titles_rebuilt' config_option,'' CTRL_NAME,'' Description,null GROUP_NAME,getdate() last_update,
null OPT_SR_NO, 'Rebuild Sku Active Titles after Optimization changes done' REMARKS,newid() row_id,0 SET_AT_HO,
'1' value,null VALUE_TYPE 
