
create TRIGGER [DBO].[TRG_INSERT_ART_NAMES] ON [DBO].[ARTICLE]  
FOR INSERT
AS  
BEGIN
	IF EXISTS (SELECT TOP 1 article_code FROM  art_diff (NOLOCK) WHERE sp_id=@@spid)	
  		DELETE FROM art_diff WITH (ROWLOCK) WHERE sp_id=@@spid			
	
	INSERT art_diff (article_code,diff_type,sp_id)
	SELECT article_code,0 as diff_type,@@spid sp_id FROM INSERTED

	EXEC SP3S_CREATE_ARTNAMES 2
END

