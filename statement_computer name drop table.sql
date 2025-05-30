IF EXISTS(SELECT TOP 1 'U' FROM SYS.TABLES A JOIN SYS.columns B ON A.object_id=B.object_id
WHERE A.name='DSM_CMM01106_UPLOAD' AND B.name='COMPUTER_NAME')
ALTER TABLE   DSM_CMM01106_UPLOAD    DROP COLUMN COMPUTER_NAME
;

IF EXISTS(SELECT TOP 1 'U' FROM SYS.TABLES A JOIN SYS.columns B ON A.object_id=B.object_id
WHERE A.name='SLS_cmm01106_MIRROR' AND B.name='COMPUTER_NAME')
ALTER TABLE   SLS_cmm01106_MIRROR    DROP COLUMN COMPUTER_NAME

;

IF EXISTS(SELECT TOP 1 'U' FROM SYS.TABLES A JOIN SYS.columns B ON A.object_id=B.object_id
WHERE A.name='SLS_cmm01106_UPLOAD' AND B.name='COMPUTER_NAME')
ALTER TABLE   SLS_cmm01106_UPLOAD    DROP COLUMN COMPUTER_NAME

;

IF EXISTS(SELECT TOP 1 'U' FROM SYS.TABLES A JOIN SYS.columns B ON A.object_id=B.object_id
WHERE A.name='cmm_hold' AND B.name='COMPUTER_NAME')
ALTER TABLE   cmm_hold    DROP COLUMN COMPUTER_NAME
