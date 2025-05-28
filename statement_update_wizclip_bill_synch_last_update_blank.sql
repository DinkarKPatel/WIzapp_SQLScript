DECLARE @cCurLocId VARCHAR(5)/*Rohit 01-11-2024*/

SELECT TOP 1 @cCurLocId=value FROM  config (NOLOCK) WHERE config_option='location_id'

select dept_id into #tmploc from location (NOLOCK) where (server_loc=1 or dept_id=@cCurLocId)
AND ISNULL(WizClip,0)=1

UPDATE a WITH (ROWLOCK) SET wizclip_bill_synch_last_update=''
FROM cmm01106 a 
JOIN #tmploc b (NOLOCK) ON LEFT(a.cm_id,2)=b.dept_id
WHERE  customer_code<>'000000000000' AND cancelled=0	AND wizclip_bill_synch_last_update IS NULL

 