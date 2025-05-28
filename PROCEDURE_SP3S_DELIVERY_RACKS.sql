CREATE PROCEDURE SP3S_DELIVERY_RACKS--(LocId 3 digit change by Sanjay:05-11-2024)
@nQueryId NUMERIC(1,0),
@cWhere VARCHAR(50)='',
@cFinYear VARCHAR(5)='',
@cRacknoPara VARCHAR(50)='',
@dLoginDt DATETIME=''
AS
BEGIN

BEGIN TRY
	DECLARE @cSearchMemo VARCHAR(50),@cErrormsg VARCHAR(500),@cAvailableRack VARCHAR(50),@cStep VARCHAR(4),
			@bMentionrack BIT,@cLocationCode VARCHAR(4)

	SET @cStep='10'
	SET @cErrormsg=''

	IF @nQueryId=1
	BEGIN
		SET @cStep='20'
		SELECT TOP 1 @cSearchMemo=cm_no,@cLocationCode=location_code FROM rps_mst (NOLOCK) WHERE cm_no=@cWhere

		IF ISNULL(@cSearchMemo,'')=''
		BEGIN
			SET @cErrormsg='Invalid Packs Slip no..... Please check'		
			GOTO END_PROC
		END
		
		SET @cStep='30'
		IF EXISTS (SELECT TOP 1 * from delivery_racks_issue_details (NOLOCK) WHERE rps_cm_no=@cWhere)
		BEGIN
			SET @cErrormsg='Pack slip already assigned to a Rack..... Please check'		
			GOTO END_PROC
		END

		IF @cRacknoPara=''
		BEGIN
			SET @cStep='40'
			SELECT TOP 1 @cAvailableRack=a.rack_no FROM loc_delivery_racks a (NOLOCK)
			LEFT JOIN  delivery_racks_issue_details b (NOLOCK) ON a.rack_no=b.rack_no
			WHERE a.dept_id=@cLocationCode AND b.rack_no IS NULL

			SET @cStep='45'
			IF ISNULL(@cAvailableRack,'')=''
			BEGIN
				SET @cErrormsg='No Rack is currently available..... Please mention'		
				SET @bMentionrack=1
				GOTO END_PROC
			END
		END
		ELSE
			SET @cAvailableRack=@cRacknoPara
				
	END
	
	IF @nQueryId=2
	BEGIN
		SET @cStep='50'
		SELECT TOP 1 @cSearchMemo=cm_no,@cLocationCode=location_code FROM cmm01106 (NOLOCK) WHERE cm_no=@cWhere

		IF ISNULL(@cSearchMemo,'')=''
		BEGIN
			SET @cErrormsg='Invalid Bill no..... Please check'		
			GOTO END_PROC
		END

		SET @cStep='55'
		SET @cSearchMemo=''

		SELECT  top 1 @cSearchMemo=d.cm_no 
		FROM delivery_racks_issue_details a (NOLOCK)
		JOIN rps_mst b (NOLOCK) ON b.CM_NO=a.rps_cm_no
		JOIN cmm01106 d (NOLOCK) ON d.cm_id=b.ref_CM_ID
		WHERE d.cm_no=@cWhere AND d.fin_year=@cFinYear
		
		SET @cStep='60'
		IF ISNULL(@cSearchMemo,'')=''
		BEGIN
			SET @cErrormsg='No Packet available for Delivery against this Bill..... Please check'		
			GOTO END_PROC
		END

		SET @cStep='65'
		SELECT d.cm_id,d.cm_no,b.cm_no pack_slip_no,rack_no,'' errmsg ,isnull(@bMentionrack,0) mention_rack
		FROM delivery_racks_issue_details a (NOLOCK)
		JOIN rps_mst b (NOLOCK) ON b.CM_id=a.rps_id
		JOIN cmm01106 d (NOLOCK) ON d.cm_id=b.ref_CM_ID
		WHERE d.cm_no=@cWhere AND d.fin_year=@cFinYear

		GOTO END_PROC
	END

LAST:

	BEGIN TRAN
	
	DECLARE @dDate DATETIME
	IF @nQueryId=1		
	BEGIN
		SET @cStep='80'
		set @dDate=getdate()
		INSERT delivery_racks_issue_details (rps_cm_no,rack_no,last_update,rps_id)
		SELECT @cWhere,@cAvailableRack,@dDate last_update,cm_id FROM rps_mst (NOLOCK)
		WHERE cm_no=@cWhere AND fin_year=@cFinyear

		SET @cStep='85'
		INSERT delivery_racks_receipt_history (rps_cm_no,rack_no,last_update,rps_id)
		SELECT @cWhere,@cAvailableRack,@dDate last_update,cm_id  FROM rps_mst (NOLOCK)
		WHERE cm_no=@cWhere AND fin_year=@cFinyear

	END
	ELSE		
	IF @nQueryId=3
	BEGIN

		SET @cStep='90'
		INSERT delivery_racks_delivered_history (rps_cm_no,rack_no,cm_no,cm_id,last_update)
		SELECT a.rps_cm_no,a.rack_no,d.cm_no,d.cm_id,getdate() last_update FROM delivery_racks_issue_details a (NOLOCK)
		JOIN rps_mst b (NOLOCK) ON b.CM_id=a.rps_id
		JOIN cmm01106 d (NOLOCK) ON d.cm_id=b.ref_CM_ID
		WHERE d.cm_id=@cWhere 


		SET @cStep='95'
		DELETE A FROM delivery_racks_issue_details a (NOLOCK)
		JOIN rps_mst b (NOLOCK) ON b.CM_id=a.rps_id
		JOIN cmm01106 d (NOLOCK) ON d.cm_id=b.ref_CM_ID
		WHERE d.cm_id=@cWhere  AND b.fin_year=@cFinyear

	END
	
	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_DELIVERY_RACKS at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:

IF @@TRANCOUNT>0
BEGIN
	IF ISNULL(@cErrormsg,'')=''
		COMMIT
	ELSE
		ROLLBACK
END	

--IF @nQueryId=1
	SELECT ISNULL(@cErrormsg,'') errmsg,ISNULL(@cAvailableRack,'') rack_no,isnull(@bMentionrack,0) mention_rack
--ELSE
--IF @nQueryId<>2 OR ISNULL(@cErrormsg,'')<>''
--	SELECT ISNULL(@cErrormsg,'') errmsg
END
