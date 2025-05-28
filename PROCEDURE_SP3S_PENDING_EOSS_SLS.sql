CREATE PROCEDURE SP3S_PENDING_EOSS_SLS
(
	 @DFROMDT DATETIME
	,@DTODT DATETIME
	,@CFILTER VARCHAR(MAX)
	,@NDISCOUNT_FILTER NUMERIC(10,3)=0

)
AS
BEGIN
/*
EXEC SP3S_PENDING_EOSS_SLS '2015-01-01','2015-04-01','ARTICLE.ARTICLE_NO IN (''MENS - COAT SUIT'',''MENS - JACKET'',''MENS - TROUSER'')'
*/
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @CCMD NVARCHAR(MAX),@CFILTER1 NVARCHAR(MAX)
	
	SET @CFILTER1=''
	SELECT @CFILTER1= REPLACE(ISNULL(A_FILTER,''),'''''''','') FROM TBL_EOSS_DISC_SHARE_MST WHERE ID=@CFILTER
	
	SELECT @CFILTER1= REPLACE(@CFILTER1,'''''','''') 
	
	IF OBJECT_ID('TEMPDB..#TEMP_DETAILS') IS NOT NULL DROP TABLE #TEMP_DETAILS
	CREATE TABLE #TEMP_DETAILS
	(
	 CM_NO             CHAR(15)
	,CM_DT             DATETIME
	,SECTION_NAME      VARCHAR(300)
	,SUB_SECTION_NAME  VARCHAR(300)
	,ARTICLE_NO        VARCHAR(300)
	,ARTICLE_ALIAS     VARCHAR(50)
	,PARA1_NAME        VARCHAR(300)
	,PARA2_NAME        VARCHAR(300)
	,PARA3_NAME        VARCHAR(300)
	,PARA4_NAME        VARCHAR(300)
	,PARA5_NAME        VARCHAR(300)
	,PARA6_NAME        VARCHAR(300)
	,UOM_NAME          VARCHAR(300)
	,PRODUCT_CODE      VARCHAR(50)
	,QUANTITY          NUMERIC(9,3)
	,MRP               NUMERIC(9,3)
	,NET               NUMERIC(9,3)
	,discount_amount   NUMERIC(10,2)	
	,nrv			   NUMERIC(20,2)	
	,value_at_pp	   NUMERIC(10,2)	
	,VALUE_AT_MRP      NUMERIC(9,3)
	,DISCOUNT_SHARING_AMOUNT NUMERIC(10,2)
	,tax_amount NUMERIC(10,2),tax_method NUMERIC(1,0)
	,scheme_name VARCHAR(500),dt_name VARCHAR(200),GROSS_MARGIN NUMERIC(6,2)
	,terms VARCHAR(1000)
)


	SET @cFilter1=REPLACE(@CFILTER1,'lmv01106.','')
	
	SET @CCMD=N'INSERT INTO #TEMP_DETAILS( CM_NO,CM_DT,SECTION_NAME,SUB_SECTION_NAME
	                  ,ARTICLE_NO,PARA1_NAME,PARA2_NAME,PARA3_NAME,PARA4_NAME
					  ,PARA5_NAME,PARA6_NAME,PRODUCT_CODE,QUANTITY,MRP,NET,VALUE_AT_PP,VALUE_AT_MRP
					  ,discount_amount,tax_amount,nrv,tax_method,scheme_name,dt_name
					  )
					  
	                   SELECT CMM.CM_NO ,CMM.CM_DT ,SECTION_NAME
					  ,SUB_SECTION_NAME,ARTICLE_NO,PARA1_NAME,PARA2_NAME,PARA3_NAME,PARA4_NAME
					  ,PARA5_NAME,PARA6_NAME
					  ,CMD.PRODUCT_CODE
					  ,SUM(CMD.QUANTITY) as quantity
					  ,CMD.MRP
					  ,SUM(CMD.NET) AS NET
					  ,SUM(sku.pp*quantity) AS value_at_pp
					  ,SUM(CMD.QUANTITY*CMD.MRP) AS VALUE_AT_MRP
					  ,SUM((cmd.mrp*(CASE WHEN ISNULL(cmd.authorized_brand_disc_pct,0)<>0 THEN
							 cmd.authorized_brand_disc_pct ELSE cmd.basic_discount_percentage END) /100)+
							 cmm_discount_amount) AS discount_amount
					  ,SUM(igst_amount+cgst_amount+sgst_amount) AS tax_amount
					  ,SUM(((cmd.mrp-(cmd.mrp*(CASE WHEN ISNULL(cmd.authorized_brand_disc_pct,0)<>0 THEN
							 cmd.authorized_brand_disc_pct ELSE cmd.basic_discount_percentage END) /100))*quantity)-
							cmd.cmm_discount_amount+(CASE WHEN tax_method=2 THEN igst_amount+cgst_amount+sgst_amount ELSE 0 END)) AS NRV
					  ,tax_method,cmd.scheme_name,dt_name
						  

				FROM CMD01106 CMD(NOLOCK)
				JOIN CMM01106 CMM(NOLOCK) ON CMD.CM_ID=CMM.CM_ID
				JOIN SKU_names sku (NOLOCK)  ON CMD.PRODUCT_CODE=SKU.PRODUCT_CODE
				JOIN DTM(NOLOCK) ON DTM.DT_CODE=CMM.DT_CODE 
				LEFT JOIN SCHEME_SETUP_DET SCH(NOLOCK) ON SCH.ROW_ID=CMD.SLSDET_ROW_ID
				LEFT JOIN 
				(
					SELECT DISTINCT D.CM_NO,D.CM_DT ,product_code
					FROM EOSSDND D
					JOIN EOSSDNM M ON D.MEMO_ID=M.MEMO_ID 
					JOIN cmm01106 c on c.CM_NO=d.CM_NO and c.CM_DT=d.CM_DT
					WHERE M.CANCELLED=0
				)EOSS ON CMM.cm_no=EOSS.CM_no and cmm.cm_dt=eoss.cm_dt AND eoss.PRODUCT_CODE=cmd.PRODUCT_CODE

				WHERE CMM.CANCELLED=0 AND EOSS.CM_NO IS NULL 
				
				AND CMM.CM_DT BETWEEN '''+CONVERT(VARCHAR,@DFROMDT,110)+''' AND 
				'''+CONVERT(VARCHAR,@DTODT,110)+'''
				'+(CASE WHEN ISNULL(@CFILTER1,'')='' THEN '' ELSE ' AND '+@CFILTER1 END)+
				'GROUP BY CMM.CM_NO ,CMM.CM_DT ,SECTION_NAME
					  ,SUB_SECTION_NAME,ARTICLE_NO,PARA1_NAME,PARA2_NAME,PARA3_NAME,PARA4_NAME
					  ,PARA5_NAME,PARA6_NAME
					  ,CMD.PRODUCT_CODE,cmd.mrp,tax_method,cmd.scheme_name,dt_name
				'

	PRINT @CCMD
	EXEC SP_EXECUTESQL @CCMD
	
	--DECLARE LOCAL VARIABLE
  DECLARE @LOOPSTART INT
         ,@LOOPEND INT
         ,@ID VARCHAR(100)
         ,@DISCFROM  NUMERIC(7,3)
         ,@DISCTO NUMERIC(7,3)
         ,@BASE INT
         ,@SUPP_SHARE_PER NUMERIC(7,2)
         ,@VAT_SHARING_MODE NUMERIC(7,2)
         ,@VAT_SHARING_PER NUMERIC(7,2)
   
   DECLARE @cFinYear VARCHAR(5),@nLoopcNT NUMERIC(2,0),@cDbName VARCHAR(200),@bFound BIT 
   
   set @nLoopcNT=1
   SET @cFinYear='01'+DBO.fn_getfinyear(getdate())
   
   SET @cDbName=DB_NAME()
   
   SET @bFound=1
   WHILE @bFound=1
   BEGIN
	   
	   	
	   SET @cCmd=N'UPDATE a SET terms=c.terms FROM #TEMP_DETAILS a
	   JOIN '+@cDbName+'.dbo.pid01106 b ON a.PRODUCT_CODE=b.product_code
	   JOIN '+@cDbName+'.dbo.pim01106 c ON c.mrr_id=b.mrr_id
	   WHERE inv_mode=1 AND a.terms IS NULL'
	   
	   PRINT @cCmd
	   EXEC SP_EXECUTESQL @cCmd		     
	   
	   lblStart:
	   SET @cFinYear='01'+DBO.fn_getfinyear(DATEADD(DD,-365*@nLoopCnt,getdate()))
	   
	   SET @nLoopcNT=@nLoopcNT+1
	   IF NOT EXISTS (SELECT TOP 1 * from #TEMP_DETAILS WHERE terms IS NULL) OR @nLoopcNT>10
			BREAK

	   
	   SET @cDbName=DB_NAME()+'_'+@cFinYear
	   
 	   IF DB_ID(@cDbName) IS  NULL		
			GOTO lblStart
   END
   
   
   UPDATE #temp_details SET GROSS_MARGIN=0
   
   UPDATE #temp_details SET GROSS_MARGIN=(SUBSTRING(Terms,DBO.CHARINDEX_NTH('-',Terms,1,2)+1,(DBO.CHARINDEX_NTH('-',Terms,1,3)-
							  DBO.CHARINDEX_NTH('-',Terms,1,2))-1))
   WHERE isnull(terms,'')<>'' AND ISNUMERIC((SUBSTRING(Terms,DBO.CHARINDEX_NTH('-',Terms,1,2)+1,(DBO.CHARINDEX_NTH('-',Terms,1,3)-
							  DBO.CHARINDEX_NTH('-',Terms,1,2))-1)))=1
	
   
   								  								  
   IF OBJECT_ID('TEMPDB..#TEMP_DISC') IS NOT NULL DROP TABLE #TEMP_DISC
   
   CREATE TABLE #TEMP_DISC
   (
     ID INT IDENTITY(1,1)
    ,DISCFROM  NUMERIC(7,3)
    ,DISCTO NUMERIC(7,3)
    ,BASE INT
    ,SUPP_SHARE_PER NUMERIC(7,2)
    ,VAT_SHARING_MODE NUMERIC(7,2)
    ,VAT_SHARING_PER NUMERIC(7,2)
   )
   
       
   INSERT INTO #TEMP_DISC(DISCFROM,DISCTO,BASE,SUPP_SHARE_PER,VAT_SHARING_MODE,VAT_SHARING_PER)
   SELECT DISCFROM,DISCTO,BASE,SUPP_SHARE_PER,VAT_SHARING_MODE,VAT_SHARING_PER 
   FROM TBL_EOSS_DISC_SHARE_DET WITH(NOLOCK)
   WHERE ID=@CFILTER
   SET @LOOPEND=@@ROWCOUNT;
   SET @LOOPSTART=1
   WHILE @LOOPEND >=@LOOPSTART
      BEGIN
         IF OBJECT_ID('TEMPDB..#TEMP_DISCOUNT_DETAILS') IS NOT NULL 
            DROP TABLE #TEMP_DISCOUNT_DETAILS
         SELECT @DISCFROM=DISCFROM,@DISCTO=DISCTO,@BASE=BASE
               ,@SUPP_SHARE_PER=SUPP_SHARE_PER
               ,@VAT_SHARING_MODE=VAT_SHARING_MODE
               ,@VAT_SHARING_PER=VAT_SHARING_PER
		 FROM #TEMP_DISC WHERE ID=@LOOPSTART
		
		--	SUBSTRING(Terms,DBO.CHARINDEX_NTH('-',Terms,1,2)+1,(DBO.CHARINDEX_NTH('-',Terms,1,3)-DBO.CHARINDEX_NTH('-',Terms,1,2))-1)
		         
         SELECT CM_NO,product_code,@SUPP_SHARE_PER AS [SUPP_SHARE_PER],cm_dt
            ,(CASE @BASE 
                WHEN 1 THEN (CASE TAX_METHOD 
                              WHEN 1 THEN ((DISCOUNT_AMOUNT)*@SUPP_SHARE_PER)/100
                              WHEN 2 THEN ((DISCOUNT_AMOUNT-ISNULL(TAX_AMOUNT,0))*@SUPP_SHARE_PER)/100
                             END)
                WHEN 2 THEN 
                (value_at_mrp-(value_at_mrp*gross_margin/100)-
				(((NRV-((NRV*@SUPP_SHARE_PER)/100)))-ISNULL(TAX_AMOUNT,0)))
             END) AS [DISCOUNT_SHARING_AMOUNT]
             
            
             
           INTO #TEMP_DISCOUNT_DETAILS FROM  #TEMP_DETAILS T
           WHERE case when value_at_mrp=0 then 0 else  ABS(ROUND((DISCOUNT_AMOUNT/value_at_mrp)*100,0)) end BETWEEN @DISCFROM AND @DISCTO

           
           UPDATE U SET U.[DISCOUNT_SHARING_AMOUNT]=ISNULL(T.[DISCOUNT_SHARING_AMOUNT],0)
           FROM #TEMP_DETAILS U
           JOIN  #TEMP_DISCOUNT_DETAILS T ON U.PRODUCT_CODE=T.product_code AND u.cm_no=t.cm_no and u.cm_dt=t.cm_dt
         
         SET @LOOPSTART=@LOOPSTART+1;
      END
	
	SELECT DISTINCT 0 AS XN_VALUE_WITH_GST,'' as hsn_code,0 as gst_percentage,  * FROM #TEMP_DETAILS

	
	--WHERE [DISCOUNT_SHARING_AMOUNT]>0
				

END
--END OF PROCEDURE - SP3S_PENDING_EOSS_SLS
/*
select ac_name,sum(basic_discount_amount), sum(a.discount_amount) discount,sum(quantity),sum(net) from cmd01106 a (nolock) join cmm01106 b (nolock) on a.cm_id=b.cm_id
join sku_names c (nolock) on c.product_Code=a.PRODUCT_CODE
join dtm (nolock) on dtm.dt_code=b.dt_code
where cm_dt between '2020-01-01' and '2020-01-31' and para4_alias='DEAL' and CANCELLED=0
and (basic_discount_amount<>0  or cmm_discount_amount<>0)
group by ac_name,a.manual_discount 

EXEC SP3S_PENDING_EOSS_SLS @DFROMDT='2020-01-01',@DTODT='2020-01-31',@CFILTER='HO00000126'

drop procedure SP3S_PENDING_EOSS_SLS
select * from eossdnm
*/			