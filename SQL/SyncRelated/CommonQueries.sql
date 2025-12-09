/* 
=====================================================================
 Initialize Active Views
 --------------------------------------------------------------------
 Run this once to generate the *_active views for the desired team.
 This ensures queries automatically filter by team_number and is_deleted.
 
     EXEC dbo.CreateActiveViews @teamNumber = 1;

=====================================================================
*/


/*
=====================================================================
 Query 1: Find all introducers for a contact (identified via email)
=====================================================================
*/
SELECT
    c.contact_id,
    c.best_full_name,
    c.best_email_address,
    col.name,
    col.email_address,
    ci.relationship_score,
    ci.latest_meeting_date
FROM contact_active AS c
    INNER JOIN contact_email_address_active AS cea 
        ON cea.contact_id = c.contact_id
    INNER JOIN contact_introducer_active AS ci 
        ON ci.contact_id = c.contact_id
    INNER JOIN colleague_active AS col
        ON col.colleague_id = ci.colleague_id
WHERE cea.email_address_text = 'jaspreet@dotalign.com';


/*
=====================================================================
 Query 2: Find all introducers for a company (identified via domain)
=====================================================================
*/
SELECT
    c.company_id,
    c.best_name,
    c.best_url,
    col.name,
    col.email_address,
    ci.relationship_score,
    ci.latest_meeting_date
FROM company_active AS c
    INNER JOIN company_url_active AS cu
        ON cu.company_id = c.company_id
    INNER JOIN company_introducer_active AS ci
        ON ci.company_id = c.company_id
    INNER JOIN colleague_active AS col
        ON col.colleague_id = ci.colleague_id
WHERE cu.url_text = 'dotalign.com';