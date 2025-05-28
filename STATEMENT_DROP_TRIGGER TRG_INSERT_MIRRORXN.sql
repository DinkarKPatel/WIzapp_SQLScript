
DECLARE @cCmd NVARCHAR(MAX)
if exists (select top 1 name from sysobjects (nolock) where name='TRG_INSERT_MIRRORXN_APP' and xtype='TR')
BEGIN
	
	SET @cCmd=N'DROP TRIGGER TRG_INSERT_MIRRORXN_APP'
	EXEC SP_EXECUTESQL @cCmd
END	


if exists (select top 1 name from sysobjects (nolock) where name='TRG_INSERT_MIRRORXN_APR' and xtype='TR')
BEGIN
	SET @cCmd=N'DROP TRIGGER TRG_INSERT_MIRRORXN_APR'
	EXEC SP_EXECUTESQL @cCmd
END	



if exists (select top 1 name from sysobjects (nolock) where name='TRG_INSERT_MIRRORXN_BCO' and xtype='TR')
BEGIN
	SET @cCmd=N'DROP TRIGGER TRG_INSERT_MIRRORXN_BCO'
	EXEC SP_EXECUTESQL @cCmd
END	

if exists (select top 1 name from sysobjects (nolock) where name='TRG_INSERT_MIRRORXN_BKT' and xtype='TR')
BEGIN
	SET @cCmd=N'DROP TRIGGER TRG_INSERT_MIRRORXN_BKT'
	EXEC SP_EXECUTESQL @cCmd
END	
if exists (select top 1 name from sysobjects (nolock) where name='TRG_INSERT_MIRRORXN_CNC' and xtype='TR')
BEGIN
	SET @cCmd=N'DROP TRIGGER TRG_INSERT_MIRRORXN_CNC'
	EXEC SP_EXECUTESQL @cCmd
END	

if exists (select top 1 name from sysobjects (nolock) where name='TRG_INSERT_MIRRORXN_DNPS' and xtype='TR')
BEGIN
	SET @cCmd=N'DROP TRIGGER TRG_INSERT_MIRRORXN_DNPS'
	EXEC SP_EXECUTESQL @cCmd
END	

if exists (select top 1 name from sysobjects (nolock) where name='TRG_INSERT_MIRRORXN_IRR' and xtype='TR')
BEGIN
	SET @cCmd=N'DROP TRIGGER TRG_INSERT_MIRRORXN_IRR'
	EXEC SP_EXECUTESQL @cCmd
END	

if exists (select top 1 name from sysobjects (nolock) where name='TRG_INSERT_MIRRORXN_JWI' and xtype='TR')
BEGIN
	SET @cCmd=N'DROP TRIGGER TRG_INSERT_MIRRORXN_JWI'
	EXEC SP_EXECUTESQL @cCmd
END	


if exists (select top 1 name from sysobjects (nolock) where name='TRG_INSERT_MIRRORXN_JWR' and xtype='TR')
BEGIN
	SET @cCmd=N'DROP TRIGGER TRG_INSERT_MIRRORXN_JWR'
	EXEC SP_EXECUTESQL @cCmd
END	

if exists (select top 1 name from sysobjects (nolock) where name='TRG_INSERT_MIRRORXN_PCI' and xtype='TR')
BEGIN
	SET @cCmd=N'DROP TRIGGER TRG_INSERT_MIRRORXN_PCI'
	EXEC SP_EXECUTESQL @cCmd
END	

if exists (select top 1 name from sysobjects (nolock) where name='TRG_INSERT_MIRRORXN_PCO' and xtype='TR')
BEGIN
	SET @cCmd=N'DROP TRIGGER TRG_INSERT_MIRRORXN_PCO'
	EXEC SP_EXECUTESQL @cCmd
END	

if exists (select top 1 name from sysobjects (nolock) where name='TRG_INSERT_MIRRORXN_RPS' and xtype='TR')
BEGIN
	SET @cCmd=N'DROP TRIGGER TRG_INSERT_MIRRORXN_RPS'
	EXEC SP_EXECUTESQL @cCmd
END	

if exists (select top 1 name from sysobjects (nolock) where name='TRG_INSERT_MIRRORXN_SCF' and xtype='TR')
BEGIN
	SET @cCmd=N'DROP TRIGGER TRG_INSERT_MIRRORXN_SCF'
	EXEC SP_EXECUTESQL @cCmd
END	

if exists (select top 1 name from sysobjects (nolock) where name='TRG_INSERT_MIRRORXN_SHF' and xtype='TR')
BEGIN
	SET @cCmd=N'DROP TRIGGER TRG_INSERT_MIRRORXN_SHF'
	EXEC SP_EXECUTESQL @cCmd
END	

if exists (select top 1 name from sysobjects (nolock) where name='TRG_INSERT_MIRRORXN_SNC' and xtype='TR')
BEGIN
	SET @cCmd=N'DROP TRIGGER TRG_INSERT_MIRRORXN_SNC'
	EXEC SP_EXECUTESQL @cCmd
END	


if exists (select top 1 name from sysobjects (nolock) where name='TRG_INSERT_MIRRORXN_TEX' and xtype='TR')
BEGIN
	SET @cCmd=N'DROP TRIGGER TRG_INSERT_MIRRORXN_TEX'
	EXEC SP_EXECUTESQL @cCmd
END	


if exists (select top 1 name from sysobjects (nolock) where name='TRG_INSERT_MIRRORXN_WBO' and xtype='TR')
BEGIN
	SET @cCmd=N'DROP TRIGGER TRG_INSERT_MIRRORXN_WBO'
	EXEC SP_EXECUTESQL @cCmd
END	

if exists (select top 1 name from sysobjects (nolock) where name='TRG_INSERT_MIRRORXN_WPL' and xtype='TR')
BEGIN
	SET @cCmd=N'DROP TRIGGER TRG_INSERT_MIRRORXN_WPL'
	EXEC SP_EXECUTESQL @cCmd
END	

if exists (select top 1 name from sysobjects (nolock) where name='TRG_INSERT_MIRRORXN_WSLORD' and xtype='TR')
BEGIN
	SET @cCmd=N'DROP TRIGGER TRG_INSERT_MIRRORXN_WSLORD'
	EXEC SP_EXECUTESQL @cCmd
END	


if exists (select top 1 name from sysobjects (nolock) where name='TRG_INSERT_MIRRORXN_PTC' and xtype='TR')
BEGIN
	SET @cCmd=N'DROP TRIGGER TRG_INSERT_MIRRORXN_PTC'
	EXEC SP_EXECUTESQL @cCmd
END	
