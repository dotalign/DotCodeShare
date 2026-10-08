/*  =====================================================================
    Relationship queries for the DotAlign sync database
    =====================================================================

    The sync database is a SQL Server copy of DotAlign relationship data.
    Every table is split by team (team_number).

    How to use:
      1. Set the parameters below.
      2. Run the whole file (one result set per query), or highlight
         the DECLARE block together with the one query you want.

    Relationship scores, counts and dates are aggregates as of
    the last sync (valid_as_of).
    ===================================================================== */

DECLARE @TeamNumber     int           = 1;
DECLARE @ContactEmail   nvarchar(256) = 'someone@example.com';    -- Queries 1 and 4
DECLARE @CompanyWebsite nvarchar(256) = 'example.com';            -- Queries 2 and 3 (domain only)
DECLARE @ColleagueEmail nvarchar(256) = 'colleague@ourfirm.com';  -- Query 3


/*  ---------------------------------------------------------------------
    Query 1: Which colleagues know a contact, and how well?

    The contact is found by any of their email addresses.
    --------------------------------------------------------------------- */

WITH matched_contact AS
(
    -- A contact can have several email addresses; match any of them
    SELECT DISTINCT
        email.contact_id
    FROM dbo.contact_email_address AS email
    WHERE email.team_number        = @TeamNumber
      AND email.email_address_text = @ContactEmail
      AND ISNULL(email.is_deleted, 0) = 0
)

SELECT
    -- The contact
    contact.contact_id,
    contact.best_full_name          AS contact_name,
    contact.best_email_address      AS contact_email,

    -- The colleague who knows them
    colleague.name                  AS colleague_name,
    colleague.email_address         AS colleague_email,

    -- How well they know each other
    relationship.relationship_score,
    relationship.latest_meeting_date

FROM dbo.contact AS contact

    JOIN matched_contact
        ON matched_contact.contact_id = contact.contact_id

    -- contact_introducer holds one row per (contact, colleague) pair
    JOIN dbo.contact_introducer AS relationship
        ON  relationship.team_number = contact.team_number
        AND relationship.contact_id  = contact.contact_id
        AND ISNULL(relationship.is_deleted, 0) = 0

    JOIN dbo.colleague AS colleague
        ON  colleague.team_number  = relationship.team_number
        AND colleague.colleague_id = relationship.colleague_id
        AND ISNULL(colleague.is_deleted, 0) = 0

WHERE contact.team_number = @TeamNumber
  AND ISNULL(contact.is_deleted, 0) = 0

ORDER BY
    relationship.relationship_score DESC;


/*  ---------------------------------------------------------------------
    Query 2: Which colleagues know a company, and how well?

    The company is found by any of its websites.
    --------------------------------------------------------------------- */

WITH matched_company AS
(
    -- A company can have several websites; match any of them
    SELECT DISTINCT
        website.company_id
    FROM dbo.company_url AS website
    WHERE website.team_number = @TeamNumber
      AND website.url_text    = @CompanyWebsite
      AND ISNULL(website.is_deleted, 0) = 0
)

SELECT
    -- The company
    company.company_id,
    company.best_name               AS company_name,
    company.best_url                AS company_website,

    -- The colleague who knows them
    colleague.name                  AS colleague_name,
    colleague.email_address         AS colleague_email,

    -- How well they know each other
    relationship.relationship_score,
    relationship.latest_meeting_date

FROM dbo.company AS company

    JOIN matched_company
        ON matched_company.company_id = company.company_id

    -- company_introducer holds one row per (company, colleague) pair
    JOIN dbo.company_introducer AS relationship
        ON  relationship.team_number = company.team_number
        AND relationship.company_id  = company.company_id
        AND ISNULL(relationship.is_deleted, 0) = 0

    JOIN dbo.colleague AS colleague
        ON  colleague.team_number  = relationship.team_number
        AND colleague.colleague_id = relationship.colleague_id
        AND ISNULL(colleague.is_deleted, 0) = 0

WHERE company.team_number = @TeamNumber
  AND ISNULL(company.is_deleted, 0) = 0

ORDER BY
    relationship.relationship_score DESC;


/*  ---------------------------------------------------------------------
    Query 3: Who does one of our colleagues know at a given firm?

    The colleague is found by email address and the firm by website.
    Results are ordered by relationship score.
    --------------------------------------------------------------------- */

