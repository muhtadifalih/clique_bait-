-- CLIQUE BAIT PSET
use clique_bait ;
 
 -- How many users are there?
 select
	count(distinct user_id) as count_users
from users ; -- 500 users
 
 -- How many cookies does each user have on average?
select 
	avg(count_cookies) as avg_cookies
from
(
select
	user_id as users,
	count(cookie_id) as count_cookies
from users 
group by user_id
) 
as count_cookies
; -- 3,56 cookies per user

-- What is the unique number of visits by all users per month?

select * from campaign_ident_cleaned ;
select * from page_h
ierarchy ;
select * from events_cleaned ;
select * from event_identifier ;

select * from users ;

select 
	-- b.user_id,
    min(date(a.event_time)) as mo_start_date,
    count(distinct a.visit_id) as count_visits
from events_cleaned a
left join users b
on a.cookie_id = b.cookie_id
group by month(a.event_time)
;

-- What is the number of events for each event type?

select 
	event_type,
	count(event_type) as count_event
from events_cleaned
group by 1
;


-- What is the percentage of visits which have a purchase event?


create temporary table purchase_visit
select 
	distinct visit_id as purchase_visitid
from events_cleaned 
where event_type =3 
;

select * from purchase_visit ;

select
	count(distinct visit_id) as count_visit_all,
    count(distinct b.purchase_visitid) as count_purchase_visit,
    count(distinct b.purchase_visitid)/ count(distinct visit_id) as ptage_purchase
from events_cleaned a
left join purchase_visit b
on a.visit_id = b.purchase_visitid
;

-- What is the percentage of visits which view the checkout page but do not have a purchase event?
-- find visits with checkout page view

create temporary table checkout_visits
select
	a.visit_id,
    a.event_type,
    a.page_id,
    b.page_name
from events_cleaned a
left join page_hierarchy b
on a.page_id = b.page_id
where a.page_id = 12;

select * from checkout_visits ;

drop temporary table purchase_visits ;

create temporary table purchase_visits
select
	a.visit_id,
    a.event_type,
    a.page_id,
    b.page_name
from events_cleaned a
left join page_hierarchy b
on a.page_id = b.page_id
where a.event_type = 3
;

select * from purchase_visits ;

-- join the table to find checkout without purchasing visits

select
	count(co_visits) as count_checkout,
    count(checkout_wo_purchase) as count_co_wo_purchase,
    count(checkout_wo_purchase) / count(co_visits) as rate
from
(
select
	a.visit_id as co_visits,
    b.visit_id as purchase_visits,
    case when b.visit_id is null then a.visit_id else null end as checkout_wo_purchase
from checkout_visits a
left join purchase_visits b
on a.visit_id = b.visit_id
)
as checkout_purchase
;

-- What are the top 3 pages by number of views?

select * from event_identifier ;
select * from page_hierarchy ;

select 
	a.*,
    b.event_name
from events_cleaned a
left join event_identifier b
on a.event_type = b.event_type
where a.event_type = 4;

select
	a.page_id,
    count(b.page_name) as count_viewed,
    rank() over(order by count(b.page_name) desc) as rnk
from events_cleaned a
left join page_hierarchy b
on a.page_id = b.page_id
-- limit 50 offset 10
where a.event_type = 1
group by a.page_id
;

-- What is the number of views and cart adds for each product category?
-- find number of views

select * from page_hierarchy ;

-- create table events_w_name
select 
	a.*,
    b.event_name
from events_cleaned a
left join event_identifier b
on a.event_type = b.event_type
-- where a.event_type =1
;

-- create temporary table view_products

select
	product_category,
	count(case when event_type = 1 then product_category else null end) as views,
    count(case when event_type = 2 then product_category else null end) as addcart
from 
(
select 
	a.*,
    b.product_category
from events_w_name a
left join page_hierarchy b
on a.page_id = b.page_id
where a.event_type in (1,2) and a.page_id not in (1,2,12,13)
) 
as table_a
group by product_category 
; # answer 1

-- What are the top 3 products by purchases?

-- find visit_id with purchases

select
	page_hierarchy.page_name,
	count(index_num) as count_purchases,
    rank() over(order by count(index_num) desc) as rnk
from
(
with cte 
as
(
select 
	visit_id
from events_w_name -- find visits with purchase events
where event_name = 'Purchase'
)
select
	a.*
from events_w_name a
inner join cte b
on a.visit_id = b.visit_id
where event_name = 'Add to Cart'
)
as add_cart_visits
inner join page_hierarchy 
on add_cart_visits.page_id = page_hierarchy.page_id
group by page_hierarchy.page_name
limit 3
; 