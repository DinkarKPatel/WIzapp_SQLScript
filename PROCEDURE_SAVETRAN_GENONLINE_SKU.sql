CREATE PROCEDURE SAVETRAN_GENONLINE_SKU  
@nMode NUMERIC(1,0),  
@cSpId VARCHAR(40),  
@bCallledforVendorEan bit=0,
@CERRORMSG VARCHAR(MAX) OUTPUT   
AS  
BEGIN  
  
    DECLARE @cCmd NVARCHAR(MAX),@bGenOnlineSku BIT,@cStep VARCHAR(5),@cSeparator VARCHAR(5),@cXnType VARCHAR(10)  
   
 BEGIN TRY  
    
  SET @CERRORMSG=''  
    

  SET @cStep=10  
  
  SET @cXnType=(CASE WHEN @nMode=1 THEN 'PUR' WHEN @nMode=2 THEN 'IRR' ELSE 'PO' END)
    
  SELECT TOP 1 @bGenOnlineSku=GENERATE_ONLINE_SKU,@cSeparator=ISNULL(barcode_separator,'') FROM ONLINE_BARCODE_PREFIX_SETUP_MST (NOLOCK)
  
  print   'enter online sku gen-1:'+@cSpid
  IF ISNULL(@bGenOnlineSku,0)=0 AND @bCallledforVendorEan=0
	RETURN  
     
  SET @cStep=20  
  SELECT a.product_code,article_code,para1_code,para2_code,para3_code,para4_code,para5_code,para6_code,
  CONVERT(VARCHAR(100),'') AS online_product_code,convert(varchar(40),'') as supplier_alias,  
  CONVERT(VARCHAR(50),'') as row_id  
  INTO #OnlineBarcodes FROM sku a  WHERE 1=2  
  
  print   'enter online sku gen-2:'+@cSpid  

  IF @cXnType='PUR'  
  BEGIN
	   INSERT #OnlineBarcodes (product_code,article_code,para1_code,para2_code,para3_code,para4_code,para5_code,para6_code,
	   online_product_code,supplier_alias,row_id)  
	   SELECT b.product_code,b.article_code,b.para1_code,b.para2_code,b.para3_code,b.para4_code,b.para5_code,
	   b.para6_code, '' as online_product_code,d.Alias_to_be_suffixed as supplier_alias,b.row_id  
	   FROM pur_pid01106_upload b (NOLOCK)  
	   LEFT JOIN sku a (NOLOCK) ON a.product_code=b.product_code  
	   JOIN pur_pim01106_upload c (NOLOCK) ON c.sp_id=b.sp_id
	   JOIN LM01106 d (NOLOCK) ON d.AC_CODE=c.ac_code  
	   WHERE c.sp_id=@cSpId AND ISNULL(a.online_product_code,'')=''  
  END
  ELSE  
  IF @cXnType='IRR'  
  BEGIN
	   INSERT #OnlineBarcodes (product_code,article_code,para1_code,para2_code,para3_code,para4_code,para5_code,para6_code,online_product_code,supplier_alias,row_id)  
	   SELECT b.new_product_Code AS product_Code,a.article_code,a.para1_code,a.para2_code,a.para3_code,
	   a.para4_code,a.para5_code,a.para6_code,'' as online_product_code,  
	   LM.Alias_to_be_suffixed AS SUPPLIER_ALIAS   ,b.row_id
	   FROM sku a (NOLOCK)  
	   JOIN IRR_IRD01106_UPLOAD b (NOLOCK) ON a.product_code=b.new_product_code  
	   JOIN IRR_IRM01106_UPLOAD c (NOLOCK) ON c.sp_id=b.sp_id
	   JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE=A.AC_CODE  
	   WHERE c.sp_id=@cSpId
	   AND (b.article_code<>b.old_article_code OR b.para1_code<>b.old_para1_code OR b.para2_code<>b.old_para2_code 
			OR b.para3_code<>b.old_para3_code OR b.para4_code<>b.old_para4_code OR b.para5_code<>b.old_para5_code  
			OR b.para6_code<>b.old_para6_code
			OR ISNULL(b.online_product_code,'')<>'')
	   AND c.type IN (1,3,4)    
	   UNION  
	   SELECT b.product_code,a.article_code,a.para1_code,a.para2_code,a.para3_code,
	   a.para4_code,a.para5_code,a.para6_code,'' as online_product_code,  
	   LM.Alias_to_be_suffixed AS SUPPLIER_ALIAS,b.row_id   
	   FROM sku a  
	   JOIN IRR_IRD01106_UPLOAD b ON a.product_code=b.product_code  
	   JOIN IRR_IRM01106_UPLOAD c ON c.sp_id=b.sp_id
	   JOIN LM01106 LM ON LM.AC_CODE=A.AC_CODE  
	   WHERE c.sp_id=@cSpId 
	   AND (b.article_code<>b.old_article_code OR b.para1_code<>b.old_para1_code OR b.para2_code<>b.old_para2_code 
			OR b.para3_code<>b.old_para3_code OR b.para4_code<>b.old_para4_code OR b.para5_code<>b.old_para5_code  
			OR b.para6_code<>b.old_para6_code
			OR ISNULL(b.online_product_code,'')<>'')  
			AND c.type IN (1,3,4)  
  END
  ELSE  
  IF @cXnType='PO'  
  BEGIN
	   INSERT #OnlineBarcodes (product_code,article_code,para1_code,para2_code,para3_code,para4_code,para5_code,para6_code,
	   online_product_code,supplier_alias,row_id)  
	   SELECT b.product_code,b.article_code,b.para1_code,b.para2_code,b.para3_code,b.para4_code,b.para5_code,
	   b.para6_code,'' as online_product_code,d.Alias_to_be_suffixed as supplier_alias,b.row_id  
	   FROM PO_POD01106_UPLOAD b (NOLOCK)  
	   JOIN PO_POM01106_UPLOAD c (NOLOCK) ON c.sp_id=b.sp_id  
	   JOIN LM01106 d (NOLOCK) ON d.AC_CODE=c.ac_code  
	   LEFT JOIN SKU E (NOLOCK) ON e.product_code=b.product_code
	   WHERE c.sp_id=@cSpId AND ISNULL(b.online_product_code,'')='' AND ISNULL(e.online_product_code,'')=''  
  END

  print   'enter online sku gen-3:'+@cSpid  
  SET @cStep=30       
  IF NOT EXISTS (SELECT TOP 1 product_code FROM #OnlineBarcodes)  
	 GOTO END_PROC  
  
  print   'enter online sku gen-4:'+@cSpid
  DECLARE @cOnlinePcExpr VARCHAR(1000),@cParaName VARCHAR(200)

  
  SET @cStep=32       
  SELECT * INTO #online_prefix FROM ONLINE_BARCODE_PREFIX_SETUP_DET (NOLOCK) WHERE enable_prefix=1

  SET @cOnlinePcExpr=' '
  WHILE EXISTS (SELECT TOP 1 * FROM #online_prefix)
  BEGIN
		SET @cStep=35       
		SELECT TOP 1 @cParaName=para_name from #online_prefix order by prefix_order
		SET @cOnlinePcExpr=@cOnlinePcExpr+'+'+(CASE WHEN @cOnlinePcExpr<>'' THEN ''''+@cSeparator+'''+' ELSE '' END)+
		(CASE WHEN charindex('alias',@cParaName)>0 THEN REPLACE(@cParaName,'_','.') ELSE @cParaName END)

		DELETE FROM #online_prefix WHERE para_name=@cParaName
  END

  SET @cStep=37            
  SET @cCmd=N'UPDATE a SET online_product_code='+@cOnlinePcExpr+'
  FROM #OnlineBarcodes A (NOLOCK)   
  JOIN article (NOLOCK) ON article.article_code=a.article_code
  JOIN sectiond sub_section(NOLOCK) ON sub_section.sub_section_code=article.sub_section_code
  JOIN sectionm section(NOLOCK) ON section.section_code=sub_section.section_code
  JOIN PARA1(NOLOCK)   ON PARA1.PARA1_CODE=A.para1_code   
  JOIN PARA2(NOLOCK)   ON PARA2.PARA2_CODE=A.PARA2_CODE  
  JOIN PARA3(NOLOCK)   ON PARA3.PARA3_CODE=A.para3_code  
  JOIN PARA4(NOLOCK)   ON PARA4.PARA4_CODE=A.para4_code  
  JOIN PARA5(NOLOCK)   ON PARA5.PARA5_CODE=A.para5_code  
  JOIN PARA6(NOLOCK)   ON PARA6.PARA6_CODE=A.para6_code  
  WHERE ISNULL(a.online_product_code,'''')='''''  
  
  PRINT @cCmd
  EXEC SP_EXECUTESQL @cCmd
  

   SET @cStep=40  
  UPDATE sku WITH (ROWLOCK)  set online_product_code=b.online_product_code from #OnlineBarcodes b  
  WHERE b.product_code=sku.product_code AND (ISNULL(sku.online_product_code,'')='' OR @cXnType='IRR') 
  AND sku.product_code<>'' 
    
  SET @cStep=50  
  IF @cXntype='PO'  
  BEGIN
	   UPDATE a WITH (ROWLOCK) set online_product_code=b.online_product_code from 
	   PO_POD01106_UPLOAD a  JOIN sku b (NOLOCK) ON b.product_code=a.product_code
	   WHERE a.sp_id=@cSpId AND ISNULL(a.online_product_code,'')=''      

	   UPDATE a WITH (ROWLOCK) set online_product_code=b.online_product_code from 
	   PO_POD01106_UPLOAD a  JOIN #OnlineBarcodes b (NOLOCK) ON b.product_code=a.product_code
	   WHERE a.sp_id=@cSpId AND ISNULL(a.online_product_code,'')=''      
  
  END	

  SET @cStep=55  
  IF @cXntype='PUR' 
  BEGIN 
	   UPDATE a WITH (ROWLOCK) set online_product_code=b.online_product_code from 
	   PUR_PID01106_UPLOAD a   JOIN sku b (NOLOCK) ON b.product_code=a.product_code
	   WHERE a.sp_id=@cSpId AND ISNULL(a.online_product_code,'')=''      

	   UPDATE a WITH (ROWLOCK) set online_product_code=b.online_product_code from 
	   PUR_PID01106_UPLOAD a   JOIN #OnlineBarcodes b (NOLOCK) ON b.product_code=a.product_code
	   WHERE a.sp_id=@cSpId AND ISNULL(a.online_product_code,'')=''      
  END
       
     SET @cStep=60  
  IF @cXnType='IRR'  
  BEGIN  
	   UPDATE a with (rowlock) set online_product_code=b.online_product_code from IRR_IRD01106_UPLOAD A
	   joiN sku b WITH (NOLOCK)   ON b.product_code=a.new_product_code 
	   WHERE  A.SP_id=@cSpId AND ISNULL(a.online_product_code,'')=''  

	   UPDATE a with (rowlock) set online_product_code=b.online_product_code from IRR_IRD01106_UPLOAD A
	   joiN sku b WITH (NOLOCK)    ON b.product_code=a.product_code 
	   WHERE  A.SP_id=@cSpId AND ISNULL(a.online_product_code,'')=''  

	   UPDATE a with (rowlock) set online_product_code=b.online_product_code from IRR_IRD01106_UPLOAD A
	   joiN #OnlineBarcodes b WITH (NOLOCK)   ON b.product_code=a.new_product_code 
	   WHERE  A.SP_id=@cSpId AND ISNULL(a.online_product_code,'')=''  
  END   
    
  GOTO END_PROC   
    
 END TRY  
   
   
 BEGIN CATCH  
  SET @CERRORMSG='Error at Step#'+@cStep+' in Procedure SAVETRAN_GENONLINE_SKU '+ERROR_MESSAGE()  
  GOTO END_PROC   
 END CATCH  
  
END_PROC:  
   
  
END    
----------------------------------------------------- END OF PROCEDURE SAVETRAN_GENONLINE_SKU 

