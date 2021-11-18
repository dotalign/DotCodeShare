-- INSTRUCTIONS 
-- ============

-- Execute the CREATE FUNCTION statement below to create the function
-- in your SQL Server. Once created, you can invoke it via calls like
-- the following:

-- 1. SELECT dbo.GetDomain('https://www.maps.google.com/directions', 0 /* stripSubDomains */)
-- 2. UPDATE Companies SET CleanDomain = dbo.GetDomain(CompanyUrl, 1 /* stripSubDomains */) 

CREATE FUNCTION dbo.GetDomain(@url VARCHAR(1024), @stripSubDomains BIT = 1)
RETURNS VARCHAR(512)
AS
BEGIN
	DECLARE @hostName VARCHAR(1024)
	SET @hostName = @url

	-- Replace some standard prefixes
	SELECT @hostName = REPLACE(@hostName, 'https://', '')
	SELECT @hostName = REPLACE(@hostName, 'http://', '')
	SELECT @hostName = REPLACE(@hostName, 'www.', '')
	SELECT @hostName = REPLACE(@hostName, 'ftp://', '')
		
	-- Remove everything after the '/', if there is one
	IF CHARINDEX('/', @hostName) > 0 
		SELECT @hostName = LEFT(@hostName, CHARINDEX('/', @hostName)-1)


	IF (@stripSubDomains = 1)
	BEGIN
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
	END

	RETURN @hostName
END

-- TESTS
-- =====

 SELECT  
	dbo.GetDomain('www.nescol.ac.uk', 1),
	dbo.GetDomain('https://books.gosimplebooks.co.uk/', 1),
	dbo.GetDomain('http://www.bas.com.bh/', 1),
	dbo.GetDomain('https://business.bankofscotland.co.uk/', 1),
	dbo.GetDomain('https://practices.healthengine.com.au', 1),
	dbo.GetDomain('https://www.google.com/mail', 1),
	dbo.GetDomain('https://help.dotalign.com/article/5wwii9q2b4-migrating-from-adal-to-msal', 1),
	dbo.GetDomain('https://dotalign--c.documentforce.com/secur/contentDoor?startURL=https%3A%2F%2FdskipRedirect=1&lm=eyJlbmMiOiJBMjU2R0NNIijowfQ%3D%3D..TbgpNG20jF_KWTa6.Gx5Rjlh9cad9mgX0UQWYVw%3D%3D.bWYNdVsK1zeqCEd-8c8sOg%3D%3D', 1),
	dbo.GetDomain('https://post.in/instructions', 1),
	dbo.GetDomain('https://julio.co.uk', 1),
	dbo.GetDomain('https://us.tradeshow.com', 1),
	dbo.GetDomain('http://help.dotalign.com/article/5wwii9q2b4-migrating-from-adal-to-msal', 1),
	dbo.GetDomain('http://dotalign--c.documentforce.com/secur/contentDoor?startURL=https%3A%2F%2FdskipRedirect=1&lm=eyJlbmMiOiJBMjU2R0NNIijowfQ%3D%3D..TbgpNG20jF_KWTa6.Gx5Rjlh9cad9mgX0UQWYVw%3D%3D.bWYNdVsK1zeqCEd-8c8sOg%3D%3D', 1),
	dbo.GetDomain('http://post.in/instructions', 1),
	dbo.GetDomain('http://julio.co.uk', 1),
	dbo.GetDomain('http://us.tradeshow.com', 1),
	dbo.GetDomain('https://dotalign.com.au/#team', 1),
	dbo.GetDomain('http://dotalign.com.in/contact-us', 1),
	dbo.GetDomain('https://www.google.com/mail', 0),
	dbo.GetDomain('https://help.dotalign.com/article/5wwii9q2b4-migrating-from-adal-to-msal', 0),
	dbo.GetDomain('https://dotalign--c.documentforce.com/secur/contentDoor?startURL=https%3A%2F%2FdskipRedirect=1&lm=eyJlbmMiOiJBMjU2R0NNIijowfQ%3D%3D..TbgpNG20jF_KWTa6.Gx5Rjlh9cad9mgX0UQWYVw%3D%3D.bWYNdVsK1zeqCEd-8c8sOg%3D%3D', 1),
	dbo.GetDomain('https://post.in/instructions', 0),
	dbo.GetDomain('https://julio.co.uk', 0),
	dbo.GetDomain('https://us.tradeshow.com', 0),
	dbo.GetDomain('http://help.dotalign.com/article/5wwii9q2b4-migrating-from-adal-to-msal', 0),
	dbo.GetDomain('http://dotalign--c.documentforce.com/secur/contentDoor?startURL=https%3A%2F%2FdskipRedirect=1&lm=eyJlbmMiOiJBMjU2R0NNIijowfQ%3D%3D..TbgpNG20jF_KWTa6.Gx5Rjlh9cad9mgX0UQWYVw%3D%3D.bWYNdVsK1zeqCEd-8c8sOg%3D%3D', 0),
	dbo.GetDomain('http://post.in/instructions', 0),
	dbo.GetDomain('http://julio.co.uk', 0),
	dbo.GetDomain('http://us.tradeshow.com', 0),
	dbo.GetDomain('https://dotalign.com.au/#team', 0),
	dbo.GetDomain('http://dotalign.com.in/contact-us', 0),
	dbo.GetDomain('www.nescol.ac.uk', 0),
	dbo.GetDomain('https://books.gosimplebooks.co.uk/', 0),
	dbo.GetDomain('http://www.bas.com.bh/', 0),
	dbo.GetDomain('https://business.bankofscotland.co.uk/', 0),
	dbo.GetDomain('https://practices.healthengine.com.au', 0)