WITH matched_company AS
(
    -- The firm, matched by any of its websites (deleted companies skipped)
    SELECT DISTINCT
        company.company_id
    FROM dbo.company AS company
        JOIN dbo.company_url AS website
            ON  website.team_number = company.team_number
            AND website.company_id  = company.company_id
            AND ISNULL(website.is_deleted, 0) = 0
    WHERE company.team_number = @TeamNumber
      AND website.url_text    = @CompanyWebsite
      AND ISNULL(company.is_deleted, 0) = 0
)

SELECT
    -- The contact at the firm
    contact.contact_id,
    contact.best_full_name          AS contact_name,
    contact.best_email_address      AS contact_email,

    -- Our colleague (the same person on every row)
    colleague.name                  AS colleague_name,
    colleague.email_address         AS colleague_email,

    -- How well they know each other
    relationship.relationship_score,
    relationship.latest_meeting_date

FROM dbo.colleague AS colleague

    -- Every contact this colleague has a relationship with...
    JOIN dbo.contact_introducer AS relationship
        ON  relationship.team_number  = colleague.team_number
        AND relationship.colleague_id = colleague.colleague_id
        AND ISNULL(relationship.is_deleted, 0) = 0

    JOIN dbo.contact AS contact
        ON  contact.team_number = relationship.team_number
        AND contact.contact_id  = relationship.contact_id
        AND ISNULL(contact.is_deleted, 0) = 0

WHERE colleague.team_number   = @TeamNumber
  AND colleague.email_address = @ColleagueEmail
  AND ISNULL(colleague.is_deleted, 0) = 0

  -- ...narrowed to contacts with a job at the firm.
  -- EXISTS rather than a join, so each contact appears only once.
  AND EXISTS
  (
      SELECT 1
      FROM dbo.contact_job AS job
          JOIN matched_company
              ON matched_company.company_id = job.company_id
      WHERE job.team_number = contact.team_number
        AND job.contact_id  = contact.contact_id
        AND ISNULL(job.is_deleted, 0) = 0
  )

ORDER BY
    relationship.relationship_score DESC;


/*  ---------------------------------------------------------------------
    Query 4: How much has each colleague interacted with a contact?

    Inbound and outbound message counts and meeting counts, with the
    first and latest date of each. Colleagues with no interaction at
    all are left out.
    --------------------------------------------------------------------- */

WITH matched_contact AS
(
    -- A contact can have several email addresses; match any of them
    SELECT DISTINCT
        email.contact_id
    FROM dbo.contact_email_address AS email
    WHERE email.team_number        = @TeamNumber
      AND email.email_address_text = @ContactEmail
      AND ISNULL(email.is_deleted, 0) = 0
)

SELECT
    -- The contact
    contact.contact_id,
    contact.best_full_name               AS contact_name,

    -- The colleague who interacted with them
    relationship.colleague_id,
    colleague.name                       AS colleague_name,
    colleague.email_address              AS colleague_email,

    -- How much interaction
    relationship.inbound_message_count,
    relationship.outbound_message_count,
    relationship.meeting_count,
    relationship.reciprocated_message_count,
    relationship.interaction_count,
    relationship.relationship_score,

    -- When it started and when it last happened
    relationship.first_inbound_message_date,
    relationship.latest_inbound_message_date,
    relationship.first_outbound_message_date,
    relationship.latest_outbound_message_date,
    relationship.first_meeting_date,
    relationship.latest_meeting_date,

    -- When Tako calculated these numbers
    relationship.valid_as_of

FROM dbo.contact AS contact

    JOIN matched_contact
        ON matched_contact.contact_id = contact.contact_id

    -- contact_introducer holds one row per (contact, colleague) pair
    JOIN dbo.contact_introducer AS relationship
        ON  relationship.team_number = contact.team_number
        AND relationship.contact_id  = contact.contact_id
        AND ISNULL(relationship.is_deleted, 0) = 0

    -- LEFT JOIN so a row is kept even if the colleague record is missing
    LEFT JOIN dbo.colleague AS colleague
        ON  colleague.team_number  = relationship.team_number
        AND colleague.colleague_id = relationship.colleague_id
        AND ISNULL(colleague.is_deleted, 0) = 0

WHERE contact.team_number = @TeamNumber
  AND ISNULL(contact.is_deleted, 0) = 0

  -- Leave out colleagues with no interaction at all.
  -- ISNULL matters: one NULL count would make the whole sum NULL.
  AND (   ISNULL(relationship.inbound_message_count,  0)
        + ISNULL(relationship.outbound_message_count, 0)
        + ISNULL(relationship.meeting_count,          0) ) > 0

ORDER BY
    relationship.interaction_count DESC;
