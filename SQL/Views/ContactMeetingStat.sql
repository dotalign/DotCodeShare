-- DROP VIEW IF EXISTS da.ContactMeetingStat;

CREATE VIEW da.ContactMeetingStat
AS
SELECT  collema.colleague_id,
        cont.contact_id,
        COUNT(DISTINCT mtg.meeting_id) AS NumMeetings,
        MIN(mtg.start_date) AS FirstMeeting,
        MAX(mtg.start_date) AS LastMeeting
FROM da.team2_colleague_email collema
JOIN da.meeting_participant collpar ON collpar.email_address = collema.email_address_text
JOIN da.meeting mtg ON mtg.meeting_id = collpar.meeting_id
JOIN da.meeting_participant contpar ON contpar.meeting_id = mtg.meeting_id AND contpar.id != collpar.id
JOIN da.team2_contact_email_address contema ON contema.email_address_text = contpar.email_address
JOIN da.team2_contact cont ON cont.contact_id = contema.contact_id
GROUP BY collema.colleague_id, cont.contact_id;
