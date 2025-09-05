-- 1. Check for users who never became learners
SELECT COUNT(*) as users_never_became_learners
FROM master.mastertable 
WHERE learner_id IS NULL;

-- 2. Check for learners who never applied
SELECT COUNT(*) as learners_never_applied
FROM master.mastertable 
WHERE learner_id IS NOT NULL AND opportunity_id IS NULL;

-- 3. Check for applicants not assigned to cohorts
SELECT COUNT(*) as applicants_without_cohorts
FROM master.mastertable 
WHERE opportunity_id IS NOT NULL AND cohort_id IS NULL;

-- 4. Sample of complete records (users who went through entire journey)
SELECT user_id, email, learner_id, opportunity_name, cohort_code, status
FROM master.mastertable 
WHERE learner_id IS NOT NULL 
  AND opportunity_id IS NOT NULL 
  AND cohort_id IS NOT NULL
LIMIT 10;

-- 5. Data quality check
SELECT 
    'Total Records' as metric, COUNT(*) as count FROM master.mastertable
UNION ALL
SELECT 'Records with Email', COUNT(*) FROM master.mastertable WHERE email IS NOT NULL
UNION ALL
SELECT 'Records with Valid User ID', COUNT(*) FROM master.mastertable WHERE user_id IS NOT NULL
UNION ALL
SELECT 'Duplicate Emails', COUNT(*) - COUNT(DISTINCT email) FROM master.mastertable WHERE email IS NOT NULL;

-- 6. Learners linked to users
SELECT COUNT(*) 
FROM master.mastertable m
LEFT JOIN staging.staging_cognito c ON m.user_id = CAST(c.user_id AS UUID)
WHERE c.user_id IS NULL;

-- 7. Opportunities linked to opportunity master
SELECT COUNT(*) 
FROM master.mastertable m
LEFT JOIN clean.opportunitymaster o ON m.opportunity_id = o.opportunity_id
WHERE m.opportunity_id IS NOT NULL AND o.opportunity_id IS NULL;

-- 8. Cohorts linked to cohort master
SELECT COUNT(*) 
FROM master.mastertable m
LEFT JOIN clean.cohortmaster c ON m.cohort_id = c.cohort_id
WHERE m.cohort_id IS NOT NULL AND c.cohort_id IS NULL;

-- 9. Check for Duplicate Primary Keys
SELECT user_id, COUNT(*) 
FROM master.mastertable
GROUP BY user_id
HAVING COUNT(*) > 1;

-- 10. Check for Missing Critical Data
SELECT COUNT(*) 
FROM master.mastertable
WHERE email IS NULL OR opportunity_id IS NULL OR cohort_id IS NULL;

-- Date Consistency Checks
-- 11. Apply date is before cohort end date:
SELECT COUNT(*) 
FROM master.mastertable
WHERE apply_date > end_date;

-- 12. Start date is before end date:
SELECT COUNT(*) 
FROM clean.cohortmaster
WHERE start_date > end_date;

-- 13. checking for anomilies
SELECT status, COUNT(*)
FROM master.mastertable
GROUP BY status
ORDER BY COUNT(*) DESC;

