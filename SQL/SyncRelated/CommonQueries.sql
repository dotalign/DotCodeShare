/*  =====================================================================
    Relationship queries for the DotAlign sync database
    =====================================================================

    The sync database is a SQL Server copy of DotAlign relationship data.
    Every table is split by team (team_number).

    How to use:
      1. Set the parameters below.
      2. Run the whole file (one result set per query), or highlight
         the DECLARE block together with the one query you want.

    Notes:
      - Relationship scores, counts and dates are aggregates as of
        the last sync (valid_as_of). They are not recounted here.
      - In lists of meeting attendees, people are shown by email address,
        or by name when there is no address.
      - Queries 5 to 10 use STRING_AGG, which needs SQL Server 2017 or
        later (or Azure SQL).
    ===================================================================== */

DECLARE @TeamNumber     int           = 1;
DECLARE @ContactEmail   nvarchar(256) = 'someone@example.com';    -- Queries 1, 4, 5, 7 and 9
DECLARE @CompanyWebsite nvarchar(256) = 'example.com';            -- Queries 2, 3, 6, 8 and 10 (domain only)
DECLARE @ColleagueEmail nvarchar(256) = 'colleague@ourfirm.com';  -- Query 3
DECLARE @MonthsBack     int           = 12;                       -- Queries 7 to 10
DECLARE @BucketSize     varchar(5)    = 'week';                   -- Queries 7 to 10: 'week' or 'month'


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


/*  ---------------------------------------------------------------------
    Query 5: Every meeting with a contact

    The contact is found by one email address, and a meeting counts if
    any of the contact's addresses is on the participant list.
    Most recent first.

    The sync only holds meetings inside its window, which defaults to
    two years back and three months ahead.
    --------------------------------------------------------------------- */

WITH contact_addresses AS
(
    -- Every email address of the contact, not just the one searched by
    SELECT DISTINCT
        all_addresses.email_address_text
    FROM dbo.contact_email_address AS searched
        JOIN dbo.contact_email_address AS all_addresses
            ON  all_addresses.team_number = searched.team_number
            AND all_addresses.contact_id  = searched.contact_id
            AND ISNULL(all_addresses.is_deleted, 0) = 0
    WHERE searched.team_number        = @TeamNumber
      AND searched.email_address_text = @ContactEmail
      AND ISNULL(searched.is_deleted, 0) = 0
),

contact_meetings AS
(
    -- Meetings the contact was on, once each
    SELECT DISTINCT
        participant.meeting_id
    FROM dbo.meeting_participants AS participant
        JOIN contact_addresses
            ON contact_addresses.email_address_text = participant.email_address
    WHERE participant.team_number = @TeamNumber
      AND ISNULL(participant.is_deleted, 0) = 0
)

SELECT
    -- When
    meeting.start_date_time,
    meeting.end_date_time,

    -- What
    meeting.subject,
    meeting.location,
    meeting.organizer_email_address,
    meeting.participant_count_non_bcc   AS participant_count,
    meeting.is_cancelled,

    -- Which of our colleagues were there
    colleagues_present.people           AS colleagues_present,

    -- Identifiers, for finding the meeting elsewhere
    meeting.meeting_id,
    meeting.series_master_key

FROM dbo.meetings AS meeting

    JOIN contact_meetings
        ON contact_meetings.meeting_id = meeting.meeting_id

    -- Colleagues on the participant list, as one comma-separated value.
    -- Email address where there is one, otherwise the name.
    OUTER APPLY
    (
        SELECT
            STRING_AGG(CAST(COALESCE(participant.email_address, colleague.name) AS nvarchar(max)), ', ')
                WITHIN GROUP (ORDER BY participant.email_address)
                AS people
        FROM dbo.meeting_participants AS participant
            JOIN dbo.colleague AS colleague
                ON  colleague.team_number   = participant.team_number
                AND colleague.email_address = participant.email_address
                AND ISNULL(colleague.is_deleted, 0) = 0
        WHERE participant.team_number = meeting.team_number
          AND participant.meeting_id  = meeting.meeting_id
          AND ISNULL(participant.is_deleted, 0) = 0
    ) AS colleagues_present

