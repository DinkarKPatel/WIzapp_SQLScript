CREATE PROCEDURE SP_WSLINV_28
(
  @CMEMOID VARCHAR(50)=''
)
as
begin
     
	 
	 SELECT *,CAST('' AS VARCHAR(50)) AS SP_ID FROM xnBoxDetails WHERE xn_type='WSL' AND Ref_memo_id=@CMEMOID   


end