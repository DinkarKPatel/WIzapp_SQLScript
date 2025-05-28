CREATE PROCEDURE SP3S_REBUILD_optimized_schemes
AS
BEGIN

	declare @cErrormsg varchar(max)
	exec SP3S_POPULATE_SKUACTIVETITLES
	@cErrormsg=@cErrormsg output

	select @cErrormsg errmsg

END