WHERE meeting.team_number = @TeamNumber
  AND ISNULL(meeting.is_deleted, 0) = 0
  -- AND ISNULL(meeting.is_cancelled, 0) = 0   -- uncomment to hide cancelled meetings

ORDER BY
    meeting.start_date_time DESC;


/*  ---------------------------------------------------------------------
    Query 6: Every meeting with a company

    The company is found by one website, and a meeting counts if anyone
    on the participant list belongs to any of the company's websites.
    Most recent first.

    The sync only holds meetings inside its window, which defaults to
    two years back and three months ahead.
    --------------------------------------------------------------------- */

WITH company_websites AS
(
    -- Every website of the company, not just the one searched by
    SELECT DISTINCT
        all_websites.url_text
    FROM dbo.company_url AS searched
        JOIN dbo.company_url AS all_websites
            ON  all_websites.team_number = searched.team_number
            AND all_websites.company_id  = searched.company_id
            AND ISNULL(all_websites.is_deleted, 0) = 0
    WHERE searched.team_number = @TeamNumber
      AND searched.url_text    = @CompanyWebsite
      AND ISNULL(searched.is_deleted, 0) = 0
),

company_meetings AS
(
    -- Meetings with at least one person from the company, once each
    SELECT DISTINCT
        participant.meeting_id
    FROM dbo.meeting_participants AS participant
        JOIN company_websites
            ON company_websites.url_text = participant.company_website
    WHERE participant.team_number = @TeamNumber
      AND ISNULL(participant.is_deleted, 0) = 0
)

SELECT
    -- When
    meeting.start_date_time,
    meeting.end_date_time,

    -- What
    meeting.subject,
    meeting.location,
    meeting.organizer_email_address,
    meeting.participant_count_non_bcc   AS participant_count,
    meeting.is_cancelled,

    -- Who was there, from their side and from ours
    company_attendees.people            AS company_attendees,
    colleagues_present.people           AS colleagues_present,

    -- Identifiers, for finding the meeting elsewhere
    meeting.meeting_id,
    meeting.series_master_key

FROM dbo.meetings AS meeting

    JOIN company_meetings
        ON company_meetings.meeting_id = meeting.meeting_id

    -- People from the company.
    -- Email address where there is one, otherwise the name.
    OUTER APPLY
    (
        SELECT
            STRING_AGG(CAST(COALESCE(participant.email_address, participant.display_name) AS nvarchar(max)), ', ')
                WITHIN GROUP (ORDER BY participant.email_address)
                AS people
        FROM dbo.meeting_participants AS participant
            JOIN company_websites
                ON company_websites.url_text = participant.company_website
        WHERE participant.team_number = meeting.team_number
          AND participant.meeting_id  = meeting.meeting_id
          AND ISNULL(participant.is_deleted, 0) = 0
    ) AS company_attendees

    -- Our colleagues on the participant list, the same way
    OUTER APPLY
    (
        SELECT
            STRING_AGG(CAST(COALESCE(participant.email_address, colleague.name) AS nvarchar(max)), ', ')
                WITHIN GROUP (ORDER BY participant.email_address)
                AS people
        FROM dbo.meeting_participants AS participant
            JOIN dbo.colleague AS colleague
                ON  colleague.team_number   = participant.team_number
                AND colleague.email_address = participant.email_address
                AND ISNULL(colleague.is_deleted, 0) = 0
        WHERE participant.team_number = meeting.team_number
          AND participant.meeting_id  = meeting.meeting_id
          AND ISNULL(participant.is_deleted, 0) = 0
    ) AS colleagues_present

WHERE meeting.team_number = @TeamNumber
  AND ISNULL(meeting.is_deleted, 0) = 0
  -- AND ISNULL(meeting.is_cancelled, 0) = 0   -- uncomment to hide cancelled meetings

ORDER BY
    meeting.start_date_time DESC;


