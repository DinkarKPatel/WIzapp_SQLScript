

IF OBJECT_ID('GST_REPORT_CONFIG_RESOLVE','U') IS NOT NULL
   DROP TABLE GST_REPORT_CONFIG_RESOLVE
SELECT * INTO GST_REPORT_CONFIG_RESOLVE FROM GST_REPORT_CONFIG (NOLOCK)  
