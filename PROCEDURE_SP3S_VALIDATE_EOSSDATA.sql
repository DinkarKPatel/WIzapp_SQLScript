CREATE PROCEDURE SP3S_VALIDATE_EOSSDATA
@nMode INT=1,
@bChkFinalData BIT=0,
@cSchDetRowId VARCHAR(50)='',
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN
	DECLARE @cSchemeName varchar(100)
	print 'SP3S_VALIDATE_EOSSDATA-1'

	IF @cSchDetRowId<>''
	BEGIN
		print 'SP3S_VALIDATE_EOSSDATA-9'
		IF EXISTS (SELECT TOP 1 a.row_id FROM SCHEME_SETUP_DET a (NOLOCK)
					LEFT JOIN SCHEME_SETUP_ALLMASTERS b (NOLOCK) ON a.row_id=b.SCHEME_SETUP_DET_ROW_ID
					WHERE a.row_id=@cSchDetRowId AND ((a.filter_mode=6 AND a.promotional_scheme_id<>'SCH0015') OR
					(a.filter_mode=3 AND a.promotional_scheme_id='SCH0015')) AND b.ROW_ID IS NULL)
		BEGIN
			print 'SP3S_VALIDATE_EOSSDATA-10'
			SELECT TOP 1 @cSchemeName=a.scheme_name FROM SCHEME_SETUP_DET a (NOLOCK)
			LEFT JOIN SCHEME_SETUP_ALLMASTERS b (NOLOCK) ON a.row_id=b.SCHEME_SETUP_DET_ROW_ID
			WHERE a.row_id=@cSchDetRowId AND ((a.filter_mode=6 AND a.promotional_scheme_id<>'SCH0015') OR
					(a.filter_mode=3 AND a.promotional_scheme_id='SCH0015')) AND b.ROW_ID IS NULL

			SET @cErrormsg='Para combination Buy data found blank for Scheme: '+@cSchemeName+' Cannot Save..'
			GOTO END_PROC
		END
			
		print 'SP3S_VALIDATE_EOSSDATA-11'
		IF EXISTS (SELECT TOP 1 a.row_id FROM SCHEME_SETUP_DET a (NOLOCK)
					LEFT JOIN SCHEME_SETUP_ALLMASTERS_config b (NOLOCK) ON a.row_id=b.SCHEME_SETUP_DET_ROW_ID
					AND b.SCHEME_SETUP_FLAG=1
					WHERE a.row_id=@cSchDetRowId AND ((a.filter_mode=6 AND a.promotional_scheme_id<>'SCH0015') OR
					(a.filter_mode=3 AND a.promotional_scheme_id='SCH0015')) AND b.SCHEME_SETUP_DET_ROW_ID IS NULL)
		BEGIN
			print 'SP3S_VALIDATE_EOSSDATA-12'
			SELECT TOP 1 @cSchemeName=a.scheme_name FROM SCHEME_SETUP_DET a (NOLOCK)
			LEFT JOIN SCHEME_SETUP_ALLMASTERS_config b (NOLOCK) ON a.row_id=b.SCHEME_SETUP_DET_ROW_ID
			AND b.SCHEME_SETUP_FLAG=1
			WHERE a.row_id=@cSchDetRowId AND ((a.filter_mode=6 AND a.promotional_scheme_id<>'SCH0015') OR
					(a.filter_mode=3 AND a.promotional_scheme_id='SCH0015')) AND b.SCHEME_SETUP_DET_ROW_ID IS NULL

			SET @cErrormsg='Para combination Config found blank for Scheme: '+@cSchemeName+' Cannot Save..'
			GOTO END_PROC
		END
			
		IF EXISTS (SELECT TOP 1 a.row_id FROM SCHEME_SETUP_DET a (NOLOCK)
					LEFT JOIN SCHEME_SETUP_ALLMASTERS b (NOLOCK) ON a.row_id=b.SCHEME_SETUP_DET_ROW_ID
					AND B.source_type=2
					WHERE a.row_id=@cSchDetRowId AND a.get_filter_mode=3 and a.promotional_scheme_id='SCH0015' AND b.ROW_ID IS NULL)
		BEGIN
			SELECT TOP 1 @cSchemeName=a.scheme_name  FROM SCHEME_SETUP_DET a (NOLOCK)
			LEFT JOIN SCHEME_SETUP_ALLMASTERS b (NOLOCK) ON a.row_id=b.SCHEME_SETUP_DET_ROW_ID AND B.source_type=2
			WHERE a.row_id=@cSchDetRowId AND a.get_filter_mode=3 and a.promotional_scheme_id='SCH0015' AND b.ROW_ID IS NULL
				
			SET @cErrormsg='Para combination Get data found blank for Scheme: '+@cSchemeName+' Cannot Save..'
			GOTO END_PROC
		END
		
		GOTO END_PROC
	END

	IF EXISTS (SELECT TOP 1 row_id FROM MSTEOSS_SCHEME_SETUP_DET_MIRROR (NOLOCK) WHERE filter_mode=6 OR  
	(promotional_scheme_id='SCH0015' and (get_filter_mode=3 or filter_mode=3)))
	BEGIN
		print 'SP3S_VALIDATE_EOSSDATA-2'
		IF @bChkFinalData=0
		BEGIN
			print 'SP3S_VALIDATE_EOSSDATA-3'
			IF EXISTS (SELECT TOP 1 a.row_id FROM MSTEOSS_SCHEME_SETUP_DET_MIRROR a (NOLOCK)
						LEFT JOIN MSTEOSS_SCHEME_SETUP_ALLMASTERS_MIRROR b (NOLOCK) ON a.row_id=b.SCHEME_SETUP_DET_ROW_ID
						WHERE ((a.filter_mode=6 AND a.promotional_scheme_id<>'SCH0015') OR
					(a.filter_mode=3 AND a.promotional_scheme_id='SCH0015')) AND b.ROW_ID IS NULL)
			BEGIN
				print 'SP3S_VALIDATE_EOSSDATA-4'
				SELECT TOP 1 @cSchemeName=a.scheme_name FROM MSTEOSS_SCHEME_SETUP_DET_MIRROR a (NOLOCK)
				LEFT JOIN MSTEOSS_SCHEME_SETUP_ALLMASTERS_MIRROR b (NOLOCK) ON a.row_id=b.SCHEME_SETUP_DET_ROW_ID
				WHERE ((a.filter_mode=6 AND a.promotional_scheme_id<>'SCH0015') OR
					(a.filter_mode=3 AND a.promotional_scheme_id='SCH0015'))

				print 'SP3S_VALIDATE_EOSSDATA-4.5:'+@cSchemeName
				SET @cErrormsg='Para combination Buy Temp data found blank for Scheme: '+@cSchemeName
				GOTO END_PROC
			END
			
			print 'SP3S_VALIDATE_EOSSDATA-5'
			IF EXISTS (SELECT TOP 1 a.row_id FROM MSTEOSS_SCHEME_SETUP_DET_MIRROR a (NOLOCK)
						LEFT JOIN MSTEOSS_SCHEME_SETUP_ALLMASTERS_config_MIRROR b (NOLOCK) ON a.row_id=b.SCHEME_SETUP_DET_ROW_ID
						AND b.SCHEME_SETUP_FLAG=1
						WHERE ((a.filter_mode=6 AND a.promotional_scheme_id<>'SCH0015') OR
					(a.filter_mode=3 AND a.promotional_scheme_id='SCH0015')) AND b.SCHEME_SETUP_DET_ROW_ID IS NULL)
			BEGIN
				print 'SP3S_VALIDATE_EOSSDATA-6'
				SELECT TOP 1 @cSchemeName=a.scheme_name FROM MSTEOSS_SCHEME_SETUP_DET_MIRROR a (NOLOCK)
				LEFT JOIN MSTEOSS_SCHEME_SETUP_ALLMASTERS_config_MIRROR b (NOLOCK) ON a.row_id=b.SCHEME_SETUP_DET_ROW_ID
				AND b.SCHEME_SETUP_FLAG=1
				WHERE ((a.filter_mode=6 AND a.promotional_scheme_id<>'SCH0015') OR
					(a.filter_mode=3 AND a.promotional_scheme_id='SCH0015')) AND b.SCHEME_SETUP_DET_ROW_ID IS NULL

				SET @cErrormsg='Para combination Temp Config found blank for Scheme: '+@cSchemeName
				GOTO END_PROC
			END
			
			print 'SP3S_VALIDATE_EOSSDATA-7'
			IF EXISTS (SELECT TOP 1 a.row_id FROM MSTEOSS_SCHEME_SETUP_DET_MIRROR a (NOLOCK)
						LEFT JOIN MSTEOSS_SCHEME_SETUP_ALLMASTERS_MIRROR b (NOLOCK) ON a.row_id=b.SCHEME_SETUP_DET_ROW_ID and b.source_type=2
						WHERE a.get_filter_mode=3 and a.promotional_scheme_id='SCH0015' AND b.ROW_ID IS NULL)
			BEGIN
				print 'SP3S_VALIDATE_EOSSDATA-8'
				SELECT TOP 1 @cSchemeName=a.scheme_name FROM MSTEOSS_SCHEME_SETUP_DET_MIRROR a (NOLOCK)
				LEFT JOIN MSTEOSS_SCHEME_SETUP_ALLMASTERS_MIRROR b (NOLOCK) ON a.row_id=b.SCHEME_SETUP_DET_ROW_ID and b.source_type=2
				WHERE a.get_filter_mode=3 and a.promotional_scheme_id='SCH0015' AND b.ROW_ID IS NULL

				SET @cErrormsg='Para combination Get Temp data cannot be blank for Scheme: '+@cSchemeName
				GOTO END_PROC
			END
		END
		ELSE
		IF @bChkFinalData=1
		BEGIN
			print 'SP3S_VALIDATE_EOSSDATA-9'
			IF EXISTS (SELECT TOP 1 a.row_id FROM MSTEOSS_SCHEME_SETUP_DET_MIRROR a (NOLOCK)
						LEFT JOIN SCHEME_SETUP_ALLMASTERS b (NOLOCK) ON a.row_id=b.SCHEME_SETUP_DET_ROW_ID
						WHERE ((a.filter_mode=6 AND a.promotional_scheme_id<>'SCH0015') OR
					(a.filter_mode=3 AND a.promotional_scheme_id='SCH0015')) AND b.ROW_ID IS NULL)
			BEGIN
				print 'SP3S_VALIDATE_EOSSDATA-10'
				SELECT TOP 1 @cSchemeName=a.scheme_name FROM MSTEOSS_SCHEME_SETUP_DET_MIRROR a (NOLOCK)
				LEFT JOIN SCHEME_SETUP_ALLMASTERS b (NOLOCK) ON a.row_id=b.SCHEME_SETUP_DET_ROW_ID
				WHERE ((a.filter_mode=6 AND a.promotional_scheme_id<>'SCH0015') OR
					(a.filter_mode=3 AND a.promotional_scheme_id='SCH0015')) AND b.ROW_ID IS NULL

				SET @cErrormsg='Para combination Buy data found blank for Scheme: '+@cSchemeName
				GOTO END_PROC
			END
			
			print 'SP3S_VALIDATE_EOSSDATA-11'
			IF EXISTS (SELECT TOP 1 a.row_id FROM MSTEOSS_SCHEME_SETUP_DET_MIRROR a (NOLOCK)
						LEFT JOIN SCHEME_SETUP_ALLMASTERS_config b (NOLOCK) ON a.row_id=b.SCHEME_SETUP_DET_ROW_ID
						AND b.SCHEME_SETUP_FLAG=1
						WHERE ((a.filter_mode=6 AND a.promotional_scheme_id<>'SCH0015') OR
					(a.filter_mode=3 AND a.promotional_scheme_id='SCH0015'))  AND b.SCHEME_SETUP_DET_ROW_ID IS NULL)
			BEGIN
				print 'SP3S_VALIDATE_EOSSDATA-12'
				SELECT TOP 1 @cSchemeName=a.scheme_name FROM MSTEOSS_SCHEME_SETUP_DET_MIRROR a (NOLOCK)
				LEFT JOIN SCHEME_SETUP_ALLMASTERS_config b (NOLOCK) ON a.row_id=b.SCHEME_SETUP_DET_ROW_ID
				AND b.SCHEME_SETUP_FLAG=1
				WHERE ((a.filter_mode=6 AND a.promotional_scheme_id<>'SCH0015') OR
					(a.filter_mode=3 AND a.promotional_scheme_id='SCH0015')) AND b.SCHEME_SETUP_DET_ROW_ID IS NULL

				SET @cErrormsg='Para combination Config found blank for Scheme: '+@cSchemeName
				GOTO END_PROC
			END
			
			IF EXISTS (SELECT TOP 1 a.row_id FROM MSTEOSS_SCHEME_SETUP_DET_MIRROR a (NOLOCK)
						LEFT JOIN SCHEME_SETUP_ALLMASTERS b (NOLOCK) ON a.row_id=b.SCHEME_SETUP_DET_ROW_ID
						AND B.source_type=2
						WHERE a.get_filter_mode=3 and a.promotional_scheme_id='SCH0015' AND b.ROW_ID IS NULL)
			BEGIN
				SELECT TOP 1 @cSchemeName=a.scheme_name  FROM MSTEOSS_SCHEME_SETUP_DET_MIRROR a (NOLOCK)
				LEFT JOIN SCHEME_SETUP_ALLMASTERS b (NOLOCK) ON a.row_id=b.SCHEME_SETUP_DET_ROW_ID AND B.source_type=2
				WHERE a.get_filter_mode=3 and a.promotional_scheme_id='SCH0015' AND b.ROW_ID IS NULL
				
				SET @cErrormsg='Para combination Get data cannot be blank for Scheme: '+@cSchemeName
				GOTO END_PROC
			END
		END

	END

END_PROC:
END