/*  ---------------------------------------------------------------------
    Query 7: Meetings with a contact over time, and who was there

    One row per week or month (@BucketSize), going back @MonthsBack
    months. Each row has:
      - meeting_count:          meetings with the contact in that bucket
      - colleagues:             our DotAlign contributors who attended
      - internal_participants:  other people from our firm
      - external_participants:  everyone outside our firm, the contact
                                included
    People are listed most frequent first as "email (meetings)", for
    example "alice@ourfirm.com (3), bob@ourfirm.com (2)", or by name
    when there is no address. Buckets with no meetings still appear,
    with a count of zero.

    - "Our firm" means the email domains our colleagues use.
    - Weeks start on Monday. The first bucket is widened back to a whole
      week or month, and the last one is the current, unfinished bucket.
    - Only meetings that have already started are counted.
      Cancelled meetings are left out.
    - Times are in UTC.
    - The sync keeps about two years of meeting history by default, so
      buckets before that show zero.
    - Per-person counts can add up to more than meeting_count. A meeting
      that two people attended counts once for each of them.
    --------------------------------------------------------------------- */

WITH contact_addresses AS
(
    -- Every email address of the contact, not just the one searched by
    SELECT DISTINCT
        all_addresses.email_address_text
    FROM dbo.contact_email_address AS searched
        JOIN dbo.contact_email_address AS all_addresses
            ON  all_addresses.team_number = searched.team_number
            AND all_addresses.contact_id  = searched.contact_id
            AND ISNULL(all_addresses.is_deleted, 0) = 0
    WHERE searched.team_number        = @TeamNumber
      AND searched.email_address_text = @ContactEmail
      AND ISNULL(searched.is_deleted, 0) = 0
),

contact_meetings AS
(
    -- Meetings that have started, with any of the contact's addresses on
    -- the participant list
    SELECT
        meeting.meeting_id,
        meeting.start_date_time
    FROM dbo.meetings AS meeting
    WHERE meeting.team_number = @TeamNumber
      AND ISNULL(meeting.is_deleted,   0) = 0
      AND ISNULL(meeting.is_cancelled, 0) = 0
      AND meeting.start_date_time < SYSUTCDATETIME()
      AND EXISTS
      (
          SELECT 1
          FROM dbo.meeting_participants AS participant
              JOIN contact_addresses
                  ON contact_addresses.email_address_text = participant.email_address
          WHERE participant.team_number = meeting.team_number
            AND participant.meeting_id  = meeting.meeting_id
            AND ISNULL(participant.is_deleted, 0) = 0
      )
),

our_domains AS
(
    -- Our firm's email domains, taken from our colleagues' addresses
    SELECT DISTINCT
        SUBSTRING(colleague.email_address, CHARINDEX('@', colleague.email_address) + 1, 256) AS domain
    FROM dbo.colleague AS colleague
    WHERE colleague.team_number = @TeamNumber
      AND colleague.email_address LIKE '%@%'
),

attendance AS
(
    -- One row per (meeting, person) for everyone on the contact's meetings,
    -- the contact included, each labelled colleague, internal or external
    SELECT
        meeting.meeting_id,
        meeting.start_date_time,
        CASE
            WHEN colleague.colleague_id IS NOT NULL THEN 'colleague'
            WHEN our_domains.domain     IS NOT NULL THEN 'internal'
            ELSE                                         'external'
        END AS participant_type,

        -- Email address where there is one, otherwise the name
        COALESCE(participant.email_address, colleague.name, participant.display_name) AS person
    FROM contact_meetings AS meeting
        JOIN dbo.meeting_participants AS participant
            ON  participant.team_number = @TeamNumber
            AND participant.meeting_id  = meeting.meeting_id
            AND ISNULL(participant.is_deleted, 0) = 0

        -- Is this person one of our colleagues?
        LEFT JOIN dbo.colleague AS colleague
            ON  colleague.team_number   = participant.team_number
            AND colleague.email_address = participant.email_address
            AND ISNULL(colleague.is_deleted, 0) = 0

        -- If not, are they at one of our domains?
        LEFT JOIN our_domains
            ON our_domains.domain = SUBSTRING(participant.email_address, CHARINDEX('@', participant.email_address) + 1, 256)
),

