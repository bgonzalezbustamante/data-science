/* downloads by product type backfill query*/

WITH daily_format AS (SELECT *, json_object_keys(date::json) AS download_date, json_each_text(date::json) AS daily_downloads
						FROM osf_pagecounter
						WHERE action = 'download'
						LIMIT 100),
	 daily_downloads AS (SELECT daily_format.id, file_id, resource_id,TO_DATE(download_date, 'YYYY/MM/DD') AS download_date, 
								(SELECT regexp_matches(daily_downloads::text, '\{""total"": ([0-9]*)'))[1] AS total,
								target_content_type_id, target_object_id
							FROM daily_format
							LEFT JOIN osf_basefilenode
							ON daily_format.file_id = osf_basefilenode.id),
 	monthly_pp_downloads AS (SELECT COUNT(total) AS downloads, date_trunc('month', download_date) AS trunc_date
							FROM daily_downloads
							WHERE target_content_type_id = 47
							GROUP BY date_trunc('month', download_date))


/* downloads by product type per quater */

SELECT *
	FROM osf_pagecounter
	WHERE modified >= date_trunc('month', current_date - interval '3' month) AND
			action = 'download'

