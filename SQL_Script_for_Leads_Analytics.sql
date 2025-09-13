USE `lead_analysis`;
SELECT * FROM leads_basic_details; 
SELECT * FROM leads_demo_watched_details; 
SELECT * FROM leads_interaction_details; 
SELECT * FROM leads_reasons_for_no_interest; 
SELECT * FROM sales_managers_assigned_leads_details; 

# --------------------------------------------------------------------------------------------------------------------------------------
# DATA CLEANING
# --------------------------------------------------------------------------------------------------------------------------------------

----------------------------
# leads_basic_details table
----------------------------
SELECT * FROM leads_basic_details; 
DESCRIBE leads_basic_details;
SELECT * FROM leads_basic_details #check nulls
WHERE lead_id IS NULL 
   OR age IS NULL OR age = ''
   OR gender IS NULL OR gender = ''
   OR current_city IS NULL OR current_city = ''
   OR current_education IS NULL OR current_education = ''
   OR parent_occupation IS NULL OR parent_occupation = ''
   OR lead_gen_source IS NULL OR lead_gen_source = '';
   
SELECT lead_id, COUNT(*) #check duplicates
FROM leads_basic_details
GROUP BY lead_id
HAVING COUNT(*) > 1;

SELECT *
FROM leads_basic_details
WHERE lead_id IN (
    SELECT lead_id
    FROM leads_basic_details
    GROUP BY lead_id
    HAVING COUNT(*) > 1
);

WITH duplicate_cte AS #check duplicates by window function
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY lead_id, age, gender, current_city, current_education, parent_occupation, lead_gen_source)
AS row_num
FROM leads_basic_details
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

SELECT DISTINCT lead_gen_source #check distinct
FROM leads_basic_details;
SELECT TRIM(lead_id) AS lead_id #remove unknown spacing
FROM leads_basic_details;

----------------------------------
# leads_demo_watched_details table
----------------------------------
SELECT * FROM leads_demo_watched_details;
DESCRIBE leads_demo_watched_details;
SELECT * FROM leads_demo_watched_details #check nulls
WHERE lead_id IS NULL OR lead_id = ''
OR demo_watched_date IS NULL
OR language IS NULL OR language = ''
OR watched_percentage IS NULL
OR watched_category IS NULL;

SET SQL_SAFE_UPDATES = 0; #convert data types
UPDATE leads_demo_watched_details
SET demo_watched_date = STR_TO_DATE(demo_watched_date, '%m/%d/%Y');
ALTER TABLE leads_demo_watched_details
MODIFY demo_watched_date DATE;

ALTER TABLE leads_demo_watched_details
MODIFY watched_percentage DECIMAL(5,2);
UPDATE leads_demo_watched_details #convert data types
SET watched_percentage = ROUND(watched_percentage / 100, 2);

SELECT lead_id, COUNT(*) #check duplicates
FROM leads_demo_watched_details
GROUP BY lead_id
HAVING COUNT(*) > 1;

WITH duplicate_cte AS #check duplicates by window function
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY lead_id, demo_watched_date, language, watched_percentage, watched_category)
AS row_num
FROM leads_demo_watched_details
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

SELECT DISTINCT language #check distinct
FROM leads_demo_watched_details;

ALTER TABLE leads_demo_watched_details ADD watched_category TEXT;

UPDATE leads_demo_watched_details
SET watched_category = 
    CASE 
        WHEN watched_percentage >= 0.8 THEN 'High'
        WHEN watched_percentage >= 0.5 THEN 'Medium'
        ELSE 'Low'
    END;
    
    SELECT TRIM(watched_category) AS watched_category #remove unknown spacing
FROM leads_demo_watched_details;
    
----------------------------------
# leads_interaction_details table
----------------------------------
SELECT * FROM leads_interaction_details;
DESCRIBE leads_interaction_details;
SELECT * FROM leads_interaction_details #check nulls
WHERE jnr_sm_id IS NULL OR jnr_sm_id = ''
OR lead_id IS NULL OR lead_id = ''
OR lead_stage IS NULL OR lead_stage = ''
OR call_done_date IS NULL
OR call_status IS NULL OR call_status = ''
OR call_reason IS NULL OR call_reason = '';