first_bucket AS
(
    -- @MonthsBack ago, moved back to the start of its week or month
    SELECT
        CASE @BucketSize
            -- 1 Jan 1900 was a Monday, so this steps back to the latest Monday
            WHEN 'week' THEN DATEADD(day, -(DATEDIFF(day, '19000101', months_back.day) % 7), months_back.day)
            ELSE             DATEFROMPARTS(YEAR(months_back.day), MONTH(months_back.day), 1)
        END AS bucket_start
    FROM
    (
        SELECT CAST(DATEADD(month, -@MonthsBack, SYSUTCDATETIME()) AS date) AS day
    ) AS months_back
),

buckets AS
(
    -- Every week or month from the first bucket up to the current one.
    -- Each bucket runs from bucket_start up to, but not including, bucket_end.
    SELECT
        first_bucket.bucket_start,
        CASE @BucketSize
            WHEN 'week' THEN DATEADD(week,  1, first_bucket.bucket_start)
            ELSE             DATEADD(month, 1, first_bucket.bucket_start)
        END AS bucket_end
    FROM first_bucket

    UNION ALL

    SELECT
        buckets.bucket_end,
        CASE @BucketSize
            WHEN 'week' THEN DATEADD(week,  1, buckets.bucket_end)
            ELSE             DATEADD(month, 1, buckets.bucket_end)
        END
    FROM buckets
    WHERE buckets.bucket_end <= CAST(SYSUTCDATETIME() AS date)
)

SELECT
    buckets.bucket_start,
    meetings.meeting_count,
    people.colleagues,
    people.internal_participants,
    people.external_participants

FROM buckets

    -- How many meetings fell in the bucket (zero when none)
    CROSS APPLY
    (
        SELECT
            COUNT(*) AS meeting_count
        FROM contact_meetings AS meeting
        WHERE meeting.start_date_time >= buckets.bucket_start
          AND meeting.start_date_time <  buckets.bucket_end
    ) AS meetings

    -- Who attended, as one list per participant type.
    -- STRING_AGG skips NULLs, so each CASE keeps only its own type.
    OUTER APPLY
    (
        SELECT
            STRING_AGG(CASE WHEN per_person.participant_type = 'colleague' THEN per_person.label END, ', ')
                WITHIN GROUP (ORDER BY per_person.meeting_count DESC, per_person.person)
                AS colleagues,

            STRING_AGG(CASE WHEN per_person.participant_type = 'internal'  THEN per_person.label END, ', ')
                WITHIN GROUP (ORDER BY per_person.meeting_count DESC, per_person.person)
                AS internal_participants,

            STRING_AGG(CASE WHEN per_person.participant_type = 'external'  THEN per_person.label END, ', ')
                WITHIN GROUP (ORDER BY per_person.meeting_count DESC, per_person.person)
                AS external_participants
        FROM
        (
            -- One entry per person in the bucket, labelled "email (meetings)".
            -- nvarchar(max) so long lists don't hit STRING_AGG's 8,000-byte limit.
            SELECT
                attendance.participant_type,
                attendance.person,
                COUNT(*) AS meeting_count,
                CONCAT(CAST(attendance.person AS nvarchar(max)), ' (', COUNT(*), ')') AS label
            FROM attendance
            WHERE attendance.start_date_time >= buckets.bucket_start
              AND attendance.start_date_time <  buckets.bucket_end
            GROUP BY
                attendance.participant_type,
                attendance.person
        ) AS per_person
    ) AS people

ORDER BY
    buckets.bucket_start

-- The default limit of 100 buckets would stop at about two years of weeks
OPTION (MAXRECURSION 1000);


/*  ---------------------------------------------------------------------
    Query 8: Meetings with a company over time, and who was there

    The same as Query 7, but for a company. A meeting counts if anyone on
    the participant list belongs to one of the company's websites.
    external_participants includes the company's own people.
    The bucket rules in Query 7 apply here too.
    --------------------------------------------------------------------- */

