IF NOT EXISTS(SELECT * FROM GST_XN_FORMAT WHERE XN_TYPE='SLS')
   INSERT INTO GST_XN_FORMAT(XN_TYPE) SELECT 'SLS'

IF NOT EXISTS(SELECT * FROM GST_XN_FORMAT WHERE XN_TYPE='WSL')
   INSERT INTO GST_XN_FORMAT(XN_TYPE) SELECT 'WSL'

IF NOT EXISTS(SELECT * FROM GST_XN_FORMAT WHERE XN_TYPE='PRT')
   INSERT GST_XN_FORMAT (XN_TYPE) SELECT 'PRT'

IF NOT EXISTS(SELECT * FROM GST_XN_FORMAT WHERE XN_TYPE='ARC')
   INSERT INTO GST_XN_FORMAT(XN_TYPE) SELECT 'ARC'

IF NOT EXISTS(SELECT * FROM GST_XN_FORMAT WHERE XN_TYPE='PUR')
   INSERT INTO GST_XN_FORMAT(XN_TYPE) SELECT 'PUR'

IF NOT EXISTS(SELECT * FROM GST_XN_FORMAT WHERE XN_TYPE='WSR')
   INSERT INTO GST_XN_FORMAT(XN_TYPE) SELECT 'WSR'
