-- DROP VIEW IF EXISTS da.ContactOutboundStat;

CREATE VIEW da.ContactOutboundStat
AS
SELECT  collema.colleague_id,
        cont.contact_id,
        COUNT(DISTINCT msg.email_message_id) AS NumMessages,
        MIN(msg.submit_date) AS FirstOutbound,
        MAX(msg.submit_date) AS LastOutbound
FROM da.team1_colleague_email collema
JOIN da.email_message_participant collpar ON collpar.email_address = collema.email_address_text
JOIN da.email_message msg ON msg.email_message_id = collpar.email_message_id
JOIN da.email_message_participant contpar ON contpar.email_message_id = msg.email_message_id AND contpar.id != collpar.id
JOIN da.team1_contact_email_address contema ON contema.email_address_text = contpar.email_address
JOIN da.team1_contact cont ON cont.contact_id = contema.contact_id
WHERE collpar.role = 'From'
GROUP BY collema.colleague_id, cont.contact_id;
