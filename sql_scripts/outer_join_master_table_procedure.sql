create or replace procedure load_mastertable_full()
language plpgsql
as $$
begin
    -- Clear out old data if reloading
    truncate table mastertable;

    -- Insert fresh data with FULL OUTER JOINs
    insert into mastertable (
        user_id, email, gender, city, state, creation_date, last_modified_date, birthdate, zip_code,
        learner_id, country, degree, institution, major,
        opportunity_id, opportunity_name, category, opportunity_code, tracking_questions,
        cohort_id, cohort_code, start_date, end_date, cohort_size,
        apply_date, status
    )
    select distinct
        c.user_id,
        c.email,
        c.gender,
        c.city,
        c.state,
        c.creation_date,
        c.last_modified_date,
        c.birthdate,
        c.zip_code,

        l.learner_id,
        l.country,
        l.degree,
        l.institution,
        l.major,

        o.opportunity_id,
        o.opportunity_name,
        o.category,
        o.opportunity_code,
        o.tracking_questions,

        coh.cohort_id,
        coh.cohort_code,
        coh.start_date,
        coh.end_date,
        coh.size as cohort_size,   -- alias size to cohort_size

        lo.apply_date,
        lo.status
    from learneropportunitymaster lo
    full outer join learnermaster l
        on lo.enrollment_id = l.learner_id
    full outer join opportunitymaster o
        on lo.opportunity_id = o.opportunity_id
    full outer join cohortmaster coh
        on lo.assigned_cohort = coh.cohort_code
    full outer join cognitomaster c
        on l.learner_id = ('Learner#' || c.user_id);
end;
$$;

call load_mastertable_full();
select * from mastertable order by master_id asc;