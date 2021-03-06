/* User Generation Tag Counting */


/* intital query to get info about users with system tags, dates, and SSO */
WITH user_tag_info AS (SELECT osf_osfuser.id AS user_id, username, is_registered, is_invited, date_registered, date_confirmed, date_disabled, is_active, deleted, spam_status, osf_tag.name, institution_id
						FROM osf_osfuser
						LEFT JOIN osf_osfuser_tags
						ON osf_osfuser.id = osf_osfuser_tags.osfuser_id
						LEFT JOIN osf_tag
						ON osf_osfuser_tags.tag_id = osf_tag.id
						LEFT JOIN osf_osfuser_affiliated_institutions
						ON osf_osfuser.id = osf_osfuser_affiliated_institutions.osfuser_id
						WHERE osf_tag.system IS TRUE AND 
							(osf_tag.name NOT LIKE '%spam' AND osf_tag.name != 'high_upload_limit' AND osf_tag.name != 'ham_confirmed' AND osf_tag.name NOT LIKE '%metrics' AND osf_tag.name != 'prereg_admin')),
	 new_signups AS (SELECT COUNT(user_id) AS new_signups, 
	 						COUNT(CASE WHEN institution_id IS NOT NULL THEN 1 END) AS sso_newsignups, 
	 						date_trunc('month', date_confirmed) as month, name
						FROM user_tag_info
						WHERE is_registered IS TRUE AND is_invited IS FALSE AND 
								date_confirmed >= date_trunc('month', current_date - interval '3' month)
						GROUP BY name, date_trunc('month', date_confirmed)),
	 new_invites AS (SELECT COUNT(user_id) AS new_sources, name
 						FROM user_tag_info
 						WHERE is_invited IS TRUE
 						GROUP BY name),
  	 new_claims AS (SELECT COUNT(user_id) AS new_claims,
	 					   COUNT(CASE WHEN institution_id IS NOT NULL THEN 1 END) AS sso_newclaims, 
	 					   date_trunc('month', date_confirmed) as month, name
	 				FROM user_tag_info
	 				WHERE is_invited IS TRUE AND date_confirmed IS NOT NULL AND
	 						date_confirmed >= date_trunc('month', current_date - interval '3' month)
	 				GROUP BY name, date_trunc('month', date_confirmed))

SELECT new_signups, new_claims, new_sources, sso_newsignups, sso_newclaims, new_signups.name, new_signups.month
	FROM new_signups
	LEFT JOIN new_claims
	ON new_signups.name = new_claims.name AND new_signups.month = new_claims.month
	LEFT JOIN new_invites
	ON new_signups.name = new_invites.name;
	

