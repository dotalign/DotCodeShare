-- DROP VIEW IF EXISTS da.team2_colleague_email;

CREATE VIEW da.team2_colleague_email
AS
SELECT DISTINCT 
  coll.colleague_id,
  ema2.email_address_id,
  ema2.email_address_text
FROM da.team2_colleague coll
JOIN da.team2_contact_email_address ema ON ema.email_address_text = coll.email_address
JOIN da.team2_contact_identity_map map ON map.secondary_id = ema.email_address_id
JOIN da.team2_contact_identity_map map2 ON map2.primary_id = map.primary_id AND map2.id != map.id
JOIN da.team2_contact_email_address ema2 ON ema2.contact_id = map2.secondary_id;