USE `lead_analysis`;
SELECT * FROM leads_basic_details; 
SELECT * FROM leads_demo_watched_details; 
SELECT * FROM leads_interaction_details; 
SELECT * FROM leads_reasons_for_no_interest; 
SELECT * FROM sales_managers_assigned_leads_details; 

SELECT *
FROM leads_interaction_details
WHERE lead_stage = "conversion";

# Data Cleaning
SELECT * FROM leads_basic_details; 
# ALTER TABLE leads_basic_details
# MODIFY lead_id VARCHAR(50) NOT NULL; 
# ALTER TABLE leads_basic_details
# ADD PRIMARY KEY (lead_id);
DESCRIBE leads_basic_details;
SELECT * FROM leads_basic_details #cek nulls
WHERE lead_id IS NULL 
   OR age IS NULL OR age = ''
   OR gender IS NULL OR gender = ''
   OR current_city IS NULL OR current_city = ''
   OR current_education IS NULL OR current_education = ''
   OR parent_occupation IS NULL OR parent_occupation = ''
   OR lead_gen_source IS NULL OR lead_gen_source = '';
   
SELECT lead_id, COUNT(*) #cek duplikasi
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

WITH duplicate_cte AS #cek duplikasi by window
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

SELECT DISTINCT lead_gen_source #cek isi row unik
FROM leads_basic_details;
SELECT TRIM(lead_id) AS lead_id #hilangkan spasi tidak terlihat
FROM leads_basic_details;

# --------------------------------------------------------------------------------------------------------------------------------------

SELECT * FROM leads_demo_watched_details;
# ALTER TABLE leads_demo_watched_details #buat kolom baru
# ADD COLUMN demo_id INT AUTO_INCREMENT PRIMARY KEY;
DESCRIBE leads_demo_watched_details;
SELECT * FROM leads_demo_watched_details #cek nulls
WHERE lead_id IS NULL OR lead_id = ''
OR demo_watched_date IS NULL
OR language IS NULL OR language = ''
OR watched_percentage IS NULL
OR watched_category IS NULL;

SET SQL_SAFE_UPDATES = 0; #ubah tipe data DATE
UPDATE leads_demo_watched_details
SET demo_watched_date = STR_TO_DATE(demo_watched_date, '%m/%d/%Y');
ALTER TABLE leads_demo_watched_details
MODIFY demo_watched_date DATE;

ALTER TABLE leads_demo_watched_details
MODIFY watched_percentage DECIMAL(5,2);
UPDATE leads_demo_watched_details #ubah tipe data DESIMAL
SET watched_percentage = ROUND(watched_percentage / 100, 2);

SELECT lead_id, COUNT(*) #cek duplikasi
FROM leads_demo_watched_details
GROUP BY lead_id
HAVING COUNT(*) > 1;

WITH duplicate_cte AS #cek duplikasi by window
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

SELECT DISTINCT language #cek isi row unik
FROM leads_demo_watched_details;

ALTER TABLE leads_demo_watched_details ADD watched_category TEXT;

UPDATE leads_demo_watched_details
SET watched_category = 
    CASE 
        WHEN watched_percentage >= 0.8 THEN 'High'
        WHEN watched_percentage >= 0.5 THEN 'Medium'
        ELSE 'Low'
    END;
    
    SELECT TRIM(watched_category) AS watched_category #hilangkan spasi tidak terlihat
FROM leads_demo_watched_details;
    
# --------------------------------------------------------------------------------------------------------------------------------------

SELECT * FROM leads_interaction_details;
DESCRIBE leads_interaction_details;
SELECT * FROM leads_interaction_details #cek nulls
WHERE jnr_sm_id IS NULL OR jnr_sm_id = ''
OR lead_id IS NULL OR lead_id = ''
OR lead_stage IS NULL OR lead_stage = ''
OR call_done_date IS NULL
OR call_status IS NULL OR call_status = ''
OR call_reason IS NULL OR call_reason = '';

SET SQL_SAFE_UPDATES = 0; #ubah tipe data DATE
UPDATE leads_interaction_details
SET call_done_date = STR_TO_DATE(call_done_date, '%m/%d/%Y');
ALTER TABLE leads_interaction_details
MODIFY call_done_date DATE;

SELECT lead_id, COUNT(*) #cek duplikasi by PK
FROM leads_interaction_details
GROUP BY lead_id
HAVING COUNT(*) > 1;

WITH duplicate_cte AS #cek duplikasi by window
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

# 1. Hitung jumlah interaksi per lead
SELECT 
    lead_id,
    COUNT(*) AS total_interactions
FROM leads_interaction_details
GROUP BY lead_id;