WITH company_websites AS
(
    -- Every website of the company, not just the one searched by
    SELECT DISTINCT
        all_websites.url_text
    FROM dbo.company_url AS searched
        JOIN dbo.company_url AS all_websites
            ON  all_websites.team_number = searched.team_number
            AND all_websites.company_id  = searched.company_id
            AND ISNULL(all_websites.is_deleted, 0) = 0
    WHERE searched.team_number = @TeamNumber
      AND searched.url_text    = @CompanyWebsite
      AND ISNULL(searched.is_deleted, 0) = 0
),

company_meetings AS
(
    -- Meetings that have started, with at least one person from the company
    SELECT
        meeting.meeting_id,
        meeting.start_date_time
    FROM dbo.meetings AS meeting
    WHERE meeting.team_number = @TeamNumber
      AND ISNULL(meeting.is_deleted,   0) = 0
      AND ISNULL(meeting.is_cancelled, 0) = 0
      AND meeting.start_date_time < SYSUTCDATETIME()
      AND EXISTS
      (
          SELECT 1
          FROM dbo.meeting_participants AS participant
              JOIN company_websites
                  ON company_websites.url_text = participant.company_website
          WHERE participant.team_number = meeting.team_number
            AND participant.meeting_id  = meeting.meeting_id
            AND ISNULL(participant.is_deleted, 0) = 0
      )
),

our_domains AS
(
    -- Our firm's email domains, taken from our colleagues' addresses
    SELECT DISTINCT
        SUBSTRING(colleague.email_address, CHARINDEX('@', colleague.email_address) + 1, 256) AS domain
    FROM dbo.colleague AS colleague
    WHERE colleague.team_number = @TeamNumber
      AND colleague.email_address LIKE '%@%'
),

attendance AS
(
    -- One row per (meeting, person) for everyone on the company's meetings,
    -- the company's own people included, each labelled colleague, internal
    -- or external
    SELECT
        meeting.meeting_id,
        meeting.start_date_time,
        CASE
            WHEN colleague.colleague_id IS NOT NULL THEN 'colleague'
            WHEN our_domains.domain     IS NOT NULL THEN 'internal'
            ELSE                                         'external'
        END AS participant_type,

        -- Email address where there is one, otherwise the name
        COALESCE(participant.email_address, colleague.name, participant.display_name) AS person
    FROM company_meetings AS meeting
        JOIN dbo.meeting_participants AS participant
            ON  participant.team_number = @TeamNumber
            AND participant.meeting_id  = meeting.meeting_id
            AND ISNULL(participant.is_deleted, 0) = 0

        -- Is this person one of our colleagues?
        LEFT JOIN dbo.colleague AS colleague
            ON  colleague.team_number   = participant.team_number
            AND colleague.email_address = participant.email_address
            AND ISNULL(colleague.is_deleted, 0) = 0

        -- If not, are they at one of our domains?
        LEFT JOIN our_domains
            ON our_domains.domain = SUBSTRING(participant.email_address, CHARINDEX('@', participant.email_address) + 1, 256)
),

first_bucket AS
(
    -- @MonthsBack ago, moved back to the start of its week or month
    SELECT
        CASE @BucketSize
            -- 1 Jan 1900 was a Monday, so this steps back to the latest Monday
            WHEN 'week' THEN DATEADD(day, -(DATEDIFF(day, '19000101', months_back.day) % 7), months_back.day)
            ELSE             DATEFROMPARTS(YEAR(months_back.day), MONTH(months_back.day), 1)
        END AS bucket_start
    FROM
    (
        SELECT CAST(DATEADD(month, -@MonthsBack, SYSUTCDATETIME()) AS date) AS day
    ) AS months_back
),

buckets AS
(
    -- Every week or month from the first bucket up to the current one.
    -- Each bucket runs from bucket_start up to, but not including, bucket_end.
    SELECT
        first_bucket.bucket_start,
        CASE @BucketSize
            WHEN 'week' THEN DATEADD(week,  1, first_bucket.bucket_start)
            ELSE             DATEADD(month, 1, first_bucket.bucket_start)
        END AS bucket_end
    FROM first_bucket

    UNION ALL

    SELECT
        buckets.bucket_end,
        CASE @BucketSize
            WHEN 'week' THEN DATEADD(week,  1, buckets.bucket_end)
            ELSE             DATEADD(month, 1, buckets.bucket_end)
        END
    FROM buckets
    WHERE buckets.bucket_end <= CAST(SYSUTCDATETIME() AS date)
)

