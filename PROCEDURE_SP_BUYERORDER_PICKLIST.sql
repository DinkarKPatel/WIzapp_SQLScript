create PROCEDURE SP_BUYERORDER_PICKLIST
(
	@NQUERYID			INTEGER,
	@CWHERE				VARCHAR(MAX)
)
AS
BEGIN
	IF @NQUERYID=1
	BEGIN
		SELECT a.*,b.AC_NAME,CAST('' AS VARCHAR(50)) AS SP_ID 
		FROM PLM01106 a (NOLOCK)
		LEFT OUTER JOIN LM01106 b (NOLOCK) ON b.AC_CODE=a.AC_CODE
		WHERE MEMO_ID=@CWHERE
	END
	ELSE IF @NQUERYID=2
	BEGIN

	     SELECT A.MEMO_ID ,A.ROW_ID ,A.ORD_ROW_ID ,A.QUANTITY ,B.LAST_UPDATE ,
		        A.BIN_ID ,A.PLD_PRODUCT_CODE ,CAST(0 AS NUMERIC(10,3)) AS STOCKQTY,
				CAST(0 AS NUMERIC(10,3)) AS INV_QTY,B.AC_CODE ,
				CAST('' AS VARCHAR(100)) AS SP_ID,
				b.ORDER_ID ,LM.AC_NAME AS CUSTOMER_NAME ,bm.order_no,bm.order_dt,
				CAST(0 AS BIT ) AS CHK,ARTICLE_NO ,PARA1_NAME ,PARA2_NAME ,PARA3_NAME ,
				p2.para2_order ,sd.sub_section_name ,sm.section_name ,
				a.Article_code ,a.para1_code ,a.para2_code ,a.para3_code,a.pl_inv_qty ,b.order_id 
		 FROM PLD01106 A
		 JOIN PLM01106 B ON A.MEMO_ID =B.MEMO_ID 
		 JOIN ARTICLE ART ON A.ARTICLE_CODE =ART.ARTICLE_CODE 
		 JOIN PARA1 P1 (NOLOCK) ON P1.PARA1_CODE =A.PARA1_CODE 
		 JOIN PARA2 P2 (NOLOCK) ON P2.PARA2_CODE =A.PARA2_CODE 
		 JOIN PARA3 P3 (NOLOCK) ON P3.PARA3_CODE =A.PARA3_CODE 
		 JOIN LM01106 LM (NOLOCK) ON lm.AC_CODE =B.AC_CODE 
		 JOIN SECTIOND SD (NOLOCK) ON SD.SUB_SECTION_CODE=ART.SUB_SECTION_CODE
         JOIN  SECTIONM SM (NOLOCK) ON SM.SECTION_CODE=SD.SECTION_CODE
		 LEFT JOIN BUYER_ORDER_MST BM (NOLOCK) ON BM.ORDER_ID=b.ORDER_ID
		 WHERE a.MEMO_ID=@CWHERE

		--DECLARE @cColList VARCHAR(MAX),@cConfigCols VARCHAR(1000),@cJoinstr VARCHAR(MAX),@cCmd NVARCHAR(MAX)

		--SELECT @cConfigCols = coalesce(@cConfigCols+',','')+'a.'+COLUMN_NAME from CONFIG_BUYERORDER (NOLOCK) 
		--WHERE isnull(open_key,0)=1

		--SELECT @cColList=
		--	(CASE WHEN charindex('ARTICLE_NO',@cConfigCols)>0 THEN  'article_no ' ELSE '' END)+
		--	(CASE WHEN charindex('PARA1_NAME',@cConfigCols)>0 THEN  ',para1_name ' ELSE '' END)+
		--	(CASE WHEN charindex('PARA2_NAME',@cConfigCols)>0 THEN  ',para2_name ' ELSE '' END)+
		--	(CASE WHEN charindex('PARA2_NAME',@cConfigCols)>0 THEN  ',para2_order ' ELSE '' END)+
		--	(CASE WHEN charindex('PARA3_NAME',@cConfigCols)>0 THEN  ',para3_name ' ELSE '' END)+
		--	(CASE WHEN charindex('PARA4_NAME',@cConfigCols)>0 THEN  ',para4_name ' ELSE '' END)+
		--	(CASE WHEN charindex('PARA5_NAME',@cConfigCols)>0 THEN  ',para5_name ' ELSE '' END)+
		--	(CASE WHEN charindex('PARA6_NAME',@cConfigCols)>0 THEN  ',para6_name ' ELSE '' END)+
		--	(CASE WHEN charindex('PARA7_NAME',@cConfigCols)>0 THEN  ' PARA7_NAME ' ELSE '' END)
	
		--SELECT @cColList=@cColList+(CASE WHEN charindex(column_name,@cConfigCols)>0 THEN  ','+column_name ELSE '' END)
		--FROM config_attr WHERE table_caption<>''
		
		--SET @cJoinstr=''
		
		--SELECT @cJoinstr=
		--	(CASE WHEN charindex('ARTICLE_NO',@cConfigCols)>0 OR charindex('ARTICLE_NAME',@cConfigCols)>0 OR charindex('PARA7_NAME',@cConfigCols)>0 THEN  ' JOIN article (NOLOCK) ON article.article_code=c.article_code ' ELSE '' END)+
		--	(CASE WHEN charindex('PARA1_NAME',@cConfigCols)>0 THEN  ' JOIN para1 (NOLOCK) ON para1.para1_code=c.para1_code ' ELSE '' END)+
		--	(CASE WHEN charindex('PARA2_NAME',@cConfigCols)>0 THEN  ' JOIN para2 (NOLOCK) ON para2.para2_code=c.para2_code  ' ELSE '' END)+
		--	(CASE WHEN charindex('PARA3_NAME',@cConfigCols)>0 THEN  ' JOIN para3 (NOLOCK) ON para3.para3_code=c.para3_code  ' ELSE '' END)+
		--	(CASE WHEN charindex('PARA4_NAME',@cConfigCols)>0 THEN  ' JOIN para4 (NOLOCK) ON para4.para4_code=c.para4_code  ' ELSE '' END)+
		--	(CASE WHEN charindex('PARA5_NAME',@cConfigCols)>0 THEN  ' JOIN para5 (NOLOCK) ON para5.para5_code=c.para5_code  ' ELSE '' END)+
		--	(CASE WHEN charindex('PARA6_NAME',@cConfigCols)>0 THEN  ' JOIN para6 (NOLOCK) ON para6.para6_code=c.para6_code  ' ELSE '' END)+
		--	(CASE WHEN charindex('PARA7_NAME',@cConfigCols)>0 THEN  ' JOIN para7 (NOLOCK) ON para7.para7_code=c.para7_code  ' ELSE '' END)

		--DECLARE @cAddJoin VARCHAR(MAX),@cAddCols VARCHAR(MAX)


		--SELECT @cAddJoin = ' JOIN sectiond sd (NOLOCK) ON sd.sub_section_code=article.sub_section_code
		--					 JOIN  sectionm sm (NOLOCK) ON sm.section_code=sd.section_code
		--					 LEFT JOIN article_fix_attr af (NOLOCK) ON af.article_code=article.article_code '

		--SELECT @cAddJoin=@cAddJoin+
		--' LEFT OUTER JOIN  '+table_name+' ON '+table_name+'.'+replace(column_name,'_name','_code')+'=af.'+replace(column_name,'_name','_code')
		--FROM config_attr WHERE table_caption<>''	
	
		--SELECT @cAddCols=',sm.section_name,sd.sub_section_name'
		--SELECT @cAddCols=@cAddCols+','+table_name+'.'+column_name+' as ['+table_caption+']'
		--FROM config_attr WHERE table_caption<>''


		
		--SELECT  A.MEMO_ID,ROW_ID,a.ORD_ROW_ID,a.QUANTITY,a.LAST_UPDATE,a.BIN_ID,a.PLD_Product_code,
		--        sum(B.QUANTITY_IN_STOCK) AS STOCKQTY,
		--		CAST(0 AS NUMERIC (14,3)) AS INV_QTY ,cast(null as timestamp) AS TS ,CAST('' AS VARCHAR(20)) AS AC_CODE,CAST('' AS VARCHAR(50)) AS SP_ID,
		--		sum(a.pl_inv_qty)  pl_inv_qty
		--     into #tmppld
		--FROM PLD01106 A (NOLOCK)
		--LEFT JOIN PMT01106 B ON A.MEMO_ID =B.PICK_LIST_ID AND A.PLD_PRODUCT_CODE =B.PRODUCT_CODE AND A.BIN_ID =B.BIN_ID and b.quantity_in_stock <>0
		--WHERE A.MEMO_ID=@CWHERE
		--group by A.MEMO_ID,ROW_ID,a.ORD_ROW_ID,a.QUANTITY,a.LAST_UPDATE,a.BIN_ID,a.PLD_Product_code


		--Update a set INV_QTY =b.Ps_qty
		--from #tmppld a
		--join 
		--(
		--  select b.ROW_ID ,sum(a.QUANTITY) as Ps_qty 
		--  from wps_det a (nolock)
		--  join #tmppld b on a.PICK_LIST_ROW_ID=b.ROW_ID
		--  join wps_mst c (nolock)  on c.ps_id=a.ps_Id
		--  where c.CANCELLED =0
		--  group by b.ROW_ID
		--) b on a.ROW_ID =b.ROW_ID 

		
		--SET @cCmd=N'SELECT B1.* ,BIN.BIN_NAME AS BInName, MBIN.BIN_NAME AS ZoneName,
		--a.ORDER_ID,a.ORDER_NO,a.ORDER_DT,LM.AC_NAME AS CUSTOMER_NAME,CONVERT(BIT,0) CHK,'+@cColList+@cAddCols+'
		--FROM #tmppld B1  (NOLOCK) 
		--JOIN BUYER_ORDER_DET C (NOLOCK)  ON c.ROW_ID=B1.ORD_ROW_ID
		--JOIN BUYER_ORDER_MST A (NOLOCK)  ON C.ORDER_ID=A.ORDER_ID
		--JOIN BIN (NOLOCK) ON BIN.BIN_ID=B1.BIN_ID
		--JOIN BIN MBIN (NOLOCK) ON BIN.major_bin_id=MBIN.BIN_ID
		--LEFT OUTER JOIN LM01106 LM (NOLOCK) ON A.AC_CODE = LM.AC_CODE '+@cJoinstr+@cAddJoin+'
		--WHERE MEMO_ID='''+@CWHERE+''' ORDER BY '+REPLACE(@cColList,',para2_name','')
		
		--PRINT @cCmd
		--EXEC SP_EXECUTESQL @cCmd
	END

END

