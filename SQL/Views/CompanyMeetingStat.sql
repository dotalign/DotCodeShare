-- DROP VIEW IF EXISTS da.CompanyMeetingStat;

CREATE VIEW da.CompanyMeetingStat
AS
SELECT  collema.colleague_id,
        courl.company_id,
        COUNT(DISTINCT mtg.meeting_id) AS NumMeetings,
        MIN(mtg.start_date) AS FirstMeeting,
        MAX(mtg.start_date) AS LastMeeting
FROM da.team1_colleague_email collema
JOIN da.meeting_participant collpar ON collpar.email_address = collema.email_address_text
JOIN da.meeting mtg ON mtg.meeting_id = collpar.meeting_id
JOIN da.meeting_participant contpar ON contpar.meeting_id = mtg.meeting_id AND contpar.id != collpar.id
JOIN da.team1_company_url courl ON courl.url_text = contpar.domain
GROUP BY collema.colleague_id, courl.company_id;
