CREATE PROCEDURE SP3S_VALIDATE_GVSELLING_SINGLECHANNEL
(
	@NSPID VARCHAR(40),
	@bCalledfromSaveTran BIT=0
)
AS
BEGIN
BEGIN TRY
		DECLARE @cStep VARCHAR(4),@cTrappedErrormsg VARCHAR(1000),@cErrormsg VARCHAR(1000)
		---gv_type 1.Sellable 2.freebie
		
		--INSERT MIRROR_gv_call (sp_id,calledfromsavetran)
		--select @NSPID,@bCalledfromSaveTran
		
		SET @CSTEP=10

		UPDATE a SET errmsg='Invalid gv no. mentioned......Please check'
		FROM validate_arc_gvsale_upload a WITH (ROWLOCK)
		LEFT JOIN sku_gv_mst b (NOLOCK) ON a.gv_srno=b.gv_srno
		WHERE a.sp_id=@nSpId AND B.gv_srno IS NULL
		
		SET @CSTEP=12

		UPDATE a SET errmsg='Gv(s) marked as Freebies cannot be sold......Please check'
		FROM validate_arc_gvsale_upload a WITH (ROWLOCK)
		JOIN sku_gv_mst b (NOLOCK) ON a.gv_srno=b.gv_srno
		WHERE a.sp_id=@nSpId AND ISNULL(gv_type,0)=2 AND isnull(errmsg,'')=''

		SET @CSTEP=15
		UPDATE a SET errmsg='(1)Gv has already been sold against Memo no :'+ adv_rec_no+' Dated :'+CONVERT(VARCHAR,adv_rec_dt,105)+
					   ' at Location Id :'+LEFT(c.adv_rec_no,2)+' ......Please check'
		FROM validate_arc_gvsale_upload a WITH (ROWLOCK)
		JOIN arc_gvsale_details b (NOLOCK) ON a.gv_srno=b.gv_srno
		JOIN arc01106 c (NOLOCK) ON c.adv_rec_id=b.adv_rec_id
		WHERE a.sp_id=@nSpId AND cancelled=0 AND isnull(errmsg,'')=''
		AND a.memo_id<>b.adv_rec_id

		SET @CSTEP=20
		UPDATE a SET errmsg='(2)Gv has already been sold against Memo Id :'+ b.memo_id+' Dated :'+convert(varchar,sold_on,105)+
					   ' at Location Id :'+LEFT(b.memo_id,2)+'  .....Please check'
		FROM validate_arc_gvsale_upload a WITH (ROWLOCK)
		JOIN gvsale_pos_validate b (nolock) on a.gv_srno=b.gv_srno
		WHERE a.sp_id=@nSpId AND isnull(errmsg,'')=''

		SET @CSTEP=30
		SELECT TOP 1 @cTrappedErrormsg=errmsg FROM validate_arc_gvsale_upload (NOLOCK)
		WHERE sp_id=@nSpId AND ISNULL(errmsg,'')<>''
		IF ISNULL(@cTrappedErrormsg,'')<>''
			GOTO END_PROC
		
		IF @bCalledfromSaveTran=0
		BEGIN
			BEGIN TRAN

			SET @CSTEP=40
			INSERT gvsale_pos_validate	( gv_srno, memo_id,sold_on )  
			SELECT gv_srno, memo_id ,getdate() FROM validate_arc_gvsale_upload (NOLOCK)
			WHERE sp_id=@nSpId
		END

		GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_VALIDATE_GVSELLING_SINGLECHANNEL at step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
	

	IF ISNULL(@cErrormsg,'')<>''
		UPDATE validate_arc_gvsale_upload WITH (ROWLOCK) SET errmsg=@cErrormsg
		WHERE sp_id=@nSpId
	ELSE
		UPDATE validate_arc_gvsale_upload WITH (ROWLOCK) SET errmsg=''
		WHERE sp_id=@nSpId AND errmsg IS NULL
	
	IF @bCalledfromSaveTran=0
	BEGIN	
		IF @@TRANCOUNT>0 
		BEGIN
			IF ISNULL(@cErrormsg,'')=''
				SELECT TOP 1 @cErrormsg=errmsg FROM validate_arc_gvsale_upload (NOLOCK)
				WHERE sp_id=@nSpId AND ISNULL(errmsg,'')<>''
		
			IF ISNULL(@cErrormsg,'')=''
				COMMIT
			ELSE
				ROLLBACK
		END

		SELECT * FROM validate_arc_gvsale_upload(NOLOCK) WHERE sp_id=@nSpId

		DELETE FROM validate_arc_gvsale_upload WITH (ROWLOCK) WHERE sp_id=@nSpId
	END
END