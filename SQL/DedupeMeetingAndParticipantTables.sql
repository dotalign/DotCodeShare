-- MEETING

CREATE TABLE da.deduped_meeting (
	[id] [int] IDENTITY(1,1) NOT NULL,
	[meeting_id] [nvarchar](256) NULL,
	[concept_key] [nvarchar](256) NULL,
	[subject] [nvarchar](256) NULL,
	[organizer_email_address] [nvarchar](256) NULL,
	[created_date] [datetime] NULL,
	[start_date] [datetime] NULL,
	[end_date] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

INSERT INTO da.deduped_meeting
SELECT m.meeting_id, m.concept_key, m.subject, m.organizer_email_address, m.created_date, m.start_date, m.end_date
FROM da.meeting m
GROUP BY m.meeting_id, m.concept_key, m.subject, m.organizer_email_address, m.created_date, m.start_date, m.end_date

-- MEETING PARTICIPANT

CREATE TABLE da.deduped_meeting_participant (
	[id] [int] IDENTITY(1,1) NOT NULL,
	[meeting_id] [nvarchar](256) NULL,
	[name] [nvarchar](256) NULL,
	[email_address] [nvarchar](256) NULL,
	[domain] [nvarchar](256) NULL,
	[role] [nvarchar](256) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

INSERT INTO da.deduped_meeting_participant
SELECT p.meeting_id, p.name, p.email_address, p.domain, p.role
FROM da.meeting_participant p
GROUP BY p.meeting_id, p.name, p.email_address, p.domain, p.role