SELECT
    buckets.bucket_start,
    meetings.meeting_count,
    people.colleagues,
    people.internal_participants,
    people.external_participants

FROM buckets

    -- How many meetings fell in the bucket (zero when none)
    CROSS APPLY
    (
        SELECT
            COUNT(*) AS meeting_count
        FROM company_meetings AS meeting
        WHERE meeting.start_date_time >= buckets.bucket_start
          AND meeting.start_date_time <  buckets.bucket_end
    ) AS meetings

    -- Who attended, as one list per participant type.
    -- STRING_AGG skips NULLs, so each CASE keeps only its own type.
    OUTER APPLY
    (
        SELECT
            STRING_AGG(CASE WHEN per_person.participant_type = 'colleague' THEN per_person.label END, ', ')
                WITHIN GROUP (ORDER BY per_person.meeting_count DESC, per_person.person)
                AS colleagues,

            STRING_AGG(CASE WHEN per_person.participant_type = 'internal'  THEN per_person.label END, ', ')
                WITHIN GROUP (ORDER BY per_person.meeting_count DESC, per_person.person)
                AS internal_participants,

            STRING_AGG(CASE WHEN per_person.participant_type = 'external'  THEN per_person.label END, ', ')
                WITHIN GROUP (ORDER BY per_person.meeting_count DESC, per_person.person)
                AS external_participants
        FROM
        (
            -- One entry per person in the bucket, labelled "email (meetings)".
            -- nvarchar(max) so long lists don't hit STRING_AGG's 8,000-byte limit.
            SELECT
                attendance.participant_type,
                attendance.person,
                COUNT(*) AS meeting_count,
                CONCAT(CAST(attendance.person AS nvarchar(max)), ' (', COUNT(*), ')') AS label
            FROM attendance
            WHERE attendance.start_date_time >= buckets.bucket_start
              AND attendance.start_date_time <  buckets.bucket_end
            GROUP BY
                attendance.participant_type,
                attendance.person
        ) AS per_person
    ) AS people

ORDER BY
    buckets.bucket_start

-- The default limit of 100 buckets would stop at about two years of weeks
OPTION (MAXRECURSION 1000);


/*  ---------------------------------------------------------------------
    Query 9: Meetings with a contact over time, per colleague (for charts)

    One row per (bucket, colleague), with the number of the contact's
    meetings that colleague attended in that bucket. Colleagues are shown
    by email address, or by name when there is no address. In Excel or
    Power BI, put bucket_start on the axis and colleague in the legend to
    get a stacked bar per bucket.

    - The bucket rules in Query 7 apply here too.
    - The stacked total is colleague attendances, not meetings. A meeting
      two colleagues attended counts once for each of them, so label the
      axis accordingly. Query 7 has the true meeting count.
    - A bucket with no meetings appears once, with an empty colleague
      and a count of zero, so the time axis has no gaps.
    --------------------------------------------------------------------- */

WITH contact_addresses AS
(
    -- Every email address of the contact, not just the one searched by
    SELECT DISTINCT
        all_addresses.email_address_text
    FROM dbo.contact_email_address AS searched
        JOIN dbo.contact_email_address AS all_addresses
            ON  all_addresses.team_number = searched.team_number
            AND all_addresses.contact_id  = searched.contact_id
            AND ISNULL(all_addresses.is_deleted, 0) = 0
    WHERE searched.team_number        = @TeamNumber
      AND searched.email_address_text = @ContactEmail
      AND ISNULL(searched.is_deleted, 0) = 0
),

