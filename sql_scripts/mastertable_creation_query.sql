drop table if exists mastertable;

create table mastertable (
    master_id serial primary key,

    -- user info
    user_id uuid,
    email text,
    gender text,
    city text,
    state text,
    creation_date timestamp without time zone,
    last_modified_date timestamp without time zone,
    birthdate date,
    zip_code text,

    -- learner info
    learner_id text,
    country text,
    degree text,
    institution text,
    major text,

    -- opportunity info
    opportunity_id text,
    opportunity_name text,
    category text,
    opportunity_code text,
    tracking_questions text,

    -- cohort info
    cohort_id int,
    cohort_code text,
    start_date date,
    end_date date,
    cohort_size int,

    -- enrollment info
    apply_date date,
    status text,

    load_timestamp timestamp default current_timestamp
);