DECLARE @cCurLocId VARCHAR(5)/*Rohit 01-11-2024*/
SELECT TOP 1 @cCurLocId=value FROM  config (NOLOCK) WHERE config_option='location_id'

SELECT dept_id INTO #tmpLocs FROM location a (NOLOCK)
WHERE dept_id=@cCurLocId OR server_loc=1


select a.cm_id,SUM(weighted_avg_disc_amt) wtddisc,SUM(a.discount_amount) disc
INTO #tmpCmd 
from CMD01106 a (NOLOCK)
/*Rohit 01-11-2024*/JOIN CMM01106 C (NOLOCK) ON C.cm_id=a.cm_id
JOIN #tmpLocs b ON b.dept_id=C.location_Code/* LEFT(a.cm_id,2)*//*Rohit 01-11-2024*/
GROUP BY a.cm_id HAVING SUM(weighted_avg_disc_amt)<>0 AND SUM(a.discount_amount)=0

UPDATE a SET weighted_avg_disc_amt=0,weighted_avg_disc_pct=0 
FROM cmd01106 a JOIN #tmpCmd b ON a.cm_id=b.cm_id