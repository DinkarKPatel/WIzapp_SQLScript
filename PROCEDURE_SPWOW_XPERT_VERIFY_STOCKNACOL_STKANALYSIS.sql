CREATE PROCEDURE SPWOW_XPERT_VERIFY_STOCKNACOL_STKANALYSIS
@cRepTempTable VARCHAR(200)
AS
BEGIN
	DECLARE @cEnforceStockNaColumn VARCHAR(2),@cCalculativeColsExpr VARCHAR(2000),@cCmd NVARCHAR(MAX),@cStockNaColHeader VARCHAR(200),@bStockNaColDropped BIT

	SELECT TOP 1 @cEnforceStockNaColumn=value FROM config(NOLOCK) WHERE config_option='ENFORCE_STOCKNA_COLUMN_STKANALYSIS'
	IF ISNULL(@cEnforceStockNaColumn,'')='1'
	BEGIN
		SELECT TOP 1 @cStockNaColHeader=col_header FROM #wow_xpert_rep_det WHERE column_id='C0042'
		IF ISNULL(@cStockNaColHeader,'')<>''
		BEGIN
			
			SELECT 	@cCalculativeColsExpr=coalesce(@cCalculativeColsExpr+' OR ','')+'ISNULL(['+col_header+'],0)<>0' FROM #wow_xpert_rep_det
			WHERE calculative_col=1

			SET @bStockNaColDropped=0

			SET @cCmd=N'IF NOT EXISTS (SELECT TOP 1 * FROM '+@cRepTempTable+' WHERE ISNULL(['+@cStockNaColHeader+'],''0'')=''1'' AND ('+@cCalculativeColsExpr+'))
						BEGIN
						   ALTER TABLE '+@cRepTempTable+' DROP COLUMN ['+@cStockNaColHeader+']
						   SET @bStockNaColDropped=1
						END'
			print @cCmd
			EXEC SP_EXECUTESQL @cCmd,N'@bStockNaColDropped BIT OUTPUT',@bStockNaColDropped OUTPUT

			IF @bStockNaColDropped=1
			BEGIN
				DELETE FROM #wow_xpert_rep_det WHERE column_id='C0042'
			END
			ELSE
			BEGIN
				SET @cCmd=N'UPDATE '+@cRepTempTable+' SET ['+@cStockNaColHeader+']=(CASE WHEN ISNULL(['+@cStockNaColHeader+'],''0'')<>''0'' THEN ''Yes'' ELSE ''No'' END)'
				EXEC SP_EXECUTESQL @cCmd
			END
		END
	END
END