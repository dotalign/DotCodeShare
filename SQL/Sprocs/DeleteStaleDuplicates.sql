-- DROP PROCEDURE IF EXISTS da.DeleteStaleDuplicates;

-- EXEC da.DeleteStaleDuplicates;

CREATE PROCEDURE da.DeleteStaleDuplicates AS
BEGIN
  
  -- email_message
  DELETE stale
  FROM da.email_message keeper
  JOIN da.email_message stale ON stale.email_message_id = keeper.email_message_id
  WHERE stale.id < keeper.id;
  
  -- email_message_participant
  DELETE stale
  FROM da.email_message_participant keeper
  JOIN da.email_message_participant stale ON stale.email_message_id = keeper.email_message_id 
    AND stale.email_address = keeper.email_address
    AND stale.role = keeper.role
  WHERE stale.id < keeper.id;

  -- meeting
  DELETE stale
  FROM da.meeting keeper
  JOIN da.meeting stale ON stale.meeting_id = keeper.meeting_id
  WHERE stale.id < keeper.id;
  
  -- meeting_participant
  DELETE stale
  FROM da.meeting_participant keeper
  JOIN da.meeting_participant stale ON stale.meeting_id = keeper.meeting_id
    AND stale.email_address = keeper.email_address
    AND stale.role = keeper.role
  WHERE stale.id < keeper.id;

  -- colleague
  DELETE stale
  FROM da.team1_colleague keeper
  JOIN da.team1_colleague stale ON stale.colleague_id = keeper.colleague_id
  WHERE stale.id < keeper.id;

  -- company
  DELETE stale
  FROM da.team1_company keeper
  JOIN da.team1_company stale ON stale.company_id = keeper.company_id
  WHERE stale.id < keeper.id;

  -- company_alias
  DELETE stale
  FROM da.team1_company_alias keeper
  JOIN da.team1_company_alias stale ON stale.company_id = keeper.company_id AND stale.alias_id = keeper.alias_id
  WHERE stale.id < keeper.id;

  -- company_identity_map
  DELETE stale
  FROM da.team1_company_identity_map keeper
  JOIN da.team1_company_identity_map stale ON stale.primary_id = keeper.primary_id AND stale.secondary_id = keeper.secondary_id
  WHERE stale.id < keeper.id;

  -- company_introducer
  DELETE stale
  FROM da.team1_company_introducer keeper
  JOIN da.team1_company_introducer stale ON stale.company_id = keeper.company_id AND stale.colleague_id = keeper.colleague_id
  WHERE stale.id < keeper.id;

  -- company_url
  DELETE stale
  FROM da.team1_company_url keeper
  JOIN da.team1_company_url stale ON stale.company_id = keeper.company_id AND stale.url_id = keeper.url_id
  WHERE stale.id < keeper.id;

  -- contact
  DELETE stale
  FROM da.team1_contact keeper
  JOIN da.team1_contact stale ON stale.contact_id = keeper.contact_id
  WHERE stale.id < keeper.id;

  -- contact_alias
  DELETE stale
  FROM da.team1_contact_alias keeper
  JOIN da.team1_contact_alias stale ON stale.contact_id = keeper.contact_id AND stale.alias_id = keeper.alias_id
  WHERE stale.id < keeper.id;

  -- contact_email_address
  DELETE stale
  FROM da.team1_contact_email_address keeper
  JOIN da.team1_contact_email_address stale ON stale.contact_id = keeper.contact_id AND stale.email_address_id = keeper.email_address_id
  WHERE stale.id < keeper.id;
  
  -- contact_identity_map
  DELETE stale
  FROM da.team1_contact_identity_map keeper
  JOIN da.team1_contact_identity_map stale ON stale.primary_id = keeper.primary_id AND stale.secondary_id = keeper.secondary_id
  WHERE stale.id < keeper.id;

  -- contact_introducer
  DELETE stale
  FROM da.team1_contact_introducer keeper
  JOIN da.team1_contact_introducer stale ON stale.contact_id = keeper.contact_id AND stale.colleague_id = keeper.colleague_id
  WHERE stale.id < keeper.id;

  -- contact_job
  DELETE stale
  FROM da.team1_contact_job keeper
  JOIN da.team1_contact_job stale ON stale.contact_id = keeper.contact_id AND stale.company_id = keeper.company_id
  WHERE stale.id < keeper.id;

  -- contact_phone_number
  DELETE stale
  FROM da.team1_contact_phone_number keeper
  JOIN da.team1_contact_phone_number stale ON stale.contact_id = keeper.contact_id AND stale.phone_number_text = keeper.phone_number_text
  WHERE stale.id < keeper.id;

END;
