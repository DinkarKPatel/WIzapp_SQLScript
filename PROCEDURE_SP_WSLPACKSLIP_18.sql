CREATE PROCEDURE SP_WSLPACKSLIP_18
(
	@CWHERE  VARCHAR(500) = ''
)
AS
BEGIN
	SELECT *,CAST('' AS VARCHAR(50)) AS SP_ID FROM xnBoxDetails WHERE xn_type='WPS' AND Ref_memo_id=@CWHERE
END