contact_meetings AS
(
    -- Meetings that have started, with any of the contact's addresses on
    -- the participant list
    SELECT
        meeting.meeting_id,
        meeting.start_date_time
    FROM dbo.meetings AS meeting
    WHERE meeting.team_number = @TeamNumber
      AND ISNULL(meeting.is_deleted,   0) = 0
      AND ISNULL(meeting.is_cancelled, 0) = 0
      AND meeting.start_date_time < SYSUTCDATETIME()
      AND EXISTS
      (
          SELECT 1
          FROM dbo.meeting_participants AS participant
              JOIN contact_addresses
                  ON contact_addresses.email_address_text = participant.email_address
          WHERE participant.team_number = meeting.team_number
            AND participant.meeting_id  = meeting.meeting_id
            AND ISNULL(participant.is_deleted, 0) = 0
      )
),

colleague_attendance AS
(
    -- One row per (meeting, colleague) for the colleagues on each meeting
    SELECT
        meeting.meeting_id,
        meeting.start_date_time,
        colleague.colleague_id,

        -- Email address where there is one, otherwise the name
        COALESCE(colleague.email_address, colleague.name) AS colleague
    FROM contact_meetings AS meeting
        JOIN dbo.meeting_participants AS participant
            ON  participant.team_number = @TeamNumber
            AND participant.meeting_id  = meeting.meeting_id
            AND ISNULL(participant.is_deleted, 0) = 0
        JOIN dbo.colleague AS colleague
            ON  colleague.team_number   = participant.team_number
            AND colleague.email_address = participant.email_address
            AND ISNULL(colleague.is_deleted, 0) = 0
),

first_bucket AS
(
    -- @MonthsBack ago, moved back to the start of its week or month
    SELECT
        CASE @BucketSize
            -- 1 Jan 1900 was a Monday, so this steps back to the latest Monday
            WHEN 'week' THEN DATEADD(day, -(DATEDIFF(day, '19000101', months_back.day) % 7), months_back.day)
            ELSE             DATEFROMPARTS(YEAR(months_back.day), MONTH(months_back.day), 1)
        END AS bucket_start
    FROM
    (
        SELECT CAST(DATEADD(month, -@MonthsBack, SYSUTCDATETIME()) AS date) AS day
    ) AS months_back
),

buckets AS
(
    -- Every week or month from the first bucket up to the current one.
    -- Each bucket runs from bucket_start up to, but not including, bucket_end.
    SELECT
        first_bucket.bucket_start,
        CASE @BucketSize
            WHEN 'week' THEN DATEADD(week,  1, first_bucket.bucket_start)
            ELSE             DATEADD(month, 1, first_bucket.bucket_start)
        END AS bucket_end
    FROM first_bucket

    UNION ALL

    SELECT
        buckets.bucket_end,
        CASE @BucketSize
            WHEN 'week' THEN DATEADD(week,  1, buckets.bucket_end)
            ELSE             DATEADD(month, 1, buckets.bucket_end)
        END
    FROM buckets
    WHERE buckets.bucket_end <= CAST(SYSUTCDATETIME() AS date)
)

SELECT
    buckets.bucket_start,
    attendance.colleague,
    COUNT(attendance.meeting_id)    AS meeting_count

FROM buckets

    -- LEFT JOIN so buckets with no meetings are kept, with a count of zero
    LEFT JOIN colleague_attendance AS attendance
        ON  attendance.start_date_time >= buckets.bucket_start
        AND attendance.start_date_time <  buckets.bucket_end

GROUP BY
    buckets.bucket_start,
    attendance.colleague_id,
    attendance.colleague

ORDER BY
    buckets.bucket_start,
    meeting_count DESC

-- The default limit of 100 buckets would stop at about two years of weeks
OPTION (MAXRECURSION 1000);


/*  ---------------------------------------------------------------------
    Query 10: Meetings with a company over time, per colleague (for charts)

    The same as Query 9, but for a company. A meeting counts if anyone on
    the participant list belongs to one of the company's websites.
    The bucket rules in Query 7 and the charting notes in Query 9 apply.
    --------------------------------------------------------------------- */

