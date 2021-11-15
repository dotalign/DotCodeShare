CREATE FUNCTION dbo.GetDomain(@url varchar(1000), @stripSubDomains bit)
RETURNS varchar(512)
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


	IF (@stripSubDomains = 1)
	BEGIN
		DECLARE @countOfDots int;
		set @countOfDots = LEN(@hostName) - LEN(REPLACE(@hostName, '.', ''))

		-- if the domain is like dotalign.com.au or dotalign.co.uk, we keep it that way
		if (((PARSENAME(@hostName, 2) = 'co' OR PARSENAME(@hostName, 2) = 'com')) 
				AND (@countOfDots = 2))
			SELECT @hostName = @hostName
		ELSE 
			SELECT @hostName = PARSENAME(@hostName, 2) + '.' + PARSENAME(@hostName, 1)
	END

	RETURN @hostName
END