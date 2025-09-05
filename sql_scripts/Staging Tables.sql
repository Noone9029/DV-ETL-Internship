-- Cognito Raw (User Info)
CREATE TABLE IF NOT EXISTS staging_cognito (
    user_id TEXT,
    email TEXT,
    gender TEXT,
    UserCreateDate TEXT,
    UserLastModifiedDate TEXT,
    birthdate TEXT,
    city TEXT,
    zip TEXT,
    state TEXT
);

-- Learner Raw (Profiles)
CREATE TABLE IF NOT EXISTS staging_learner (
    learner_id TEXT,
    country TEXT,
    major TEXT,
    institution TEXT,
    degree TEXT
);

-- Opportunity Raw (Programs/Opportunities)
CREATE TABLE IF NOT EXISTS staging_opportunity (
    opportunity_id TEXT,
    opportunity_name TEXT,
    category TEXT,
    opportunity_code TEXT,
    tracking_questions TEXT
);


-- Cohort Raw (Cohort Information)
CREATE TABLE IF NOT EXISTS staging_cohort (
    cohort_id TEXT,
    cohort_code TEXT,
    start_date TEXT,
    end_date TEXT,
    size_numbers TEXT
);

-- LearnerOpportunity Raw (Bridge Table)
CREATE TABLE IF NOT EXISTS staging_learneropportunity (
    enrollment_id TEXT,
    learner_id TEXT,
    assigned_cohort TEXT,
    apply_date TEXT,
    status TEXT
);

select * from staging_cognito;
select * from staging_cohort;
select * from staging_learner;
select * from staging_learneropportunity;
select * from staging_opportunity;

CREATE TABLE CognitoMaster (
    user_id UUID PRIMARY KEY,
    email TEXT,
    gender TEXT,
    creation_date TIMESTAMP,
    last_modified_date TIMESTAMP,
    birthdate DATE,
    city TEXT,
    zip_code TEXT,
    state TEXT
);
INSERT INTO CognitoMaster
SELECT DISTINCT
    CAST(user_id AS UUID),
    INITCAP(email),
    CASE
        WHEN gender ILIKE 'Don%27t want to specify' THEN 'Prefer not to say'
        WHEN gender IS NULL OR gender = '' THEN 'Unknown'
        ELSE INITCAP(gender)
    END AS gender,
    CAST(UserCreateDate AS TIMESTAMP) AS creation_date,
    CAST(UserLastModifiedDate AS TIMESTAMP) AS last_modified_date,
    NULLIF(birthdate, 'NULL')::DATE AS birthdate,
    INITCAP(city) AS city,
    CASE WHEN zip ~ '^[0-9]+$' THEN zip ELSE NULL END AS zip_code,
    INITCAP(state) AS state
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY email ORDER BY UserLastModifiedDate DESC) AS rn
    FROM staging_cognito
) ranked
WHERE rn = 1;  -- keep latest record per email

select * from cognitomaster;
create table cohortmaster (
    cohort_id serial primary key,   -- auto increment integer
    cohort_code text unique,
    start_date date not null,
    end_date date not null,
    size int not null
);
insert into cohortmaster (cohort_code, start_date, end_date, size)
select distinct
    cohort_code,
    to_timestamp(cast(cast(start_date as numeric) as bigint) / 1000)::date as start_date,
    to_timestamp(cast(cast(end_date as numeric) as bigint) / 1000)::date as end_date,
    cast(size_numbers as int) as size
from staging_cohort
where cohort_code is not null
  and start_date is not null
  and end_date is not null
  and (size_numbers ~ '^[0-9]+$' and cast(size_numbers as int) > 0)
  and to_timestamp(cast(cast(start_date as numeric) as bigint) / 1000) 
      <= to_timestamp(cast(cast(end_date as numeric) as bigint) / 1000)
  and cohort_code ~ '^[a-zA-Z0-9]+$';

select * from cohortmaster;
-- auto incremented the cohort id since in raw data cohortid was duplicated entirely

CREATE TABLE LearnerMaster (
    learner_id TEXT PRIMARY KEY,
    country TEXT,
    degree TEXT,
    institution TEXT,
    major TEXT
);

INSERT INTO LearnerMaster
SELECT DISTINCT
    learner_id,
    INITCAP(country) AS country,
    INITCAP(degree) AS degree,
    INITCAP(institution) AS institution,
    INITCAP(major) AS major
FROM staging_learner
WHERE learner_id IS NOT NULL;

CREATE TABLE OpportunityMaster (
    opportunity_id TEXT PRIMARY KEY,
    opportunity_name TEXT,
    category TEXT,
    opportunity_code TEXT,
    tracking_questions TEXT
);
INSERT INTO OpportunityMaster
SELECT DISTINCT
    opportunity_id,
    INITCAP(opportunity_name) AS opportunity_name,
    INITCAP(category) AS category,
    opportunity_code,
    tracking_questions
FROM staging_opportunity
WHERE opportunity_id IS NOT NULL;


create table learneropportunitymaster (
    enrollment_id text not null,     -- actually the learner
    opportunity_id text not null,    -- renamed from learner_id
    assigned_cohort text not null,
    apply_date date,
    status text,
    constraint pk_learnopp primary key (enrollment_id, opportunity_id),
    constraint fk_learner foreign key (enrollment_id) references learnermaster(learner_id),
    constraint fk_opportunity foreign key (opportunity_id) references opportunitymaster(opportunity_id)
);
insert into learneropportunitymaster (enrollment_id, opportunity_id, assigned_cohort, apply_date, status)
select distinct
    enrollment_id,
    learner_id as opportunity_id,
    assigned_cohort,
    case 
        when apply_date ilike 'NULL' then null
        else cast(apply_date as timestamp)
    end::date as apply_date,
    status
from staging_learneropportunity
where enrollment_id like 'Learner#%'
  and learner_id like 'Opportunity#%'
  and assigned_cohort is not null;

select * from learneropportunitymaster;

--there were enrollment_id rows in the data set that started with opportunity so we skip those.
--around 200 rows with dirty data removed