WITH company_websites AS
(
    -- Every website of the company, not just the one searched by
    SELECT DISTINCT
        all_websites.url_text
    FROM dbo.company_url AS searched
        JOIN dbo.company_url AS all_websites
            ON  all_websites.team_number = searched.team_number
            AND all_websites.company_id  = searched.company_id
            AND ISNULL(all_websites.is_deleted, 0) = 0
    WHERE searched.team_number = @TeamNumber
      AND searched.url_text    = @CompanyWebsite
      AND ISNULL(searched.is_deleted, 0) = 0
),

company_meetings AS
(
    -- Meetings that have started, with at least one person from the company
    SELECT
        meeting.meeting_id,
        meeting.start_date_time
    FROM dbo.meetings AS meeting
    WHERE meeting.team_number = @TeamNumber
      AND ISNULL(meeting.is_deleted,   0) = 0
      AND ISNULL(meeting.is_cancelled, 0) = 0
      AND meeting.start_date_time < SYSUTCDATETIME()
      AND EXISTS
      (
          SELECT 1
          FROM dbo.meeting_participants AS participant
              JOIN company_websites
                  ON company_websites.url_text = participant.company_website
          WHERE participant.team_number = meeting.team_number
            AND participant.meeting_id  = meeting.meeting_id
            AND ISNULL(participant.is_deleted, 0) = 0
      )
),

colleague_attendance AS
(
    -- One row per (meeting, colleague) for the colleagues on each meeting
    SELECT
        meeting.meeting_id,
        meeting.start_date_time,
        colleague.colleague_id,

        -- Email address where there is one, otherwise the name
        COALESCE(colleague.email_address, colleague.name) AS colleague
    FROM company_meetings AS meeting
        JOIN dbo.meeting_participants AS participant
            ON  participant.team_number = @TeamNumber
            AND participant.meeting_id  = meeting.meeting_id
            AND ISNULL(participant.is_deleted, 0) = 0
        JOIN dbo.colleague AS colleague
            ON  colleague.team_number   = participant.team_number
            AND colleague.email_address = participant.email_address
            AND ISNULL(colleague.is_deleted, 0) = 0
),

first_bucket AS
(
    -- @MonthsBack ago, moved back to the start of its week or month
    SELECT
        CASE @BucketSize
            -- 1 Jan 1900 was a Monday, so this steps back to the latest Monday
            WHEN 'week' THEN DATEADD(day, -(DATEDIFF(day, '19000101', months_back.day) % 7), months_back.day)
            ELSE             DATEFROMPARTS(YEAR(months_back.day), MONTH(months_back.day), 1)
        END AS bucket_start
    FROM
    (
        SELECT CAST(DATEADD(month, -@MonthsBack, SYSUTCDATETIME()) AS date) AS day
    ) AS months_back
),

buckets AS
(
    -- Every week or month from the first bucket up to the current one.
    -- Each bucket runs from bucket_start up to, but not including, bucket_end.
    SELECT
        first_bucket.bucket_start,
        CASE @BucketSize
            WHEN 'week' THEN DATEADD(week,  1, first_bucket.bucket_start)
            ELSE             DATEADD(month, 1, first_bucket.bucket_start)
        END AS bucket_end
    FROM first_bucket

    UNION ALL

    SELECT
        buckets.bucket_end,
        CASE @BucketSize
            WHEN 'week' THEN DATEADD(week,  1, buckets.bucket_end)
            ELSE             DATEADD(month, 1, buckets.bucket_end)
        END
    FROM buckets
    WHERE buckets.bucket_end <= CAST(SYSUTCDATETIME() AS date)
)

SELECT
    buckets.bucket_start,
    attendance.colleague,
    COUNT(attendance.meeting_id)    AS meeting_count

FROM buckets

    -- LEFT JOIN so buckets with no meetings are kept, with a count of zero
    LEFT JOIN colleague_attendance AS attendance
        ON  attendance.start_date_time >= buckets.bucket_start
        AND attendance.start_date_time <  buckets.bucket_end

GROUP BY
    buckets.bucket_start,
    attendance.colleague_id,
    attendance.colleague

ORDER BY
    buckets.bucket_start,
    meeting_count DESC

-- The default limit of 100 buckets would stop at about two years of weeks
OPTION (MAXRECURSION 1000);