# 2. Ambil interaksi pertama dan terakhir
SELECT 
    lead_id,
    MIN(call_done_date) AS first_interaction,
    MAX(call_done_date) AS last_interaction
FROM leads_interaction_details
GROUP BY lead_id;

# 3. Hitung variasi event unik per lead
SELECT 
    lead_id,
    COUNT(DISTINCT call_reason) AS unique_events
FROM leads_interaction_details
GROUP BY lead_id;

# 4. Summary lengkap
SELECT
    lead_id,
    COUNT(*) AS total_interactions,
    COUNT(DISTINCT call_reason) AS unique_events,
    MIN(call_done_date) AS first_interaction,
    MAX(call_done_date) AS last_interaction
FROM leads_interaction_details
GROUP BY lead_id;

SELECT DISTINCT call_status #cek isi row unik
FROM leads_interaction_details;

SELECT TRIM(call_reason) AS call_reason #hilangkan spasi tidak terlihat jnr_sm_id lead_stage call_done_date call_status call_reason
FROM leads_interaction_details;

# --------------------------------------------------------------------------------------------------------------------------------------

SELECT * FROM leads_reasons_for_no_interest;
# ALTER TABLE leads_reasons_for_no_interest #buat kolom baru
# ADD COLUMN reasons_id INT AUTO_INCREMENT PRIMARY KEY;
DESCRIBE leads_reasons_for_no_interest;
SELECT * FROM leads_reasons_for_no_interest #cek nulls
WHERE lead_id IS NULL OR lead_id = '';
SELECT * FROM leads_reasons_for_no_interest
WHERE (reasons_for_not_interested_in_demo IS NULL OR reasons_for_not_interested_in_demo = '')
AND (reasons_for_not_interested_to_consider IS NULL OR reasons_for_not_interested_to_consider = '')
AND (reasons_for_not_interested_to_convert IS NULL OR reasons_for_not_interested_to_convert = '');

SELECT * FROM leads_reasons_for_no_interest
WHERE reasons_for_not_interested_in_demo = ''
OR reasons_for_not_interested_to_consider = ''
OR reasons_for_not_interested_to_convert = '';

# Hapus "" jadi null - cek
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

# Hapus "" jadi null - hapus dan replace jadi null
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

SELECT lead_id, COUNT(*) #cek duplikasi
FROM leads_reasons_for_no_interest
GROUP BY lead_id
HAVING COUNT(*) > 1;

WITH duplicate_cte AS #cek duplikasi by window
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

SELECT DISTINCT reasons_for_not_interested_in_demo #cek isi row unik
FROM leads_reasons_for_no_interest;
UPDATE leads_reasons_for_no_interest #menyeragamkan isi row
SET reasons_for_not_interested_in_demo = "Can't afford"
WHERE reasons_for_not_interested_in_demo LIKE 'Cannot afford';

SELECT TRIM(reasons_for_not_interested_to_convert) AS reasons_for_not_interested_to_convert #hilangkan spasi tidak terlihat reasons_for_not_interested_in_demo reasons_for_not_interested_to_consider reasons_for_not_interested_to_convert
FROM leads_reasons_for_no_interest;

# --------------------------------------------------------------------------------------------------------------------------------------

SELECT * FROM sales_managers_assigned_leads_details;
# ALTER TABLE sales_managers_assigned_leads_details #buat kolom baru
# ADD COLUMN assigned_id INT AUTO_INCREMENT PRIMARY KEY;
DESCRIBE sales_managers_assigned_leads_details;
SELECT * FROM sales_managers_assigned_leads_details #cek nulls
WHERE snr_sm_id IS NULL OR snr_sm_id = ''
OR jnr_sm_id IS NULL OR jnr_sm_id = ''
OR assigned_date IS NULL
OR cycle IS NULL OR cycle = ''
OR lead_id IS NULL OR lead_id = '';

SET SQL_SAFE_UPDATES = 0; #ubah tipe data DATE
UPDATE sales_managers_assigned_leads_details
SET assigned_date = STR_TO_DATE(assigned_date, '%m/%d/%Y');
ALTER TABLE sales_managers_assigned_leads_details
MODIFY assigned_date DATE;

SELECT lead_id, COUNT(*) #cek duplikasi
FROM sales_managers_assigned_leads_details
GROUP BY lead_id
HAVING COUNT(*) > 1;

WITH duplicate_cte AS #cek duplikasi by window
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

SELECT TRIM(lead_id) AS lead_id #hilangkan spasi tidak terlihat snr_sm_id jnr_sm_id assigned_date cycle lead_id
FROM sales_managers_assigned_leads_details;

# --------------------------------------------------------------------------------------------------------------------------------------
# Data Wrangling
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