CREATE PROCEDURE SP3S_DELIVERY_RACKS_DETAILS--(LocId 3 digit change by Sanjay:05-11-2024)
(
	@nQueryID INT,
	@cLoc_ID VARCHAR(4),
	@cWhere VARCHAR(50),
	@cFinYear VARCHAR(10)='',
	@cLoginDate	DATETIME=''
)
AS
BEGIN
	DECLARE @cCMD NVARCHAR(MAX)
	IF @nQueryID=1
	BEGIN
		SELECT DISTINCT A.RACK_NO,ISNULL(rps_cm_no,'') AS  rps_cm_no,b.last_update,DBO.FN_CONVERTINTOHOURSMINS(DATEDIFF(MI,b.LAST_UPDATE,GETDATE()))  AS DELAY
		FROM
		(
			SELECT RACK_NO
			FROM loc_delivery_racks (NOLOCK) 
			WHERE DEPT_ID=@cLoc_ID
			AND @cWhere='' 
			UNION
			SELECT RACK_NO
			FROM delivery_racks_issue_details a (NOLOCK)
			JOIN rps_mst b (NOLOCK) ON b.cm_id=a.rps_id
			WHERE b.location_Code=@cLoc_ID
		)A 
		LEFT OUTER JOIN 
		(SELECT a.last_update,rack_no,rps_cm_no FROM  delivery_racks_issue_details a (NOLOCK)  JOIN rps_mst b (NOLOCK) ON b.cm_id=a.rps_id
			WHERE b.location_Code=@cLoc_ID) b ON B.rack_no=A.rack_no 
	
	END
	ELSE IF @nQueryID=2
	BEGIN
		SELECT A.RACK_NO
		FROM loc_delivery_racks A (NOLOCK)
		WHERE DEPT_ID=@cLoc_ID
		AND @cWhere=''
		ORDER BY A.RACK_NO
	END
	ELSE IF @nQueryID=3
	BEGIN
		SET @cCMD=N'SELECT TOP 50 A.CM_NO AS rps_cm_no
		FROM RPS_MST A (NOLOCK)
		LEFT JOIN delivery_racks_issue_details b (NOLOCK) ON b.rps_id=a.cm_id
		WHERE b.rps_id IS NULL AND A.CANCELLED=0 
		AND CONVERT(VARCHAR(20),A.CM_DT,105)='''+CONVERT(VARCHAR(20),@cLoginDate,105)+'''
		AND A.FIN_YEAR='''+ @cFinYear+''' 
		AND a.location_code=''' + @cLoc_ID +''' 
		AND  A.cm_no LIKE '''+@cWhere+ ''' 
		ORDER BY A.cm_no'
		PRINT @cCMD
		
		EXEC SP_EXECUTESQL @cCMD
	END
	ELSE IF @nQueryID=33
	BEGIN
		

		SET @cCMD=N'SELECT a.cm_no AS rps_cm_no 
		from  cmm01106 a (NOLOCK) 
		JOIN  RPS_MST b (NOLOCK) ON b.REF_cm_id=a.cm_id
		JOIN delivery_racks_issue_details e (NOLOCK) ON e.rps_id=b.cm_id
		LEFT JOIN delivery_racks_delivered_history d (NOLOCK) ON d.cm_id=a.cm_id
		WHERE  a.CANCELLED=0 AND d.cm_id IS NULL 
		AND A.FIN_YEAR='''+ @cFinYear+''' 
		AND a.location_code=''' + @cLoc_ID +''' 
		group by a.cm_no
		ORDER BY A.cm_no'
		PRINT @cCMD
		EXEC SP_EXECUTESQL @cCMD
	END
END