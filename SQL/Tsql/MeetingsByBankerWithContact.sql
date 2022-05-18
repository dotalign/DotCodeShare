DECLARE @bkrEmail varchar(128);
SET @bkrEmail = 'vince@dotalign.com';

DECLARE @contactEmail varchar(128);
SET @contactEmail = 'hswartz@hl.com';

-- let's gather up all the emails for this banker (since the meeting could involve any of them)
;WITH cteBkrEmail AS (
  SELECT DISTINCT ema2.email_address_text
  FROM da.team1_colleague coll
  JOIN da.team1_contact_email_address ema ON ema.email_address_text = coll.email_address
  JOIN da.team1_contact_identity_map map ON map.secondary_id = ema.email_address_id
  JOIN da.team1_contact_identity_map map2 ON map2.primary_id = map.primary_id AND map2.id != map.id
  JOIN da.team1_contact_email_address ema2 ON ema2.contact_id = map2.secondary_id
  WHERE coll.email_address = @bkrEmail
)
SELECT
        COUNT(DISTINCT m.start_date) AS MeetingCount,  -- can't use meeting_id because each banker has their own key for it
        MAX(m.start_date) AS LastMeeting,
        MIN(m.start_date) AS FirstMeeting
FROM da.meeting m
-- banker
JOIN da.meeting_participant pbkr ON pbkr.meeting_id = m.meeting_id
JOIN cteBkrEmail bkrema ON bkrema.email_address_text = pbkr.email_address
-- participant
JOIN da.meeting_participant pcont ON pcont.meeting_id = m.meeting_id AND pcont.id != pbkr.Id
JOIN da.team1_contact_email_address pema ON pema.email_address_text = pcont.email_address
JOIN da.team1_contact_identity_map pmap ON pmap.secondary_id = pema.contact_id
JOIN da.team1_contact cont ON cont.contact_id = pmap.primary_id
WHERE cont.best_email_address = @contactEmail;
