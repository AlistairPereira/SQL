use onlineedudb;
select * from students;
select * from enrollments;
select * from payments;
select * from assessments;
select * from courses;

-- Q1. Assessment Result
-- Based on score:
-- = 80 → "Excellent"
-- 60–79 → "Good"
-- <60 → "Poor"
-- NULL → "Not Attempted"

select student_id, course_id, score,
case 
when score is null then "not attempted"
when score <60 then "poor"
when score between 60 and 79 then "good"
else "excellent"
end as score_status
 from assessments;
 
 #----------------------------------------------------------------
-- Q2. Payment Status
-- amount_paid IS NULL → "Pending"
-- amount_paid < course price → "Partial"
-- amount_paid >= price → "Completed"


select * from courses;
select * from payments;

select p.payment_id,c.course_id, c.title,c.price , p.amount_paid,
case
when p.amount_paid is null then "pending"
when p.amount_paid < c.price then "partial"
when p.amount_paid >= c.price then "completed"
end as price_status
 from courses as c
left join payments as p on c.course_id = p.course_id;

#----------------------------------------------------------------------------
-- Write a SQL query to show number of students in each status per course

select course_id, count(student_id),
count(case when status ="dropped" then 1 end) as dropped_courses,
count(case when status ="in-progress" then 1 end) as inprogress_courses,
count(case when status ="completed" then 1 end) as completed_courses,
count(case when status is null then 1 end) as pending_courses
 from enrollments
group by course_id;

#--------------------------------------------------------------------------
-- Q3. Enrollment Recency
-- 👉 Based on enroll_date:
-- Last 30 days → "Recent"
-- 30–90 days → "Moderate"
-- 90 days → "Old"
-- NULL → "Unknown"
select * from students;

select *,
case
when e.enroll_date is null then 'pending'
when datediff(s.join_date, e.enroll_date) <= 30 then "recent"
when datediff(s.join_date, e.enroll_date) between 30 and 90 then "moderate"
else "old"
end as recency_tab
 from enrollments as e 
 join students as s on e.student_id = s.student_id;

select *,
case
when enroll_date is null then 'pending'
when datediff(current_date, enroll_date) <= 30 then "recent"
when datediff(Current_date, enroll_date) between 30 and 90 then "moderate"
else "old"
end as recency_tab
 from enrollments ;
 
-- Write a query to show each student’s overall performance summary
-- 📊 Expected Output
-- student_id | name | total_courses | avg_score | performance_tag
-- 📌 Requirements
-- 1. Total Courses
-- 👉 Count how many courses each student enrolled in
-- 2. Average Score
-- 👉 Average of score from assessments
-- Ignore NULL scores automatically
-- 3. Performance Tag (CASE)
-- Condition	Tag
-- avg_score >= 80	"Excellent"
-- 60–79	"Good"
-- <60	"Poor"
-- NULL avg_score	"No Data"

select * from enrollments;

select s.student_id, s.name, count(e.course_id) as total_courses,
round(avg(a.score),2) as avg_score,
case
when round(avg(a.score),2) is null then "no data"
when round(avg(a.score),2) >= 80 then "excellent"
when round(avg(a.score),2) between 60 and 79 then "good"
else "poor"
end as performance_tag
from students as s 
left join  enrollments as e on s.student_id = e.student_id
left join assessments as a on e.course_id = a.course_id and e.student_id = a.student_id
group by s.student_id,s.name;






