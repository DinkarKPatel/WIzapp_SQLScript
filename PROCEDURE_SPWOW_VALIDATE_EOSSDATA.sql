CREATE PROCEDURE SPWOW_VALIDATE_EOSSDATA
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
		IF EXISTS (SELECT TOP 1 a.schemeRowId FROM wow_SchemeSetup_Title_Det a (NOLOCK)
					LEFT JOIN wow_SchemeSetup_para_combination_buy b (NOLOCK) ON a.schemeRowId=b.schemeRowId
					WHERE a.schemeRowId=@cSchDetRowId AND 
					(buyFilterMode=3 and schemeMode=1) AND b.schemeRowId IS NULL)
		BEGIN
			print 'SP3S_VALIDATE_EOSSDATA-10'
			SELECT TOP 1 @cSchemeName=a.schemeName FROM wow_SchemeSetup_Title_Det a (NOLOCK)
			LEFT JOIN wow_SchemeSetup_para_combination_buy b (NOLOCK) ON a.schemeRowId=b.schemeRowId
			WHERE a.schemeRowId=@cSchDetRowId  AND 
					(buyFilterMode=3 and schemeMode=1) AND b.schemeRowId IS NULL

			SET @cErrormsg='Para combination Buy data found blank for Scheme: '+@cSchemeName+' Cannot Save..'
			GOTO END_PROC
		END

		IF EXISTS (SELECT TOP 1 a.schemeRowId FROM wow_SchemeSetup_Title_Det a (NOLOCK)
					LEFT JOIN wow_SchemeSetup_slabs_det b (NOLOCK) ON a.schemeRowId=b.schemeRowId
					WHERE a.schemeRowId=@cSchDetRowId AND a.schemeMode=1 AND b.schemeRowId IS NULL)
		BEGIN
			print 'SP3S_VALIDATE_EOSSDATA-10'
			SELECT TOP 1 @cSchemeName=a.schemeName FROM wow_SchemeSetup_Title_Det a (NOLOCK)
			LEFT JOIN wow_SchemeSetup_slabs_det b (NOLOCK) ON a.schemeRowId=b.schemeRowId
			WHERE a.schemeRowId=@cSchDetRowId AND a.schemeMode=1 AND b.schemeRowId IS NULL

			SET @cErrormsg='Slab details data found blank for Scheme: '+@cSchemeName+' Cannot Save..'
			GOTO END_PROC
		END

		IF EXISTS (SELECT TOP 1 a.schemeRowId FROM wow_SchemeSetup_Title_Det a (NOLOCK)
					LEFT JOIN wow_SchemeSetup_para_combination_flat b (NOLOCK) ON a.schemeRowId=b.schemeRowId
					WHERE a.schemeRowId=@cSchDetRowId AND 
					(buyFilterMode=3 and schemeMode=2 ) AND b.schemeRowId IS NULL)
		BEGIN
			print 'SP3S_VALIDATE_EOSSDATA-10'
			SELECT TOP 1 @cSchemeName=a.schemeName FROM wow_SchemeSetup_Title_Det a (NOLOCK)
			LEFT JOIN wow_SchemeSetup_para_combination_flat b (NOLOCK) ON a.schemeRowId=b.schemeRowId
			WHERE a.schemeRowId=@cSchDetRowId  AND 
					(buyFilterMode=3 and schemeMode=2) AND b.schemeRowId IS NULL

			SET @cErrormsg='Para combination Flat data found blank for Scheme: '+@cSchemeName+' Cannot Save..'
			GOTO END_PROC
		END
			
		print 'SP3S_VALIDATE_EOSSDATA-11'
		IF EXISTS (SELECT TOP 1 a.schemeRowId FROM wow_SchemeSetup_Title_Det a (NOLOCK)
					LEFT JOIN wow_SchemeSetup_para_combination_config b (NOLOCK) ON a.schemeRowId=b.schemeRowId
					WHERE a.schemeRowId=@cSchDetRowId AND (buyfiltermode=3 or (getfiltermode=3 and schememode=1))
					AND b.schemeRowId IS NULL)
		BEGIN
			print 'SP3S_VALIDATE_EOSSDATA-12'
			SELECT TOP 1 @cSchemeName=a.schemename FROM wow_SchemeSetup_Title_Det a (NOLOCK)
			LEFT JOIN wow_SchemeSetup_para_combination_config b (NOLOCK) ON a.schemeRowId=b.schemeRowId
			WHERE a.schemeRowId=@cSchDetRowId AND ((buyfiltermode=3 or (getfiltermode=3 and schememode=1))) AND b.schemeRowId IS NULL

			SET @cErrormsg='Para combination Config found blank for Scheme: '+@cSchemeName+' Cannot Save..'
			GOTO END_PROC
		END

			
		IF EXISTS (SELECT TOP 1 a.schemeRowId FROM wow_SchemeSetup_Title_Det a (NOLOCK)
					LEFT JOIN wow_SchemeSetup_para_combination_get b (NOLOCK) ON a.schemeRowId=b.schemeRowId
					WHERE a.schemeRowId=@cSchDetRowId AND a.getfiltermode=3 and a.schememode=1 AND b.schemeRowId IS NULL)
		BEGIN
			SELECT TOP 1 @cSchemeName=a.schemename  FROM wow_SchemeSetup_Title_Det a (NOLOCK)
			LEFT JOIN wow_SchemeSetup_para_combination_get b (NOLOCK) ON a.schemeRowId=b.schemeRowId 
			WHERE a.schemeRowId=@cSchDetRowId AND a.getfiltermode=3 and a.schememode=1 AND b.schemeRowId IS NULL
				
			SET @cErrormsg='Para combination Get data found blank for Scheme: '+@cSchemeName+' Cannot Save..'
			GOTO END_PROC
		END
		
		GOTO END_PROC
	END

	--IF EXISTS (SELECT TOP 1 schemeRowId FROM MSTEOSS_wow_SchemeSetup_Title_Det_MIRROR (NOLOCK) WHERE filtermode=6 OR  
	--( (getfiltermode=3 or filtermode=3)))
	--BEGIN
		print 'SP3S_VALIDATE_EOSSDATA-2'
		IF @bChkFinalData=0
		BEGIN
			print 'SP3S_VALIDATE_EOSSDATA-3'
			IF EXISTS (SELECT TOP 1 a.schemeRowId FROM MSTEOSS_wow_SchemeSetup_Title_Det_MIRROR a (NOLOCK)
						LEFT JOIN MSTEOSS_wow_SchemeSetup_para_combination_buy_MIRROR b (NOLOCK) ON a.schemeRowId=b.schemeRowId
						WHERE (buyfiltermode=3 and schememode=1) AND b.schemeRowId IS NULL)
			BEGIN
				print 'SP3S_VALIDATE_EOSSDATA-4'
				SELECT TOP 1 @cSchemeName=a.schemename FROM MSTEOSS_wow_SchemeSetup_Title_Det_MIRROR a (NOLOCK)
				LEFT JOIN MSTEOSS_wow_SchemeSetup_para_combination_buy_MIRROR b (NOLOCK) ON a.schemeRowId=b.schemeRowId
				WHERE (buyfiltermode=3 and schememode=1)  AND b.schemeRowId IS NULL

				print 'SP3S_VALIDATE_EOSSDATA-4.5:'+@cSchemeName
				SET @cErrormsg='Para combination Buy Temp data found blank for Scheme: '+@cSchemeName
				GOTO END_PROC
			END
		
			IF EXISTS (SELECT TOP 1 a.schemeRowId FROM MSTEOSS_wow_SchemeSetup_Title_Det_MIRROR a (NOLOCK)
						LEFT JOIN MSTEOSS_wow_SchemeSetup_para_combination_flat_MIRROR b (NOLOCK) ON a.schemeRowId=b.schemeRowId
						WHERE (buyfiltermode=3 and schememode=2) AND b.schemeRowId IS NULL)
			BEGIN
				print 'SP3S_VALIDATE_EOSSDATA-4'
				SELECT TOP 1 @cSchemeName=a.schemename FROM MSTEOSS_wow_SchemeSetup_Title_Det_MIRROR a (NOLOCK)
				LEFT JOIN MSTEOSS_wow_SchemeSetup_para_combination_flat_MIRROR b (NOLOCK) ON a.schemeRowId=b.schemeRowId
				WHERE (buyfiltermode=3 and schememode=2)  AND b.schemeRowId IS NULL

				print 'SP3S_VALIDATE_EOSSDATA-4.5:'+@cSchemeName
				SET @cErrormsg='Para combination Flat Temp data found blank for Scheme: '+@cSchemeName
				GOTO END_PROC
			END
			
			print 'SP3S_VALIDATE_EOSSDATA-5'
			IF EXISTS (SELECT TOP 1 a.schemeRowId FROM MSTEOSS_wow_SchemeSetup_Title_Det_MIRROR a (NOLOCK)
						LEFT JOIN MSTEOSS_wow_SchemeSetup_para_combination_config_MIRROR b (NOLOCK) ON a.schemeRowId=b.schemeRowId
						WHERE (buyfiltermode=3 or (getfiltermode=3 and schememode=1)) AND b.schemeRowId IS NULL)
			BEGIN
				print 'SP3S_VALIDATE_EOSSDATA-6'
				SELECT TOP 1 @cSchemeName=a.schemename FROM MSTEOSS_wow_SchemeSetup_Title_Det_MIRROR a (NOLOCK)
				LEFT JOIN MSTEOSS_wow_SchemeSetup_para_combination_config_MIRROR b (NOLOCK) ON a.schemeRowId=b.schemeRowId
				WHERE (buyfiltermode=3 or (getfiltermode=3 and schememode=1)) AND b.schemeRowId IS NULL

				SET @cErrormsg='Para combination Temp Config found blank for Scheme: '+@cSchemeName
				GOTO END_PROC
			END
			
			print 'SP3S_VALIDATE_EOSSDATA-7'
			IF EXISTS (SELECT TOP 1 a.schemeRowId FROM MSTEOSS_wow_SchemeSetup_Title_Det_MIRROR a (NOLOCK)
						LEFT JOIN MSTEOSS_wow_SchemeSetup_para_combination_get_MIRROR b (NOLOCK) ON a.schemeRowId=b.schemeRowId
						WHERE (getfiltermode=3 and schememode=1 ) AND b.schemeRowId IS NULL)
			BEGIN
				print 'SP3S_VALIDATE_EOSSDATA-8'
				SELECT TOP 1 @cSchemeName=a.schemename FROM MSTEOSS_wow_SchemeSetup_Title_Det_MIRROR a (NOLOCK)
				LEFT JOIN MSTEOSS_wow_SchemeSetup_para_combination_get_MIRROR b (NOLOCK) ON a.schemeRowId=b.schemeRowId 
				WHERE  (getfiltermode=3 and schememode=1) AND b.schemeRowId IS NULL

				SET @cErrormsg='Para combination Get Temp data cannot be blank for Scheme: '+@cSchemeName
				GOTO END_PROC
			END
		END
		

END_PROC:
END

