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
 Query 1: Which colleagues know a contact (identified via email 
		  address) and how well?
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
WHERE cea.email_address_text = 'jaspreet@dotalign.com'
ORDER BY ci.relationship_score DESC

/*
=====================================================================
 Query 2: Which colleagues know a company (identified by website) and 
		  how well?
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
WHERE cu.url_text = 'dotalign.com'
ORDER BY ci.relationship_score DESC

/*
=====================================================================
 Query 3: What are all the relationships of one of our colleagues, 
		  at a firm specified by its domain (ordered by relationship 
		  score)?
 ====================================================================
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
    INNER JOIN contact_introducer_active AS ci ON ci.contact_id = c.contact_id
    INNER JOIN colleague_active AS col ON col.colleague_id = ci.colleague_id
	INNER JOIN contact_job_active cj ON cj.contact_id = c.contact_id
	INNER JOIN company_active com ON com.company_id = cj.company_id
	INNER JOIN company_url_active cu ON cu.company_id = com.company_id
WHERE cu.url_text = 'dotalign.com'
	AND col.email_address = 'ourcolleague@ourfirm.com'
ORDER BY ci.relationship_score DESC