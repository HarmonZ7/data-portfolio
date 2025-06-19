# Museum & Artist SQL Analysis

**Tools:** PostgreSQL, Tableau  
**Category:** Relational Database Design + Visualization

## Overview

In this project, I wrote 3 SQL queries to explore a database of museums, paintings, and artists. I created derived tables and visualized the data into a storyboard using Tableau to identify patterns in artwork distribution, artist representation, and subject and style content of the artwork.

## What I Did

- Created 3 normalized SQL tables: `subject and style`, `artists`, and `museums`
- Used joins, aggregations, CTE's, window functions, and subqueries to build insights
- Visualized artwork, artist, and museum data by country, subject, style, frequency, etc

## Tableau Public Storyboard

Listed is the finished storyboard published to tableau public:
https://public.tableau.com/views/MuseumAnalysis_17503635414280/MuseumAnalysis?:language=en-US&publish=yes&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link

## SQL Queries Used

<pre>
This query collects museum data using multiple CTE's and calculations from 2 separate tables.
    
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


This query gathers all the data for the artists, as well as calculates how many museums are featuring the works of each artists.
    
    select
        a.full_name as artist_name,
        a.artist_id as artist_id,
        count(distinct w.museum_id) as num_museums_featuring_works
    from artist a
    inner join work w on a.artist_id = w.artist_id
    group by a.artist_id, a.full_name
    order by num_museums_featuring_works desc


This query uses CTE's and window functions to gather calculated data regarding the subject and styles of each painting.
    
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
</pre>

## Files

- `museum_queries.sql` — SQL queries used to extract and process data
- `museum_analysis.twbx` — Tableau visual analysis

---
