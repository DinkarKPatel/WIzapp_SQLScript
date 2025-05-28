CREATE PROCEDURE SP3S_SMSHISTORY
(
	@cFromDt Varchar(10),
	@cToDt Varchar(10),
	@cWhere VarchaR (100)=''
)
As
Begin
select b.rep_type,'EMAIL' AS TYPE ,name,mobile, target_email,email_subject as msg,
CONVERT(VARCHAR(10), Sent_On, 103) + ' '  + 
convert(VARCHAR(8), Sent_On, 14)  as Sent_on
from SMSDetails a 
Join reporttype b on a.rep_code= b.rep_code
where Mobile = '' and  WhatsApp_msg = ''
and  sent_on between @cFromDt and @cToDt and  (@cWhere='' or a.rep_id=@cWhere) 
union
select b.rep_type,'SMS' AS TYPE ,name,mobile, target_email,msg as msg,
CONVERT(VARCHAR(10), Sent_On, 103) + ' '  + 
convert(VARCHAR(8), Sent_On, 14)  as Sent_on
from SMSDetails  a
Join reporttype b on a.rep_code= b.rep_code
where Mobile  <> '' and  WhatsApp_msg = ''
and  sent_on between @cFromDt and @cToDt and  (@cWhere='' or a.rep_id=@cWhere) 
union
select b.rep_type,'WHATSAPP' AS TYPE ,name,mobile, target_email,WhatsApp_msg as msg,
CONVERT(VARCHAR(10), Sent_On, 103) + ' '  + 
convert(VARCHAR(8), Sent_On, 14)  as Sent_on 
from SMSDetails a
Join reporttype b on a.rep_code= b.rep_code
where Mobile  <> '' and WhatsApp_msg <> ''
and  sent_on between @cFromDt and @cToDt and  (@cWhere='' or a.rep_id=@cWhere) 

END