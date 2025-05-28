create   PROCEDURE SP3S_WPSPRINT_DYNAMIC
(
@cMemoId VARCHAR(40),
@CWHERE NVARCHAR(MAX)=''
)
AS
BEGIN


	   DECLARE @cCmdCols VARCHAR(MAX),@cCmd NVARCHAR(MAX),@cCols NVARCHAR(MAX),@cCmd1 NVARCHAR(MAX),@cCmd2 NVARCHAR(MAX),@cCmd3 NVARCHAR(MAX),@cCmdIMG NVARCHAR(MAX)
	   ,@PARA1 NVARCHAR(10),@PARA2 NVARCHAR(10),@PARA3 NVARCHAR(10),@PARA4 NVARCHAR(10),@PARA5 NVARCHAR(10),@PARA6 NVARCHAR(10),
	   @cnullableCols VARCHAR(max),@CERRMSG VARCHAR(1000),@cgroupcols varchar(max)
	   
	
	   SET @CERRMSG=''

	    IF OBJECt_ID('tempdb..#tmpBoxes','u') is not null    
		  dROP TaBLE #tmpBoxes    
    
		 CrEaTE tABlE #tmpBoxes (ps_id varchar(40),total_box numeric(4,0))   
		 
		 set @cCmdIMG=''
		 if isnull(@CWHERE,'')<>''
		 SET @cCmdIMG=ISNULL(@cCmdIMG,'') + N' AND wps_det.box_no in ('+@CWHERE+')'
    
		 Set @cCMd=N'SELECT PS_ID,COUNT(DISTINCT BOX_NO) AS TOTAL_BOX FROM WPS_DET (NOLOCK)    
		  WHERE ps_id='''+@cMemoId+'''     
		  GROUP BY PS_ID'    
    
		 iNsERT #tmpBoxes    
	 	 exec sp_executesql @CCmd    

		 declare @PLNOLIST varchar(max)
		if exists ( SELECT TOP 1 'u' FROM SALESORDERPROCESSING (nolock) WHERE XNTYPE='PLPACKSLIP' and Memoid=@cMemoId)
		begin
		     
			 select @PLNOLIST=COALESCE(@PLNOLIST+',','')+rtrim(ltrim(MEMO_NO))
			 FROM SALESORDERPROCESSING A (nolock) 
			 join PLM01106 b (nolock) on a.RefMemoId =b.MEMO_ID 
			 WHERE XNTYPE='PLPACKSLIP' and Memoid=@cMemoId
			 group by MEMO_NO

		end

		SET @PLNOLIST=ISNULL(@PLNOLIST,'')

		 IF OBJECt_ID('tempdb..#tmpOrdPlan','u') is not null    
		  dROP TaBLE #tmpOrdPlan    
     
		 SELECT BAR_DET.PRODUCT_CODE, A.ORDER_NO AS BUYER_ORDER_NO,A.ORDER_DT AS BUYER_ORDER_DT,A.REF_NO AS BUYER_ORDER_REF_NO    
		  ,BMST.MEMO_NO AS JOB_CARD_NO,BMST.MEMO_DT AS JOB_CARD_DT    
		  iNTO #tmpOrdPlan FROM ORD_PLAN_BARCODE_DET BAR_DET (NOLOCK)     
		  JOIN ORD_PLAN_DET BDET (NOLOCK) ON BDET.ROW_ID=BAR_DET.REFROW_ID    
		  JOIN ORD_PLAN_MST BMST (NOLOCK) ON BDET.MEMO_ID=BMST.MEMO_ID    
		  LEFT JOIN BUYER_ORDER_DET A1 (NOLOCK) ON BDET.WOD_ROW_ID=A1.ROW_ID    
		  LEFT JOIN BUYER_ORDER_MST A (NOLOCK) ON A1.ORDER_ID=A.ORDER_ID    
		  JOIN wps_det wpd (nolock) on wpd.product_code=bar_det.product_code    
		  WHERE wpd.ps_id=@cMemoId AND BMST.CANCELLED=0 AND A.CANCELLED=0    
		  GROUP BY BAR_DET.PRODUCT_CODE, A.ORDER_ID,A.ORDER_NO,A.ORDER_DT,A.REF_NO,BMST.MEMO_ID ,BMST.MEMO_NO,BMST.MEMO_DT    
    
	

        SELECT TOP 1 @PARA1=VALUE FROM CONFIG WHERE config_option='PARA1_caption' AND ISNULL(VALUE,'') <>''
        SELECT TOP 1 @PARA2=VALUE FROM CONFIG WHERE config_option='PARA2_caption' AND ISNULL(VALUE,'') <>''
        SELECT TOP 1 @PARA3=VALUE FROM CONFIG WHERE config_option='PARA3_caption' AND ISNULL(VALUE,'') <>''
        SELECT TOP 1 @PARA4=VALUE FROM CONFIG WHERE config_option='PARA4_caption' AND ISNULL(VALUE,'') <>''
        SELECT TOP 1 @PARA5=VALUE FROM CONFIG WHERE config_option='PARA5_caption' AND ISNULL(VALUE,'') <>''
        SELECT TOP 1 @PARA6=VALUE FROM CONFIG WHERE config_option='PARA6_caption' AND ISNULL(VALUE,'') <>''
	    SET @PARA1=CASE WHEN ISNULL(@PARA1,'')='' THEN 'Para1' ELSE ISNULL(@PARA1,'') END
	    SET @PARA2=CASE WHEN ISNULL(@PARA2,'')='' THEN 'Para2' ELSE ISNULL(@PARA2,'') END
	    SET @PARA3=CASE WHEN ISNULL(@PARA3,'')='' THEN 'Para3' ELSE ISNULL(@PARA3,'') END
	    SET @PARA4=CASE WHEN ISNULL(@PARA4,'')='' THEN 'Para4' ELSE ISNULL(@PARA4,'') END
	    SET @PARA5=CASE WHEN ISNULL(@PARA5,'')='' THEN 'Para5' ELSE ISNULL(@PARA5,'') END
	    SET @PARA6=CASE WHEN ISNULL(@PARA6,'')='' THEN 'Para6' ELSE ISNULL(@PARA6,'') END
	   
	    SELECT @cCols=COALESCE(@cCols+',','')+column_name+' ['+DISPLAY_COLUMN_NAME+']' ,
		       @cgroupcols=COALESCE(@cgroupcols+',','')+column_name
	    FROM dynamic_print_cols	
	    WHERE LTRIM(RTRIM(xn_type))='WPS' AND selected=1
		AND DISPLAY_COLUMN_NAME not in('Size_Cross_Type','SizeQtyString')

		SELECT BOX_NO ,CAST(0 AS NUMERIC(14,3)) AS GROSSWEIGHT
		      INTO #TMPXNWEIGHTBOXES
		FROM XNBOXDETAILS A (NOLOCK) WHERE 1=2


		IF CHARINDEX ('GROSSWEIGHT',@CCOLS)>0
		BEGIN
            
			 INSERT INTO #TMPXNWEIGHTBOXES(BOX_NO,GROSSWEIGHT)
			 SELECT A.BOX_NO , ISNULL(XNITEMWEIGHT,0)+ISNULL(EMPTYBOXWEIGHT,0) AS GROSSWEIGHT
			 FROM XNBOXDETAILS A (NOLOCK)
			 WHERE A.REF_MEMO_ID =@CMEMOID AND XN_TYPE ='WPS'
		
	
		END


		SELECT @cnullableCols=COALESCE(@cnullableCols+',','')+'NULL as '+' ['+DISPLAY_COLUMN_NAME+']' 
		FROM dynamic_print_cols	
	    WHERE LTRIM(RTRIM(xn_type))='wps' AND selected=0 AND DISPLAY_COLUMN_NAME not in('Size_Cross_Type','SizeQtyString')
		SET @cnullableCols=ISNULL(@cnullableCols,'')
		IF ISNULL(@cnullableCols,'')<>''
		   SET @cnullableCols=','+ISNULL(@cnullableCols,'')
		
	 


	  DECLARE @CSPID VARCHAR(100),@CTABLENAME VARCHAR(100)

	 SET @CSPID=LTRIM(RTRIM(STR(@@SPID )))
	 SET @CTABLENAME  ='##TMPPOPRINT'+@CSPID

	SET @CCMD = N'IF OBJECT_ID(''TEMPDB..'+@CTABLENAME+''',''U'') IS NOT NULL
		          DROP TABLE '+@CTABLENAME+''
	PRINT @CCMD
    EXEC SP_EXECUTESQL @CCMD

	

	 
	 --select @cCols
	   SET @cCmdCols=N'
	   SELECT '+@cCols+',
	   '''+@para1 +''' AS PARA1_CONFIG,'''+@PARA2 +''' AS PARA2_CONFIG,'''+@PARA3 +''' AS PARA3_CONFIG,
	   '''+@PARA4 +''' AS PARA4_CONFIG,'''+@PARA5 +''' AS PARA5_CONFIG,'''+@PARA6 +''' AS PARA6_CONFIG,
	    SIZE_SRNO=cast(0 as int),
		'''+@PLNOLIST+''' as PickListNoList,
	    DBO.FN_CONVERTAMOUNTINWORDS(WPM.SUBTOTAL) AS  SUBTOTAL_IN_WORDS
	    '+@cnullableCols
	   +'  INTO '+@CTABLENAME+'  '
	     SET @cCmd=N'FROM WPS_MST WPM     (NOLOCK)       
		 JOIN WPS_DET  (NOLOCK) ON WPM.PS_ID = WPS_DET.PS_ID            
		 JOIN LMV01106 LMV (NOLOCK) ON LMV.AC_CODE = WPM.AC_CODE                    
		 JOIN EMPLOYEE  (NOLOCK) ON EMPLOYEE.EMP_CODE = WPS_DET.EMP_CODE            
		 LEFT JOIN USERS U1 (NOLOCK) ON U1.USER_CODE = WPM.USER_CODE  
		 LEFT JOIN USERS U2 (NOLOCK) ON U2.USER_CODE = WPM.EDT_USER_CODE      
		 JOIN SKU_names sn (NOLOCK) ON sn.PRODUCT_CODE = WPS_DET.PRODUCT_CODE                
		 left join LOC_VIEW loc (nolock) on loc.dept_id =WPM.LOCATION_CODE    
		 JOIN #tmpBoxes Z ON Z.PS_ID=WPM.PS_ID    
		 LEFT OUTER JOIN COMPANY COM (NOLOCK) ON 1=1 AND COM.COMPANY_CODE=''01''    
		 LEFT OUTER JOIN #tmpOrdPlan X ON X.PRODUCT_CODE=WPS_DET.PRODUCT_CODE 
		 JOIN SKU (NOLOCK) ON SKU.PRODUCT_CODE=WPS_DET.PRODUCT_CODE
		 join para2 p2 (nolock) on p2.para2_code=sku.para2_code 
		 LEFT JOIN #TMPXNWEIGHTBOXES XNBOX ON XNBOX.BOX_NO=WPS_DET.BOX_NO
		 WHERE WPM.ps_id='''+@cMemoId+'''  '+@cCmdIMG
       print 'cCmdCols '+@cCmdCols
       print @cCmd
       EXEC(@cCmdCols+@cCmd)

     
	   DECLARE  @CsizeQTY VARCHAR(1000)
	   SET @CsizeQTY=''

	   IF EXISTS (SELECT TOP 1 'U'  FROM dynamic_print_cols	WHERE LTRIM(RTRIM(xn_type))='WPS' AND selected=1 and DISPLAY_COLUMN_NAME='SizeQtyString')
	   BEGIN
	         SET @cCmd=N' Update a set SIZE_SRNO=p2.para2_order 
			      FROM '+@CTABLENAME+'  A
			      JOIN PARA2 P2 ON P2.PARA2_NAME=A.PARA2_NAME '
			 exec sp_executesql  @cCmd


	         SET @CsizeQTY=N',(SELECT STUFF((SELECT CASE WHEN ISNULL(para2_name,'''') <> '''' THEN ''  '' ELSE '''' END +para2_name+ ''/''+RTRIM(LTRIM(STR((SUM(QUANTITY)))))  
		     FROM '+@CTABLENAME+'  B  WHERE A.article_no  =B.article_no AND A.para1_name =B.para1_name 
				GROUP BY ARTICLE_no,PARA1_NAME,RATE,CASE WHEN ISNULL(para2_name,'''') <> '''' THEN ''  '' ELSE '''' END +para2_name	,SIZE_SRNO 
				order by SIZE_SRNO
				FOR XML PATH('''')),1,2,''''))  	 as [SIZEQTY]'
		END
	
	 
	
	   
 END_PROC:
       
	   IF ISNULL(@CERRMSG,'')<>'' 
	   BEGIN
		   SELECT @CERRMSG AS ERRMSG 
	   END
	   ELSE 
	   BEGIN
	        
		IF not EXISTS (SELECT TOP 1 'U' FROM DYNAMIC_PRINT_COLS	WHERE LTRIM(RTRIM(XN_TYPE))='WPS' AND SELECTED=1
		   AND DISPLAY_COLUMN_NAME='SIZE_CROSS_TYPE')
		begin

			SET @CCMD = N'SELECT * '+@CsizeQTY+'
			FROM '+@CTABLENAME+' A '
			PRINT @CCMD
			EXEC SP_EXECUTESQL @CCMD    
		end
		else 
		begin
		   

        Declare @cdisplaycolname varchar(max),@dtsql varchar(max)

		SELECT @cdisplaycolname=COALESCE(@cdisplaycolname+',','')+' ['+DISPLAY_COLUMN_NAME+']' 
	    FROM dynamic_print_cols	
	    WHERE LTRIM(RTRIM(xn_type))='WPS' AND selected=1
		AND DISPLAY_COLUMN_NAME not in('Size_Cross_Type','para2_alias','para2_name','SizeQtyString')




		    SET @CCMD = N';with sizesr as 
			             (
						 select *, sno=dense_rank() OVER (PARTITION BY '+@cdisplaycolname+' ORDER BY '+@cdisplaycolname+')
				         FROM '+@CTABLENAME+' A 
				          )
						  UPDATE SIZESR SET SIZE_SRNO=SNO
						  '
			PRINT @CCMD
			EXEC SP_EXECUTESQL @CCMD 

		    SET @dtsql = N';with cte as  
				(
				SELECT a.*,SizeCOL=''SizeCOL''+cast( SIZE_SRNO as varchar(10)),
				       AUTOSR=ROW_NUMBER() OVER (ORDER BY PRODUCT_CODE)
				FROM   '+@CTABLENAME+' A
				)  

				SELECT a.*,b.[SizeVAL1], b.[SizeVAL2], b.[SizeVAL3], b.[SizeVAL4], b.[SizeVAL5] FROM 
				(
				 SELECT *
				 FROM CTE 
				 PIVOT (MAX(PARA2_NAME) for SIZECOL in ([SizeCOL1], [SizeCOL2], [SizeCOL3], [SizeCOL4], [SizeCOL5])) as pvt 
				) a
			    join
				(
				  select * from
				  (
				   select SIZE_SRNO,Sizeval=Replace(SizeCOL,''SizeCOL'',''Sizeval''),quantity 
				   from cte 
				   ) pvt2 
				   PIVOT (sum(quantity) for Sizeval in ([SizeVAL1], [SizeVAL2], [SizeVAL3], [SizeVAL4], [SizeVAL5])) as pvt1 
				) b on a.SIZE_SRNO=b.SIZE_SRNO
				'
			PRINT @dtsql
			EXEC ( @dtsql )   


		 --   SET @CCMD = N'SELECT * 
			--FROM '+@CTABLENAME+' A '
			--PRINT @CCMD
			--EXEC SP_EXECUTESQL @CCMD    

		end
	   END

	   
		SET @CCMD = N'IF OBJECT_ID(''TEMPDB..'+@CTABLENAME+''',''U'') IS NOT NULL
					  DROP TABLE '+@CTABLENAME+''
		PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD


END


/*
exec SP3S_WSLPRINT_DYNAMIC 'JM01120000JM/IS-000006'



*/
