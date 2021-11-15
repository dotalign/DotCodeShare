CREATE FUNCTION dbo.GetDomainTable(@url varchar(1000))
RETURNS @result TABLE 
(
    hostName varchar(512),
	hostNameWithSubdomains varchar(512),
    fulUrl varchar(1024)
)
AS
BEGIN
	DECLARE @hostName varchar(1000)
	set @hostName = @url

	-- Replace some standard prefixes
	SELECT @hostName = REPLACE(@hostName, 'https://', '')
	SELECT @hostName = REPLACE(@hostName, 'http://', '')
	SELECT @hostName = REPLACE(@hostName, 'www.', '')
	SELECT @hostName = REPLACE(@hostName, 'ftp://', '')
		
	-- Remove everything after the '/', if there is one
	IF CHARINDEX('/', @hostName) > 0 
		SELECT @hostName = LEFT(@hostName, CHARINDEX('/', @hostName)-1)

	DECLARE @hostNameWithSubdomains varchar(512)
	set @hostNameWithSubdomains = @hostName

	DECLARE @countOfDots int;
	set @countOfDots = LEN(@hostName) - LEN(REPLACE(@hostName, '.', ''))

	-- if the domain is like dotalign.com.au or dotalign.co.uk
	if (((PARSENAME(@hostNameWithSubdomains, 2) = 'co' OR PARSENAME(@hostNameWithSubdomains, 2) = 'com')) AND (@countOfDots = 2))
		SELECT @hostName = @hostNameWithSubdomains
	ELSE 
		SELECT @hostName = PARSENAME(@hostNameWithSubdomains, 2) + '.' + PARSENAME(@hostNameWithSubdomains, 1)

	INSERT INTO @result SELECT @hostName, @hostNameWithSubdomains, @url
	RETURN
END

-- TESTS
-- select * from dbo.GetDomainTable('https://www.google.com/hello')
-- UNION 
-- select * from dbo.GetDomainTable('https://help.dotalign.com/article/5wwii9q2b4-migrating-from-adal-to-msal')
-- UNION 
-- select * from dbo.GetDomainTable('https://www.google.com/hello')
-- UNION 
-- select * from dbo.GetDomainTable('https://help.dotalign.com/article/5wwii9q2b4-migrating-from-adal-to-msal')
-- UNION 
-- select * from dbo.GetDomainTable('https://dotalign--c.documentforce.com/secur/contentDoor?startURL=https%3A%2F%2FdskipRedirect=1&lm=eyJlbmMiOiJBMjU2R0NNIijowfQ%3D%3D..TbgpNG20jF_KWTa6.Gx5Rjlh9cad9mgX0UQWYVw%3D%3D.bWYNdVsK1zeqCEd-8c8sOg%3D%3D')
-- UNION 
-- select * from dbo.GetDomainTable('https://post.in/instructions')
-- UNION 
-- select * from dbo.GetDomainTable('https://julio.co.uk')
-- UNION 
-- select * from dbo.GetDomainTable('https://us.tradeshow.com')
-- UNION 
-- select * from dbo.GetDomainTable('http://help.dotalign.com/article/5wwii9q2b4-migrating-from-adal-to-msal')
-- UNION 
-- select * from dbo.GetDomainTable('http://dotalign--c.documentforce.com/secur/contentDoor?startURL=https%3A%2F%2FdskipRedirect=1&lm=eyJlbmMiOiJBMjU2R0NNIijowfQ%3D%3D..TbgpNG20jF_KWTa6.Gx5Rjlh9cad9mgX0UQWYVw%3D%3D.bWYNdVsK1zeqCEd-8c8sOg%3D%3D')
-- UNION 
-- select * from dbo.GetDomainTable('http://post.in/instructions')
-- UNION 
-- select * from dbo.GetDomainTable('http://julio.co.uk')
-- UNION 
-- select * from dbo.GetDomainTable('http://us.tradeshow.com')
-- UNION 
-- select * from dbo.GetDomainTable('https://dotalign.com.au/#team')
-- UNION 
-- select * from dbo.GetDomainTable('http://dotalign.com.in/contact-us')

