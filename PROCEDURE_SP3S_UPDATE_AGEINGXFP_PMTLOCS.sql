CREATE PROCEDURE SP3S_UPDATE_AGEINGXFP_PMTLOCS
@dFromDt DATETIME,
@dToDt DATETIME,
@bCalledFromPostMonitor BIT=0
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@cPmtTableName VARCHAR(200),@cStr varchar(100),@cStep VARCHAR(5),@cErrormsg VARCHAR(MAX),@dXnDt DATETIME

BEGIN TRY
	WHILE @dFromDt<=@dToDt+1
	BEGIN
		SET @cStep='10'
		SET @dXnDt=@dFromDt

		IF @dXnDt<@dToDt+1
			SET @cPmtTablename=db_name()+'_pmt.dbo.pmtlocs_'+convert(varchar,@dXnDt,112)
		else
			SET @cPmtTablename='pmt01106'
		
		set @cStr=convert(varchar,@dXndt,110)+'@'+convert(varchar,getdate(),113)
		PRINT 'Updating xfp for Date:'+@cStr
		SET @cCmd=N'UPDATE a WITH (ROWLOCK) SET xfer_price=sx.xfer_price,challan_receipt_dt=sx.receipt_dt
					FROM '+@cPmtTablename+'	a
					JOIN  sku_xfp sx (NOLOCK) ON sx.product_code=a.product_code AND sx.dept_id=a.dept_id'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
				
		
		set @cStr=convert(varchar,@dXndt,110)+'@'+convert(varchar,getdate(),113)
		PRINT 'Updating Ageing for Date:'+@cStr
		SET @cStep='20'
		SET @cCmd=N'UPDATE  a SET purchase_ageing_days=DATEDIFF(dd,purchase_receipt_dt,'''+convert(varchar,@dXnDt,110)+'''),
					shelf_ageing_days=DATEDIFF(dd,a.challan_receipt_Dt,'''+convert(varchar,@dXnDt,110)+''')
					FROM '+@cPmtTablename+'	a WITH (ROWLOCK)
					JOIN sku_names sn(NOLOCK) ON sn.product_code=a.product_code'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

		set @cStr=convert(varchar,@dXndt,110)+'@'+convert(varchar,getdate(),113)
		PRINT 'Completed updation for Date:'+@cStr
		
		IF @bCalledFromPostMonitor=1
			BREAK
		SET @dFromDt=@dFromDt+1
	END

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_UPDATE_AGEINGXFP_PMTLOCS at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
	SELECT ISNULL(@cErrormsg,'') errmsg
END