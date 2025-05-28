CREATE PROCEDURE SP3S_EOSS_MARK_CUTSIZES_BARCODE
(
 @CERRORMSG VARCHAR(MAX) OUTPUT
)
AS
BEGIN
 ---DECLARE LOCAL VARIABLE
 
BEGIN TRY
	 
	 DECLARE @CSTEP VARCHAR(2)
	 SET @CERRORMSG=''
	 PRINT 'ENTER CUT SIZE-1'
	
	 IF NOT EXISTS (SELECT TOP 1 ROW_ID FROM SCHEME_SETUP_DET WHERE CUT_SIZE_SCHEME=1)
		RETURN

	 SET @CSTEP='10'
	 IF OBJECT_ID('TEMPDB..#TMPSIZEWISESTK','U') IS NOT NULL
		DROP TABLE #TMPSIZEWISESTK

	 IF OBJECT_ID('TEMPDB..#TMPSdpara2','U') IS NOT NULL
	 	DROP TABLE #TMPSdpara2	 
	
	 PRINT 'ENTER CUT SIZE-2.5'
	 SELECT DISTINCT c.article_code,d.PARA2_CODE,CONVERT(NUMERIC(10,2),0) AS CBS_QTY,
	 CONVERT(bit,0) as cut_size
	 into	#TMPSIZEWISESTK  FROM 
	 #TMPCMD A 
	 JOIN SKU B (NOLOCK) ON A.PRODUCT_CODE=B.PRODUCT_CODE
	 JOIN ARTICLE C (NOLOCK) ON C.ARTICLE_CODE=B.ARTICLE_CODE
	 JOIN CUTSIZE_PARAS D (NOLOCK) ON D.SUB_SECTION_CODE=C.SUB_SECTION_CODE 
	 	 
	 SET @CSTEP='20'

	 PRINT 'ENTER CUT SIZE-3'
	 UPDATE A SET CBS_QTY=B.CBS_QTY FROM #TMPSIZEWISESTK A
	 JOIN (SELECT B.ARTICLE_CODE,D.PARA2_CODE,SUM(QUANTITY_IN_STOCK) AS CBS_QTY FROM PMT01106 A
	       JOIN SKU B (NOLOCK) ON A.PRODUCT_CODE=B.PRODUCT_CODE
		   JOIN ARTICLE C (NOLOCK) ON C.ARTICLE_CODE=B.ARTICLE_CODE
		   JOIN #TMPSIZEWISESTK D ON D.ARTICLE_CODE=C.ARTICLE_CODE AND D.PARA2_CODE=B.PARA2_CODE
		   GROUP BY B.ARTICLE_CODE,D.PARA2_CODE) B ON A.ARTICLE_CODE=B.ARTICLE_CODE AND A.PARA2_CODE=B.PARA2_CODE
	 

	 PRINT 'ENTER CUT SIZE-4'
	 SET @CSTEP='30'
	 UPDATE A SET CUT_SIZE=1 FROM #TMPCMD A JOIN 
	 SKU B (NOLOCK)  ON A.PRODUCT_CODE=B.PRODUCT_CODE
	 JOIN #TMPSIZEWISESTK D ON D.ARTICLE_CODE=B.ARTICLE_CODE
	 JOIN (SELECT A.PRODUCT_CODE,MAX(B.RECEIPT_DT) AS RECEIPT_DT FROM PID01106 A (NOLOCK)
	       JOIN PIM01106 B (NOLOCK) ON B.MRR_ID=A.MRR_ID
		   JOIN #TMPCMD C ON C.PRODUCT_CODE=A.PRODUCT_CODE
		   WHERE INV_MODE=2 AND CANCELLED=0
		   GROUP BY A.PRODUCT_CODE) E ON E.PRODUCT_CODE=A.PRODUCT_CODE
	 WHERE D.CBS_QTY=0 AND DATEDIFF(DD,E.RECEIPT_DT,GETDATE())<=90
	 

END TRY
  
BEGIN CATCH
		SET @CERRORMSG='ERROR IN PROCEDURE SP3S_EOSS_MARK_CUTSIZES_BARCODE AT STEP#'+@CSTEP+' '+ERROR_MESSAGE()
		PRINT 'ENTER CATCH BLOCK OF SP3S_EOSS_MARK_CUTSIZES_BARCODE'+@CERRORMSG
END CATCH

END
/*
create table cutsize_paras (sub_section_code char(7),para2_code char(9))

insert into cutsize_paras (sub_Section_code,para2_code)
select sub_section_Code,a.para2_code from sku a
join article b on a.article_code=b.article_code
group by sub_section_Code,a.para2_code

select  scheme_name, memo_no,* fROM scheme_Setup_det WHERE cut_size_scheme=1

select  applicable_from_dt,applicable_to_dt,scheme_name, a.memo_no,* fROM scheme_Setup_det a
join scheme_Setup_mst b on a.memo_no=b.memo_no WHERE scheme_name='atest'


select distinct quantity_in_stock, sku.para2_Code,sub_Section_name from pmt01106 pmt join sku  on pmt.product_code=sku.product_code
join article art on art.article_code=sku.article_Code
join sectiond b on art.sub_Section_code=b.sub_section_code
join sectionm c on c.section_code=b.section_code
where section_name='boys'
order by sub_Section_name


select distinct sku.para2_code from sku 
join article art on art.article_code=sku.article_Code
join sectiond b on art.sub_Section_code=b.sub_section_code
where sub_section_name='acc'

select * from scheme_setup_mst where memo_no='JM00027'

update scheme_Setup_mst set applicable_to_dt='2019-11-30' where memo_no<>'JM00027'

;with ctesc
as
(
select row_id,processing_order,row_number() over (order by last_update) as rno from scheme_Setup_det where   memo_no='JM00027'
)

update a set processing_order=b.rno from scheme_Setup_det a join ctesc b on a.row_id=b.row_id

select processing_order, *  from scheme_Setup_det where  cut_size_scheme=1

exec savetran_sls_beforesave 1,'76c70d0d78-f42e-450a-8b0c-73b5dda9f4bb','',''

select scheme_name, * from sls_cmd01106_upload where sp_id='76c70d0d78-f42e-450a-8b0c-73b5dda9f4bb'

select sp_id,* from sls_cmm01106_upload order by last_update desc

update scheme_Setup_det set processing_order=0 where scheme_name='ANIL'
*/