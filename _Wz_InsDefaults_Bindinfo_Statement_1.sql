PRINT 'INSERTING BIN ID COLUMN INFORMATION IN TABLE BINIDINFO'

TRUNCATE TABLE BINIDINFO
 
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'DNPS_DET','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'DNPS_MST','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'DNPS_MST','TARGET_BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'WPS_DET','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'WPS_MST','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'WPS_MST','TARGET_BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'APD01106','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'APM01106','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'APPROVAL_RETURN_DET','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'APPROVAL_RETURN_MST','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'ARC01106','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'FLOOR_ST_DET','SOURCE_BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'FLOOR_ST_MST','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'FLOOR_ST_MST','TARGET_BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'SNC_MST','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'ICD01106','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'BIN_LOC','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'ICM01106','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'BINUSERS','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'SNC_DET','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'IND01106','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'IND01106_AUDIT','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'INM01106','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'INM01106','TARGET_BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'INM01106_AUDIT','TARGET_BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'INM01106_AUDIT','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'OPS01106','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'RMD01106','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'RMD01106_AUDIT','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'IRD01106','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'RMM01106','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'RMM01106','TARGET_BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'IRM01106','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'RMM01106_AUDIT','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'RMM01106_AUDIT','TARGET_BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'RPS_DET','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'RPS_MST','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'JOBWORK_ISSUE_DET','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'JOBWORK_ISSUE_MST','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'JOBWORK_RECEIPT_DET','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'JOBWORK_RECEIPT_MST','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'CMD_HOLD','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'CMD01106','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'CMD01106_AUDIT','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'PID01106','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'PID01106_AUDIT','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'PIM01106','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'PIM01106_AUDIT','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'CMM_HOLD','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'PMT01106','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'CMM01106','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'CMM01106_AUDIT','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'SNC_CONSUMABLE_DET','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'POD01106','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'POM01106','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'CND01106','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'CND01106_AUDIT','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'CNM01106','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'CNM01106_AUDIT','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'POST_SALES_JOBWORK_ISSUE_DET','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'POST_SALES_JOBWORK_ISSUE_MST','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'POST_SALES_JOBWORK_RECEIPT_DET','BIN_ID'
INSERT BINIDINFO (TABLENAME,COLNAME) SELECT 'POST_SALES_JOBWORK_RECEIPT_MST','BIN_ID'

