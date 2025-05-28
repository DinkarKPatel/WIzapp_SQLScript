CREATE PROCEDURE SP3S_GET_XPERTREP_OHColsInfo
@cRepId VARCHAR(50),
@cOhColsStru VARCHAR(2000) OUTPUT
AS
BEGIN	
		DECLARE @cUpdCols VARCHAR(2000),@COUTPUT NVARCHAR(MAX),	@CCMD NVARCHAR(MAX),@bOhAmtColFound BIT,
				@bOhGstColFound BIT,@cXnType VARCHAR(100),@cStruColName VARCHAR(200)
				
		SELECT @CCMD='',@COUTPUT='',@cOhColsStru=''
		SELECT TOP 1 @cXnType=xn_type FROM rep_det_xntypes (NOLOCK) where rep_id=@cRepId
		
		SET @cOhColsStru='CONVERT(VARCHAR(30),'''') OH_NAME'
		IF EXISTS (SELECT TOP 1 key_col FROM #rep_det WHERE key_col='OH_AMOUNT')
			SET @cOhColsStru=@cOhColsStru+',CONVERT(NUMERIC(10,2),0) [oh amount]'

		IF EXISTS (SELECT TOP 1 key_col FROM #rep_det WHERE key_col='OH_GST')
		BEGIN
			IF NOT EXISTS (SELECT TOP 1 key_col FROM #rep_det WHERE key_col='HSN_CODE')
				SET @cOhColsStru=@cOhColsStru+',CONVERT(VARCHAR(50),'''') AS HSN_CODE'

			IF NOT EXISTS (SELECT TOP 1 key_col FROM #rep_det WHERE key_col='GST_PCT')
				SET @cOhColsStru=@cOhColsStru+',CONVERT(NUMERIC(6,2),0) AS [Gst%]'

			IF NOT EXISTS (SELECT TOP 1 key_col FROM #rep_det WHERE key_col='Taxable_Value')
				SET @cOhColsStru=@cOhColsStru+',CONVERT(NUMERIC(10,2),0) AS [Taxable Value]'

			IF NOT EXISTS (SELECT TOP 1 key_col FROM #rep_det WHERE key_col='IGST_AMOUNT')
				SET @cOhColsStru=@cOhColsStru+',CONVERT(NUMERIC(10,2),0) AS [igst amount]'

			IF NOT EXISTS (SELECT TOP 1 key_col FROM #rep_det WHERE key_col='CGST_AMOUNT')
				SET @cOhColsStru=@cOhColsStru+',CONVERT(NUMERIC(10,2),0) AS [cgst amount]'

			IF NOT EXISTS (SELECT TOP 1 key_col FROM #rep_det WHERE key_col='SGST_AMOUNT')
				SET @cOhColsStru=@cOhColsStru+',CONVERT(NUMERIC(10,2),0) AS [sgst amount]'
	    END
			
			
END