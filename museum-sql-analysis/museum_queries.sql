--museum info query
with 
	museum_info as (
		select 
			m.name as museum_name,
			m.museum_id as museum_id,
			m.country as museum_country,
			w.artist_id as artist_id
			
		from museum m
		inner join work w on m.museum_id = w.museum_id		
		),
		
	total_paintings as (
		select 
			count(*) as total_num_works,
			w.museum_id as museum_id
		from work w
		group by 2
		),

	works_info as (
		select 
			coalesce(w.style, 'No Info') as work_style,
			w.museum_id as museum_id,
			count(*) as num_per_style
		from work w
		group by w.museum_id, w.style
		)


select distinct
	museum_name,
	mi.museum_id,
	total_num_works,
	work_style,
	num_per_style,
	round(100.0 * num_per_style/total_num_works, 2) as percent_of_total

from museum_info mi
inner join total_paintings tp on mi.museum_id = tp.museum_id
inner join works_info wi on tp.museum_id = wi.museum_id
order by museum_id, num_per_style desc


--artist query
select
	a.full_name as artist_name,
	a.artist_id as artist_id,
	count(distinct w.museum_id) as num_museums_featuring_works
from artist a
inner join work w on a.artist_id = w.artist_id
group by a.artist_id, a.full_name
order by num_museums_featuring_works desc


--subject and style query
with
	subject_counts as (
		select
			s.subject as subject,
			w.style as style,
			count(*) as num_subject_per_style
		 from work w
		 inner join subject s on w.work_id = s.work_id
		 where subject is not null
		 group by s.subject, w.style
			),

	style_counts as (
		select
			count(w.work_id) as total_per_style,
			w.style as style
		from work w
		group by w.style
			),

	ranking_subject as (
		select 
			suc.style,
			suc.subject,
			total_per_style,
			num_subject_per_style,
			row_number() over(partition by suc.style order by num_subject_per_style desc ) as rn
		from subject_counts suc
		inner join style_counts stc on suc.style = stc.style
			)

select
	coalesce(rs.style, 'No Info'),
	rs.total_per_style,
	rs.subject,
	rs.num_subject_per_style,
	round(100.0 * num_subject_per_style/total_per_style, 2) as percent_of_style_total
from ranking_subject rs
where rn = 1
order by style