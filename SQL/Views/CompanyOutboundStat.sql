-- DROP VIEW IF EXISTS da.CompanyOutboundStat;

CREATE VIEW da.CompanyOutboundStat
AS
SELECT  collema.colleague_id,
        courl.company_id,
        COUNT(DISTINCT msg.email_message_id) AS NumMessages,
        MIN(msg.submit_date) AS FirstOutbound,
        MAX(msg.submit_date) AS LastOutbound
FROM da.team2_colleague_email collema
JOIN da.email_message_participant collpar ON collpar.email_address = collema.email_address_text
JOIN da.email_message msg ON msg.email_message_id = collpar.email_message_id
JOIN da.email_message_participant contpar ON contpar.email_message_id = msg.email_message_id AND contpar.id != collpar.id
JOIN da.team2_company_url courl ON courl.url_text = contpar.domain
WHERE collpar.role = 'From'
GROUP BY collema.colleague_id, courl.company_id;