SET SQL_SAFE_UPDATES = 0; #convert data types
UPDATE leads_interaction_details
SET call_done_date = STR_TO_DATE(call_done_date, '%m/%d/%Y');
ALTER TABLE leads_interaction_details
MODIFY call_done_date DATE;

SELECT lead_id, COUNT(*) #check duplicates by PK
FROM leads_interaction_details
GROUP BY lead_id
HAVING COUNT(*) > 1;

WITH duplicate_cte AS #check duplicates by window function
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY jnr_sm_id, lead_id, lead_stage,
call_done_date, call_status, call_reason)
AS row_num
FROM leads_interaction_details
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

# 1. Count the number of interactions per lead
SELECT 
    lead_id,
    COUNT(*) AS total_interactions
FROM leads_interaction_details
GROUP BY lead_id;

# 2. Take the first and last interaction
SELECT 
    lead_id,
    MIN(call_done_date) AS first_interaction,
    MAX(call_done_date) AS last_interaction
FROM leads_interaction_details
GROUP BY lead_id;

# 3. Count unique event variations per lead
SELECT 
    lead_id,
    COUNT(DISTINCT call_reason) AS unique_events
FROM leads_interaction_details
GROUP BY lead_id;

# 4. Summary
SELECT
    lead_id,
    COUNT(*) AS total_interactions,
    COUNT(DISTINCT call_reason) AS unique_events,
    MIN(call_done_date) AS first_interaction,
    MAX(call_done_date) AS last_interaction
FROM leads_interaction_details
GROUP BY lead_id;

SELECT DISTINCT call_status #check distinct
FROM leads_interaction_details;

SELECT TRIM(call_reason) AS call_reason #remove unknown spacing
FROM leads_interaction_details;

--------------------------------------
# leads_reasons_for_no_interest table
--------------------------------------
SELECT * FROM leads_reasons_for_no_interest;
DESCRIBE leads_reasons_for_no_interest;
SELECT * FROM leads_reasons_for_no_interest #check nulls
WHERE lead_id IS NULL OR lead_id = '';
SELECT * FROM leads_reasons_for_no_interest
WHERE (reasons_for_not_interested_in_demo IS NULL OR reasons_for_not_interested_in_demo = '')
AND (reasons_for_not_interested_to_consider IS NULL OR reasons_for_not_interested_to_consider = '')
AND (reasons_for_not_interested_to_convert IS NULL OR reasons_for_not_interested_to_convert = '');

SELECT * FROM leads_reasons_for_no_interest
WHERE reasons_for_not_interested_in_demo = ''
OR reasons_for_not_interested_to_consider = ''
OR reasons_for_not_interested_to_convert = '';

# Replace "" to nulls
SELECT 
    CASE 
        WHEN TRIM(LOWER(reasons_for_not_interested_in_demo)) IN ('', 'none') THEN NULL
        ELSE reasons_for_not_interested_in_demo
    END AS reasons_for_not_interested_in_demo_clean,

    CASE 
        WHEN TRIM(LOWER(reasons_for_not_interested_to_consider)) IN ('', 'none') THEN NULL
        ELSE reasons_for_not_interested_to_consider
    END AS reasons_for_not_interested_to_consider_clean,

    CASE 
        WHEN TRIM(LOWER(reasons_for_not_interested_to_convert)) IN ('', 'none') THEN NULL
        ELSE reasons_for_not_interested_to_convert
    END AS reasons_for_not_interested_to_convert_clean
FROM leads_reasons_for_no_interest;

# Replace "" to nulls
UPDATE leads_reasons_for_no_interest
SET 
    reasons_for_not_interested_in_demo = CASE 
        WHEN TRIM(LOWER(reasons_for_not_interested_in_demo)) IN ('', 'none') THEN NULL
        ELSE reasons_for_not_interested_in_demo
    END,

    reasons_for_not_interested_to_consider = CASE 
        WHEN TRIM(LOWER(reasons_for_not_interested_to_consider)) IN ('', 'none') THEN NULL
        ELSE reasons_for_not_interested_to_consider
    END,

    reasons_for_not_interested_to_convert = CASE 
        WHEN TRIM(LOWER(reasons_for_not_interested_to_convert)) IN ('', 'none') THEN NULL
        ELSE reasons_for_not_interested_to_convert
    END;

