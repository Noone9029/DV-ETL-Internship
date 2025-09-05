create or replace procedure load_mastertable()
language plpgsql
as $$
begin
    -- Clear out old data if reloading
    truncate table mastertable;

    -- Insert fresh data with LEFT JOINs
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
        coh.size as cohort_size,

        lo.apply_date,
        lo.status
    from learneropportunitymaster lo
    left join learnermaster l
        on lo.enrollment_id = l.learner_id
    left join opportunitymaster o
        on lo.opportunity_id = o.opportunity_id
    left join cohortmaster coh
        on lo.assigned_cohort = coh.cohort_code
    left join cognitomaster c
        on l.learner_id = ('Learner#' || c.user_id);
end;
$$;


call load_mastertable()

select * from mastertable;