DECLARE @bkrEmail varchar(128);
SET @bkrEmail = 'vince@dotalign.com';

DECLARE @contactEmail varchar(128);
SET @contactEmail = 'hswartz@hl.com';

-- let's gather up all the emails for this banker (since the email_message could involve any of them)
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
        COUNT(DISTINCT m.email_message_id) AS email_messageCount,  -- can't use email_message_id because each banker has their own key for it
        MAX(m.submit_date) AS Lastemail_message,
        MIN(m.submit_date) AS Firstemail_message
FROM da.email_message m
-- banker
JOIN da.email_message_participant pbkr ON pbkr.email_message_id = m.email_message_id
JOIN cteBkrEmail bkrema ON bkrema.email_address_text = pbkr.email_address
-- participant
JOIN da.email_message_participant pcont ON pcont.email_message_id = m.email_message_id AND pcont.id != pbkr.Id
JOIN da.team1_contact_email_address pema ON pema.email_address_text = pcont.email_address
JOIN da.team1_contact_identity_map pmap ON pmap.secondary_id = pema.contact_id
JOIN da.team1_contact cont ON cont.contact_id = pmap.primary_id
WHERE cont.best_email_address = @contactEmail;