SELECT lead_id, COUNT(*) #check duplicates
FROM leads_reasons_for_no_interest
GROUP BY lead_id
HAVING COUNT(*) > 1;

WITH duplicate_cte AS #check duplicates by window function
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY lead_id, reasons_for_not_interested_in_demo, reasons_for_not_interested_to_consider, reasons_for_not_interested_to_convert)
AS row_num
FROM leads_reasons_for_no_interest
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

SELECT DISTINCT reasons_for_not_interested_in_demo #check distinct
FROM leads_reasons_for_no_interest;
UPDATE leads_reasons_for_no_interest #update row value
SET reasons_for_not_interested_in_demo = "Can't afford"
WHERE reasons_for_not_interested_in_demo LIKE 'Cannot afford';

SELECT TRIM(reasons_for_not_interested_to_convert) AS reasons_for_not_interested_to_convert #remove unknown spacing
FROM leads_reasons_for_no_interest;

----------------------------------------------
# sales_managers_assigned_leads_details table
----------------------------------------------
SELECT * FROM sales_managers_assigned_leads_details;
DESCRIBE sales_managers_assigned_leads_details;
SELECT * FROM sales_managers_assigned_leads_details #check nulls
WHERE snr_sm_id IS NULL OR snr_sm_id = ''
OR jnr_sm_id IS NULL OR jnr_sm_id = ''
OR assigned_date IS NULL
OR cycle IS NULL OR cycle = ''
OR lead_id IS NULL OR lead_id = '';

SET SQL_SAFE_UPDATES = 0; #convert data types
UPDATE sales_managers_assigned_leads_details
SET assigned_date = STR_TO_DATE(assigned_date, '%m/%d/%Y');
ALTER TABLE sales_managers_assigned_leads_details
MODIFY assigned_date DATE;

SELECT lead_id, COUNT(*) #check duplicates
FROM sales_managers_assigned_leads_details
GROUP BY lead_id
HAVING COUNT(*) > 1;

WITH duplicate_cte AS #check duplicates by window function
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY snr_sm_id, jnr_sm_id, assigned_date, cycle, lead_id)
AS row_num
FROM sales_managers_assigned_leads_details
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

SELECT TRIM(lead_id) AS lead_id #remove unknown spacing
FROM sales_managers_assigned_leads_details;

# --------------------------------------------------------------------------------------------------------------------------------------
# DATA WRANGLING
# --------------------------------------------------------------------------------------------------------------------------------------

SELECT * FROM leads_basic_details; 
SELECT * FROM leads_demo_watched_details; 
SELECT * FROM leads_interaction_details; 
SELECT * FROM leads_reasons_for_no_interest; 
SELECT * FROM sales_managers_assigned_leads_details; 

SELECT lead_stage 
FROM leads_interaction_details;

CREATE TABLE leads_joined AS
SELECT 
	bas.lead_id,
    bas.age,
    bas.gender,
    bas.current_city,
    bas.current_education,
    bas.parent_occupation,
    bas.lead_gen_source,
    dem.demo_watched_date,
    dem.language,
    dem.watched_percentage,
    dem.watched_category,
    itr.lead_stage,
    itr.call_done_date,
    itr.call_status,
    itr.call_reason,
    res.reasons_for_not_interested_in_demo,
    res.reasons_for_not_interested_to_consider,
    res.reasons_for_not_interested_to_convert,
    sam.snr_sm_id,
    sam.jnr_sm_id,
    sam.assigned_date,
    sam.cycle
FROM leads_basic_details AS bas
LEFT OUTER JOIN leads_demo_watched_details AS dem
	ON bas.lead_id = dem.lead_id
LEFT OUTER JOIN leads_interaction_details AS itr
	ON bas.lead_id = itr.lead_id
LEFT OUTER JOIN leads_reasons_for_no_interest AS res
	ON bas.lead_id = res.lead_id
LEFT OUTER JOIN sales_managers_assigned_leads_details AS sam
	ON bas.lead_id = sam.lead_id
;

SELECT * FROM leads_joined;