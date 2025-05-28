CREATE PROC SP3S_DATASENDING_ORDER  
AS   
BEGIN  
SELECT * FROM   
(  
SELECT 'PO' AS XN_TYPE,20 AS SEND_ORDER,1 as new_Sending_method  
UNION SELECT 'OPS',30,0 as new_Sending_method   
UNION SELECT 'PUR',40,1 as new_Sending_method   
UNION SELECT 'SNC',45,1 as new_Sending_method   
UNION SELECT 'SCF',60,1 as new_Sending_method   
UNION SELECT 'IRR',70,1 as new_Sending_method   
UNION SELECT 'APP',80,1 as new_Sending_method   
UNION SELECT 'APR',90,1 as new_Sending_method   
UNION SELECT 'SHF',95,1 as new_Sending_method   
UNION SELECT 'ADV',100,0 as new_Sending_method --NOT IN USE 
UNION SELECT 'RPS',110,1 as new_Sending_method   
UNION SELECT 'WSL',115,1 as new_Sending_method     
UNION SELECT 'XNSLM',10,1 as new_Sending_method   
UNION SELECT 'XNSDTM',117,1 as new_Sending_method   
UNION SELECT 'SLS',120,1 as new_Sending_method   
UNION SELECT 'ARC',125,1 as new_Sending_method   
UNION SELECT 'TLF',127,1 as new_Sending_method   
UNION SELECT 'TEX',130,1 as new_Sending_method   
UNION SELECT 'BKT',132,1 as new_Sending_method  
UNION SELECT 'PTC',135,1 as new_Sending_method   
UNION SELECT 'PTCAPP',138,1 as new_Sending_method   
UNION SELECT 'HBD',140,0 as new_Sending_method   --NOT IN USE
UNION SELECT 'WSLORD',150,1 as new_Sending_method   
UNION SELECT 'SCHNEW',300,1 as new_Sending_method  
UNION SELECT 'WPS',112,1 as new_Sending_method  
UNION SELECT 'WBO',160,1 as new_Sending_method  
UNION SELECT 'WPL',165,0 as new_Sending_method  --OLD PICK LIST
UNION SELECT 'DNPS',180,1 as new_Sending_method   
UNION SELECT 'PRT',185,1 as new_Sending_method    
UNION SELECT 'WSR',190,1 as new_Sending_method   
UNION SELECT 'BCO',195,1 as new_Sending_method   
UNION SELECT 'JWI',200,1 as new_Sending_method   
UNION SELECT 'JWR',210,1 as new_Sending_method   
UNION SELECT 'ACT',220,0 as new_Sending_method   --NOT IN USE
UNION SELECT 'ATD',230,1 as new_Sending_method   
UNION SELECT 'CNC',240,1 as new_Sending_method  
UNION SELECT 'POADJ',250,1 as new_Sending_method   
UNION SELECT 'DEND',260,1 as new_Sending_method   
UNION SELECT 'FIRR',270,0 as new_Sending_method  --NOT IN USE
UNION SELECT 'PSHBD',310,1 as new_Sending_method   
UNION SELECT 'PSJWI',320,1 as new_Sending_method  
UNION SELECT 'PSJWR',330,1 as new_Sending_method   
UNION SELECT 'PSDLV',340,1 as new_Sending_method  

UNION SELECT 'STREC',380,1 as new_Sending_method  
UNION SELECT 'PCI',510,1 as new_Sending_method  
UNION SELECT 'PCO',520,1 as new_Sending_method  
UNION SELECT 'DSM',530,1 as new_Sending_method  
UNION SELECT 'PRCL',540,1 as new_Sending_method  
UNION SELECT 'PBM',550,0 as new_Sending_method --TABLE DISCARDED 
UNION SELECT 'CNC',560,1 as new_Sending_method  
UNION SELECT 'CUS',570,1 as new_Sending_method  
UNION SELECT 'DCO',580,0 as new_Sending_method  --NOT IN USE
UNION SELECT 'PFI',590,1 AS NEW_SENDING_METHOD   
UNION SELECT 'MIS',600,1 AS NEW_SENDING_METHOD  
UNION SELECT 'TTM',610,1 AS NEW_SENDING_METHOD  
UNION SELECT 'SLRRECON',620,1 AS NEW_SENDING_METHOD   
UNION SELECT 'BIN_MST',630,1 as new_Sending_method  
UNION SELECT 'GRNPS',640,1 AS NEW_SENDING_METHOD  
UNION SELECT 'STKCNT',645,1 AS NEW_SENDING_METHOD
) A 
ORDER BY SEND_ORDER  
END  

