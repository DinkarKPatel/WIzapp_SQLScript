CREATE Procedure sp3s_buildpmt_single
(
  @dxndt datetime='2022-08-20'
)
as
begin
               

			   DECLARE @PMTTABLE VARCHAR(100),@cDbName varchar(100),@cCmd nvarchar(max)
			   set @cDbName=db_name()

			   SET @PMTTABLE=db_name()+'_pmt.dbo.pmtlocs_'+CONVERT(VARCHAR,@dxndt,112)  

               IF OBJECT_ID(@PMTTABLE,'U') IS NULL                              
			   BEGIN      
				   EXEC  SP3S_CREATE_LOCWISEPMTXNS_STRU    @cDbName=@cDbName,    @dXnDt=@dXnDt,    @bInsPmt=0,    @bDonotChkDb=1                              
			   END    


				set @cCmd=' Truncate table  '+@PMTTABLE+' '
				print @CCMD
			    exec sp_executesql @CCMD

			    SET @cCmd=N'insert into '+@PMTTABLE+'(DEPT_ID,PRODUCT_CODE,BIN_ID,cbs_qty)
				select a.dept_id, product_code,a.bin_id, sum(case when xn_type in (''PFI'', ''WSR'', ''APR'', ''CHI'', ''WPR'', ''OPS'', ''DCI'', ''SCF'', ''PUR'', ''UNC'', ''SLR'',
				''JWR'',''DNPR'',''TTM'',''API'',''PRD'', ''PFG'', ''BCG'',''MRP'',''PSB'',''JWR'',''MIR'',''GRNPSIN'',''MAQ'',''OLOAQ'',''CNPI'') 
				then 1 else -1 end * xn_qty) CBSQty
				from VW_XNSREPS a (nolock) 
				where  xn_type not in (''TRI'', ''TRO'',''sac'',''sau'',''saum'',''sacm'') 
				and CONVERT(DATE, XN_DT) <='''+CONVERT(varchar,@dxndt,112)+''' 
				and isnull(a.PRODUCT_CODE,'''') <>''''
				group by a.dept_id, product_code,a.bin_id 
				having sum(case when xn_type in (''PFI'', ''WSR'', ''APR'', ''CHI'', ''WPR'', ''OPS'', ''DCI'', ''SCF'', ''PUR'', ''UNC'', ''SLR'',
				''JWR'',''DNPR'',''TTM'',''API'',''PRD'', ''PFG'', ''BCG'',''MRP'',''PSB'',''JWR'',''MIR'',''GRNPSIN'',''MAQ'',''OLOAQ'',''CNPI'') 
				then 1 else -1 end * xn_qty)<>0'
				PRINT @cCmd
				EXEC SP_EXECUTESQL @cCmd

				 SET @cCmd=N' Update a set 
				 purchase_ageing_days=(CASE WHEN isnull(purchase_receipt_dt,'''')='''' then 1 when ABS(DATEDIFF(dd,purchase_receipt_dt,'''+convert(varchar,@dxndt,110)+'''))>99999   
				 THEN 99999 ELSE DATEDIFF(dd,purchase_receipt_dt,'''+convert(varchar,@dxndt,110)+''') END)  ,  

				 shelf_ageing_days= (CASE WHEN isnull(sx.receipt_Dt,'''')='''' then 1 when  ABS(DATEDIFF(dd,sx.receipt_Dt,'''+convert(varchar,@dxndt,110)+'''))>99999   
				 THEN 99999 ELSE DATEDIFF(dd,sx.receipt_Dt,'''+convert(varchar,@dxndt,110)+''')  END) ,  
				 xfer_price=sx.xfer_price  
				 FROM '+@PMTTABLE+' A 
				 join sku_names sn (NOLOCK) ON sn.product_code=a.product_code  
				 LEFT JOIN  sku_xfp sx (NOLOCK) ON sx.product_code=a.product_code AND sx.dept_id=a.dept_id  
				 '
				 PRINT @cCmd
				EXEC SP_EXECUTESQL @cCmd

		


end

