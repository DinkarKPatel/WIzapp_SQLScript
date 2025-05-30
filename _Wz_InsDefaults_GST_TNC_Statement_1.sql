IF EXISTS(SELECT IS_ENABLED FROM GST_TNC WHERE IS_ENABLED IS NULL AND XN_TYPE='SLS')
   UPDATE GST_TNC SET IS_ENABLED=1 WHERE XN_TYPE='SLS'

IF EXISTS(SELECT IS_ENABLED FROM GST_TNC WHERE IS_ENABLED IS NULL AND XN_TYPE='WSL')
   UPDATE GST_TNC SET IS_ENABLED=1 WHERE XN_TYPE='WSL'  

IF NOT EXISTS(SELECT * FROM GST_TNC WHERE XN_TYPE='PRT')
   INSERT GST_TNC (XN_TYPE,TNC_1,TNC_2,TNC_3,TNC_4,TNC_5,TNC_6,[IS_ENABLED]) 
   SELECT 'PRT',''T1,''T2,''T3,''T4,''T5,''T6,1 ENABLD

IF EXISTS(SELECT IS_ENABLED FROM GST_TNC WHERE IS_ENABLED IS NULL AND XN_TYPE='PRT')
   UPDATE GST_TNC SET IS_ENABLED=1 WHERE XN_TYPE='PRT'  

IF NOT EXISTS(SELECT * FROM GST_TNC WHERE XN_TYPE='SLS')
   INSERT GST_TNC (XN_TYPE,TNC_1,TNC_2,TNC_3,TNC_4,TNC_5,TNC_6,[IS_ENABLED]) 
   SELECT 'SLS',''T1,''T2,''T3,''T4,''T5,''T6,1 ENABLD

IF EXISTS(SELECT * FROM GST_TNC WHERE XN_TYPE='SLS')
   UPDATE GST_TNC SET TNC_1=ISNULL(TNC_1,''),TNC_2=ISNULL(TNC_2,''),TNC_3=ISNULL(TNC_3,''),TNC_4=ISNULL(TNC_4,''),TNC_5=ISNULL(TNC_5,''),TNC_6=ISNULL(TNC_6,''),[IS_ENABLED]=ISNULL([IS_ENABLED],1) WHERE XN_TYPE='SLS'

IF NOT EXISTS(SELECT * FROM GST_TNC WHERE XN_TYPE='WSL')
   INSERT GST_TNC (XN_TYPE,TNC_1,TNC_2,TNC_3,TNC_4,TNC_5,TNC_6,[IS_ENABLED]) 
   SELECT 'WSL',''T1,''T2,''T3,''T4,''T5,''T6,1 ENABLD

IF NOT EXISTS(SELECT * FROM GST_TNC WHERE XN_TYPE='PUR')
   INSERT GST_TNC (XN_TYPE,TNC_1,TNC_2,TNC_3,TNC_4,TNC_5,TNC_6,[IS_ENABLED]) 
   SELECT 'PUR',''T1,''T2,''T3,''T4,''T5,''T6,1 ENABLD

IF EXISTS(SELECT * FROM GST_TNC WHERE XN_TYPE='WSL')
   UPDATE GST_TNC SET TNC_1=ISNULL(TNC_1,''),TNC_2=ISNULL(TNC_2,''),TNC_3=ISNULL(TNC_3,''),TNC_4=ISNULL(TNC_4,''),TNC_5=ISNULL(TNC_5,''),TNC_6=ISNULL(TNC_6,''),[IS_ENABLED]=ISNULL([IS_ENABLED],1) WHERE XN_TYPE='WSL'
