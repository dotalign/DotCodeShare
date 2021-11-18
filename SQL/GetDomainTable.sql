-- INSTRUCTIONS
-- ============

-- Execute the CREATE FUNCTION statement below to create the function
-- in your SQL Server. Once created, you can invoke it via a call like
-- the following. This function returns a table so the return value 
-- must be treated as such.

-- 1. SELECT dbo.GetDomainTable('https://www.google.com/mail')

CREATE FUNCTION dbo.GetDomainTable(@url VARCHAR(1024))
RETURNS @result TABLE 
(
    hostName VARCHAR(512),
    hostNameWithSubdomains VARCHAR(512),
    originalUrl VARCHAR(1024)
)
AS
BEGIN
	DECLARE @hostName varchar(1000)
	SET @hostName = @url

	-- Replace some standard prefixes
	SELECT @hostName = REPLACE(@hostName, 'https://', '')
	SELECT @hostName = REPLACE(@hostName, 'http://', '')
	SELECT @hostName = REPLACE(@hostName, 'www.', '')
	SELECT @hostName = REPLACE(@hostName, 'ftp://', '')
		
	-- Remove everything after the '/', if there is one
	IF CHARINDEX('/', @hostName) > 0 
		SELECT @hostName = LEFT(@hostName, CHARINDEX('/', @hostName)-1)

	DECLARE @hostNameWithSubdomains varchar(512)
	SET @hostNameWithSubdomains = @hostName

	-- Special handling for second level domains like dotalign.com.au or dotalign.co.uk
	-- More info can be found here https://en.wikipedia.org/wiki/Second-level_domain
	DECLARE @secondLevelDomains TABLE (DomainName VARCHAR(20))
		
	-- List of second level domain names we're handling
	INSERT INTO @secondLevelDomains(DomainName) 
	VALUES	('co'), 
			('com'), 
			('firm'),
			('net'),
			('org'), 
			('gen'), 
			('ernet'), 
			('ac'), 
			('edu'), 
			('res'), 
			('gov'), 
			('mil')

	DECLARE @sld VARCHAR(20)
	set @sld = PARSENAME(@hostName, 2)

	-- If the second level domain exists in the list
	IF EXISTS (SELECT * FROM @secondLevelDomains WHERE DomainName = @sld)
		SELECT @hostName = PARSENAME(@hostName, 3) + '.' + PARSENAME(@hostName, 2) + '.' + PARSENAME(@hostName, 1)				
	ELSE
		SELECT @hostName = PARSENAME(@hostName, 2) + '.' + PARSENAME(@hostName, 1)

	INSERT INTO @result SELECT @hostName, @hostNameWithSubdomains, @url
	RETURN
END

-- TESTS
-- =====

--SELECT * from dbo.GetDomainTable('www.nescol.ac.uk')
--UNION
--SELECT * from dbo.GetDomainTable('https://books.gosimplebooks.co.uk/')
--UNION
--SELECT * from dbo.GetDomainTable('http://www.bas.com.bh/')
--UNION
--SELECT * from dbo.GetDomainTable('https://business.bankofscotland.co.uk/')
--UNION
--SELECT * from dbo.GetDomainTable('https://practices.healthengine.com.au')
--UNION
--SELECT * from dbo.GetDomainTable('https://www.google.com/hello')
--UNION 
--SELECT * from dbo.GetDomainTable('https://help.dotalign.com/article/5wwii9q2b4-migrating-from-adal-to-msal')
--UNION 
--SELECT * from dbo.GetDomainTable('https://www.google.com/hello')
--UNION 
--SELECT * from dbo.GetDomainTable('https://help.dotalign.com/article/5wwii9q2b4-migrating-from-adal-to-msal')
--UNION 
--SELECT * from dbo.GetDomainTable('https://dotalign--c.documentforce.com/secur/contentDoor?startURL=https%3A%2F%2FdskipRedirect=1&lm=eyJlbmMiOiJBMjU2R0NNIijowfQ%3D%3D..TbgpNG20jF_KWTa6.Gx5Rjlh9cad9mgX0UQWYVw%3D%3D.bWYNdVsK1zeqCEd-8c8sOg%3D%3D')
--UNION 
--SELECT * from dbo.GetDomainTable('https://post.in/instructions')
--UNION 
--SELECT * from dbo.GetDomainTable('https://julio.co.uk')
--UNION 
--SELECT * from dbo.GetDomainTable('https://us.tradeshow.com')
--UNION 
--SELECT * from dbo.GetDomainTable('http://help.dotalign.com/article/5wwii9q2b4-migrating-from-adal-to-msal')
--UNION 
--SELECT * from dbo.GetDomainTable('http://dotalign--c.documentforce.com/secur/contentDoor?startURL=https%3A%2F%2FdskipRedirect=1&lm=eyJlbmMiOiJBMjU2R0NNIijowfQ%3D%3D..TbgpNG20jF_KWTa6.Gx5Rjlh9cad9mgX0UQWYVw%3D%3D.bWYNdVsK1zeqCEd-8c8sOg%3D%3D')
--UNION 
--SELECT * from dbo.GetDomainTable('http://post.in/instructions')
--UNION 
--SELECT * from dbo.GetDomainTable('http://julio.co.uk')
--UNION 
--SELECT * from dbo.GetDomainTable('http://us.tradeshow.com')
--UNION 
--SELECT * from dbo.GetDomainTable('https://dotalign.com.au/#team')
--UNION 
--SELECT * from dbo.GetDomainTable('http://dotalign.com.in/contact-us')