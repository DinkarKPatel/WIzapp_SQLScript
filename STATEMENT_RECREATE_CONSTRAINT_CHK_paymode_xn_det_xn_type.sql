
IF EXISTS (SELECT TOP 1 'U'  FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME ='CHK_paymode_xn_det_xn_type')
BEGIN
    ALTER TABLE [dbo].[paymode_xn_det]  DROP CONSTRAINT [CHK_paymode_xn_det_xn_type]
	ALTER TABLE [dbo].[paymode_xn_det]  WITH NOCHECK ADD  CONSTRAINT [CHK_paymode_xn_det_xn_type] CHECK  (([xn_type]='ARC' OR [xn_type]='SLS' OR [xn_type]='WSL' OR [xn_type]='WSR'))

END

