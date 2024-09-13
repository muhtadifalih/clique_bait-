-- CAMPAIGN ANALYSIS

use clique_bait ;

with cte 
as
(
select
	b.user_id,
    a.visit_id,
    min(a.event_time) as visit_start_time,
	count(case when a.event_name = 'Page View' then a.visit_id else null end) as page_views,
    count(case when a.event_name = 'Add to Cart' then a.visit_id else null end) as cart_adds,
    count(distinct case when a.event_name = 'Purchase' then 1 else null end) as purchase,
    -- case when min(a.event_time) between c.start_date and c.end_date then c.campaign_name else null end) as campaign_name
    count(case when a.event_name = 'Ad Impression' then a.visit_id else null end) as impression,
    count(case when a.event_name = 'Ad Click' then a.visit_id  else null end) as click
from events_w_name a
inner join users b
on a.cookie_id = b.cookie_id
group by 2,1
order by 3
)
select
	cte.*,
    test_table.campaign_name
    /*case
		when cte.visit_start_time between '2020-01-01 00:00:00' and '2020-01-14 00:00:00'then 'BOGOF - Fishing For Compliments'
        when cte.visit_start_time between '2020-01-15 00:00:00' and '2020-01-28 00:00:00'then '25% Off - Living The Lux Life'
        when cte.visit_start_time between '2020-02-01 00:00:00' and '2020-03-31 00:00:00'then 'Half Off - Treat Your Shellf(ish)'
        else null
		end as campaign_name*/
from cte
left join 
(
select  
	distinct b.campaign_name,
    b.start_date,
    b.end_date
from page_hierarchy a
inner join campaign_ident_cleaned b
on a.product_id = b.products_cleaned
)
as test_table
on cte.visit_start_time >= test_table.start_date -- joining on between dates
and cte.visit_start_time <= test_table.end_date
;

-- a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the
-- sequence number

with cte as
(
select
	a.visit_id,
    a.page_id,
    a.sequence_number
    -- group_concat(a.page_id) as test
from events_w_name a
where event_name = 'Add to Cart'
-- group by a.visit_id
order by a.event_time
)
select
	visit_id,
    group_concat(page_id) as product_sequence
from cte
group by visit_id
;


-- JOIN INTO MAIN TABLE

WITH cte2 
as
(
with cte 
as
(
select
	b.user_id,
    a.visit_id,
    min(a.event_time) as visit_start_time,
	count(case when a.event_name = 'Page View' then a.visit_id else null end) as page_views,
    count(case when a.event_name = 'Add to Cart' then a.visit_id else null end) as cart_adds,
    count(distinct case when a.event_name = 'Purchase' then 1 else null end) as purchase,
    -- case when min(a.event_time) between c.start_date and c.end_date then c.campaign_name else null end) as campaign_name
    count(case when a.event_name = 'Ad Impression' then a.visit_id else null end) as impression,
    count(case when a.event_name = 'Ad Click' then a.visit_id  else null end) as click
from events_w_name a
inner join users b
on a.cookie_id = b.cookie_id
group by 2,1
order by 3
)
select
	cte.*,
    test_table.campaign_name
from cte
left join 
(
select  
	distinct b.campaign_name,
    b.start_date,
    b.end_date
from page_hierarchy a
inner join campaign_ident_cleaned b
on a.product_id = b.products_cleaned
)
as test_table
on cte.visit_start_time >= test_table.start_date -- joining on between dates
and cte.visit_start_time <= test_table.end_date
)
select
	cte2.*,
    cte3.product_sequence
from cte2 
left join 
(
with cte as
(
select
	a.visit_id,
    a.page_id,
    a.sequence_number
    -- group_concat(a.page_id) as test
from events_w_name a
where event_name = 'Add to Cart'
-- group by a.visit_id
order by a.event_time
)
select
	visit_id,
    group_concat(page_id) as product_sequence
from cte
group by visit_id
) as cte3 
on cte2.visit_id = cte3.visit_id
;


-- QA only

SELECT
	*
from events_w_name
where visit_id = '3324e3';-- only page view, not adding to cart or purchase



