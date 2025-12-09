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
FROM contact AS c
    INNER JOIN contact_email_address AS cea 
        ON cea.contact_id = c.contact_id
    INNER JOIN contact_introducer AS ci 
        ON ci.contact_id = c.contact_id
    INNER JOIN colleague AS col
        ON col.colleague_id = ci.colleague_id
WHERE cea.email_address_text = 'jaspreet@dotalign.com'
AND c.team_number = 1 
AND cea.team_number = 1
AND ci.team_number = 1
AND col.team_number = 1
AND ci.is_deleted = 0
AND cea.is_deleted = 0
AND ci.is_deleted = 0
AND col.is_deleted = 0
ORDER BY ci.relationship_score DESC

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
FROM company AS c
    INNER JOIN company_url AS cu
        ON cu.company_id = c.company_id
    INNER JOIN company_introducer AS ci
        ON ci.company_id = c.company_id
    INNER JOIN colleague AS col
        ON col.colleague_id = ci.colleague_id
WHERE cu.url_text = 'dotalign.com'
AND c.team_number = 1 
AND cu.team_number = 1
AND ci.team_number = 1
AND col.team_number = 1
AND ci.is_deleted = 0
AND cu.is_deleted = 0
AND ci.is_deleted = 0
AND col.is_deleted = 0
ORDER BY ci.relationship_score DESC

/*
=====================================================================
 Query 3: What are all the relationships of one of our employees, at 
		  an external firm (specified by the firm's domain)? Order by 
		  strongest relationship score.
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
FROM contact AS c
    INNER JOIN contact_introducer AS ci ON ci.contact_id = c.contact_id
    INNER JOIN colleague AS col ON col.colleague_id = ci.colleague_id
	INNER JOIN contact_job cj ON cj.contact_id = c.contact_id
	INNER JOIN company com ON com.company_id = cj.company_id
	INNER JOIN company_url cu ON cu.company_id = com.company_id
WHERE cu.url_text = 'dotalign.com'
	AND col.email_address = 'ourcolleague@ourfirm.com'
AND c.team_number = 1 
AND ci.team_number = 1
AND col.team_number = 1
AND cj.team_number = 1
AND com.team_number = 1
AND cu.team_number = 1
AND c.is_deleted = 0 
AND ci.is_deleted = 0
AND col.is_deleted = 0
AND cj.is_deleted = 0
AND com.is_deleted = 0
AND cu.is_deleted = 0
ORDER BY ci.relationship_score DESC