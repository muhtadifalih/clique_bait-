-- PRODUCT FUNNEL ANALYSIS

USE clique_bait ;
/*
Using a single SQL query - create a new output table which has the following details:

How many times was each product viewed?
How many times was each product added to cart?
How many times was each product added to a cart but not purchased (abandoned)?
How many times was each product purchased?
*/

SELECT 
	page_id,
	count(case when event_name = 'Page View' then cookie_id else null end) as count_view,
    count(case when event_name = 'Add to Cart' then cookie_id else null end) as count_cart
from events_w_name
where page_id between 3 and 11 -- filter by products viewed
group by 1
;


-- find cart visits without purchasing

select * from events_w_name limit 100 offset 50 ;

drop temporary table t1 ;

create temporary table t1
select
	distinct visit_id
from events_w_name
where event_name = 'Add to Cart'
;

select * from t1 ;

-- find visits which have purchase events

create temporary table t2 
select 
	visit_id
from events_w_name
where event_name = 'Purchase'
;

-- join to find visits of cart add without purchasing

create temporary table t3
select
	a.visit_id as addcart_visit,
    b.visit_id as purchase_visit,
    case when b.visit_id is null then a.visit_id else null end as cart_wo_purchase

from t1 a
left join t2 b
on a.visit_id= b.visit_id
;

select * from t3 ;

-- find count events of adding to cart without purchasing

create temporary table t4
select
	a.page_id,
	count(a.visit_id) as count_events
    
    -- a.event_name

from events_w_name a
inner join t3 b
on a.visit_id = b.cart_wo_purchase
where a.event_name = 'Add to Cart'
group by 1
;

-- How many times was each product purchased?

create temporary table t5
select 
	-- a.visit_id,
    a.page_id,
	count(b.purchase_visit) AS count_events
    
    -- a.event_name

from events_w_name a
inner join t3 b
on a.visit_id = b.purchase_visit
where event_name in ('Add to Cart','Purchase')
group by 1
;

-- join the table with main table of view and cart events
create temporary table main_table
SELECT 
	page_id,
	count(case when event_name = 'Page View' then cookie_id else null end) as count_view,
    count(case when event_name = 'Add to Cart' then cookie_id else null end) as count_cart
from events_w_name
where page_id between 3 and 11 -- filter by products viewed
group by 1
;

with cte 
as
(
select 
	a.*,
    b.count_events as cart_wo_purchase
from main_table a
inner join t4 b
on a.page_id = b.page_id
)
select
	a.*,
    b.count_events as count_purchased
from cte a 
inner join t5 b
on a.page_id = b.page_id
;


-- Additionally, create another table which further
-- aggregates the data for the above points but this time for each product category instead of individual products.

with cte2
as
(
with cte 
as
(
select 
	a.*,
    b.count_events as cart_wo_purchase
from main_table a
inner join t4 b
on a.page_id = b.page_id
)
select
	a.*,
    b.count_events as count_purchased
from cte a 
inner join t5 b
on a.page_id = b.page_id
)
select
	b.product_category,
    sum(a.count_view) as sum_view,
    sum(a.count_cart) as sum_addcart,
    sum(a.cart_wo_purchase) as sum_cart_wo_purchase,
    sum(a.count_purchased) as sum_purchased
from cte2 a
inner join page_hierarchy b
on a.page_id = b.page_id
group by b.product_category
;

/*
Which product had the highest view to purchase percentage?
What is the average conversion rate from view to cart add?
What is the average conversion rate from cart add to purchase?
*/

-- Which product had the highest view to purchase percentage?

with cte 
as
(
select 
	a.*,
    b.count_events as cart_wo_purchase
from main_table a
inner join t4 b
on a.page_id = b.page_id
)
select
	a.*,
    b.count_events as count_purchased,
    b.count_events / a.count_view as view2purchase_rt,
    rank() over(order by b.count_events / a.count_view desc) as rnk
from cte a 
inner join t5 b
on a.page_id = b.page_id
;

-- What is the average conversion rate from view to cart add?

with cte3
as
(
with cte 
as
(
select 
	a.*,
    b.count_events as cart_wo_purchase
from main_table a
inner join t4 b
on a.page_id = b.page_id
)
select
	a.*,
    b.count_events as count_purchased,
    a.count_cart/a.count_view as rate
from cte a 
inner join t5 b
on a.page_id = b.page_id
)
select
	round(avg(rate),2) as avg_view2cart
from cte3;

-- What is the average conversion rate from cart add to purchase?


with cte4
as
(
with cte 
as
(
select 
	a.*,
    b.count_events as cart_wo_purchase
from main_table a
inner join t4 b
on a.page_id = b.page_id
)
select
	a.*,
    b.count_events as count_purchased,
    b.count_events/a.count_cart as cart2purchase_rt
from cte a 
inner join t5 b
on a.page_id = b.page_id
)
select
	round(avg(cart2purchase_rt),2) as avg_cart2purchase
from cte4
;