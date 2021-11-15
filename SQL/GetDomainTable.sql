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
	if (((PARSENAME(@hostNameWithSubdomains, 2) = 'co' OR PARSENAME(@hostNameWithSubdomains, 2) = 'com')) 
			AND (@countOfDots = 2))
		SELECT @hostName = @hostNameWithSubdomains
	ELSE 
		SELECT @hostName = PARSENAME(@hostNameWithSubdomains, 2) + '.' + PARSENAME(@hostNameWithSubdomains, 1)

	INSERT INTO @result SELECT @hostName, @hostNameWithSubdomains, @url
	RETURN
END
GO