CREATE VIEW VW_TICKET_LIST
--WITH ENCRYPTION
AS
SELECT WEBSUPPORT_TICKET_ID AS TICKET_ID,TICKET_ID AS REF_ID,
	   SUBJECT,TICKET_DT AS 'TICKET DATE',(CASE WHEN COMPLETED = 0 THEN 'OPEN' ELSE 'CLOSED' END) AS STATUS
FROM WEBSUPPORT_TKTM
