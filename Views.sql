use onlineedudb;
select * from students;
select * from enrollments;
select * from payments;
select * from assessments;
select * from courses;


-- A view is just a saved SELECT query

-- Feature	                   View	                      Stored Procedure
-- Type					Saved query	                       Program
-- Parameter					❌ No	                          ✅ Yes
-- Logic (IF, CASE)	      ❌ No	                            ✅ Yes
-- Insert/Update/Delete	 ❌ Mostly no	                ✅ Yes
-- Usage	               Like table	                    Called using CALL

-- A view is like a saved SQL query.
-- You write a query once, give it a name, and then use it like a table.

-- 2. Why use Views?
-- Views help when:
-- your query is long
-- you use same join again and again
-- you want clean reporting tables
-- you want to hide complex logic

-- Example: instead of writing joins every time, create a view once.

-- 🔥 Without View (repeating joins again and again)

-- Suppose you want:

-- student_id | student_name | course_title | score

-- You will write this EVERY time:

SELECT 
    s.student_id,
    s.name,
    c.title,
    a.score
FROM students s
JOIN enrollments e 
    ON s.student_id = e.student_id
JOIN courses c 
    ON e.course_id = c.course_id
LEFT JOIN assessments a 
    ON e.student_id = a.student_id 
   AND e.course_id = a.course_id;

-- 👉 This is long
-- 👉 You will repeat it again and again ❌

-- 🚀 With View (clean way)
-- Step 1: Create view once
CREATE VIEW vw_student_course_details AS
SELECT 
    s.student_id,
    s.name,
    c.title AS course_title,
    a.score
FROM students s
JOIN enrollments e 
    ON s.student_id = e.student_id
JOIN courses c 
    ON e.course_id = c.course_id
LEFT JOIN assessments a 
    ON e.student_id = a.student_id 
   AND e.course_id = a.course_id;
   
-- Step 2: Use it like a table
SELECT * 
FROM vw_student_course_details;

-- Step 3: Apply filters easily
SELECT *
FROM vw_student_course_details
WHERE score >= 80;

-- 👉 Without view:

-- Write long join query every time 😓

-- 👉 With view:

-- Write once → reuse forever 😎

#-----------------------------------------------------------------
-- Create a View: Course Details with Instructor
-- Create:
-- vw_course_instructor
-- 📊 Output:
-- course_id | title | category | price | instructor_name
select * from instructors;
select * from courses;

create view vw_course_instructor as
Select 
c.course_id, c.title,
 c.category, c.price, 
 i.name
 from courses as c
left join instructors as i on i.instructor_id = c.instructor_id;

select * from vw_course_instructor
where price > 160;

#--------------------------------------------------------------
-- Create a View: Payment Status
-- Create: vw_payment_status
-- 📊 Output:
-- student_id | course_id | amount_paid | price | payment_status

create view vw_payment_status as 
select s.student_id, c.course_id, p.amount_paid, c.price,
case
	when p.amount_paid is null then "pending"
    when p.amount_paid < c.price then "partial"
    when p.amount_paid >= c.price then  "completed"
    end as payment_status from students as s
left join payments as p on s.student_id = p.student_id
left join courses as c on p.course_id = c.course_id;

select * from vw_payment_status;

drop view vw_payment_status;

select s.student_id, c.course_id, sum(p.amount_paid) ,c.price ,
case
	when sum(p.amount_paid) is null then "pending"
    when sum(p.amount_paid) < c.price then "partial"
    when sum(p.amount_paid) >= c.price then  "completed"
    end as payment_status
from students as s
left join payments as p on s.student_id = p.student_id
left join courses as c on p.course_id = c.course_id
group by s.student_id, c.course_id;

#----------------------------------------

#nested View

create view  vw_total_courses as
select student_id, count(course_id) as total_courses
 from enrollments
group by student_id;

create view vw_active_courses as
select * from vw_total_courses
where total_courses >2;

select * from vw_active_courses;

#--------------------------------------------------
create view vw_high_value_students as
select student_id, sum(amount_paid) as total_paid from payments 
group by student_id
having sum(amount_paid) > 300;

drop view vw_high_value_students ;
select * from vw_high_value_students;

create view vw_student_value_tag as 
select *,
case
	when total_paid >=400 then "premium"
    when total_paid >= 200 then "gold"
    else "regular"
    end as stud_pay_stats
from vw_high_value_students;

drop view vw_student_value_tag;

select * from vw_student_value_tag;

#-------------------------------------------------------------
-- vw_student_course_performance
-- The view should show one row for each enrolled student-course combination.
-- Expected columns
-- student_id,student_name,city,course_id,course_title,course_category,instructor_name,enrollment_status
-- score,amount_paid,course_price,payment_status,result_status,overall_status
select * from courses;
create view vw_student_course_performance as
select s.student_id, s.name as student_name ,
s.city, 
c.course_id, c.title,c.category,
i.name as instructor_name, e.status, a.score, p.amount_paid, c.price,
case 
	when p.amount_paid IS NULL then 'Payment Pending'
	when p.amount_paid >= c.price  then 'Paid'
	when p.amount_paid < c.price  then 'Partial Payment'
	end as payment_status,
case
	when a.score IS NULL then 'Assessment Pending'
	when a.score >= 60  then 'Pass'
	when a.score < 60  then 'Fail'
	end as result_status,
case 
	when e.status = 'completed' AND a.score >= 60 AND p.amount_paid >= price then  'Completed Successfully'
	when e.status = 'completed' AND a.score < 60 then 'Completed but Failed'
	when e.status = 'in-progress' then 'Currently Learning'
	when e.status = 'dropped' then 'Dropped Course'
    when p.amount_paid IS NULL then 'Payment Issue'
    else 'Needs Review'
end as overall_status
 from students as s
left join enrollments as e on s.student_id = e.student_id
left join courses as c on e.course_id = c.course_id
left join instructors as i on i.instructor_id = c.instructor_id
left join payments as p on e.student_id = p.student_id and e.course_id = p.course_id
left join assessments as a on e.student_id = a.student_id and e.course_id = a.course_id;

select * from vw_student_course_performance
where payment_status ="paid" ;

#--------------------------------------------------------
select * from instructors;
select * from courses;

create view vw_course_revenue_summary as (
select c.course_id, c.title,c.price, c.category, i.name,
count(e.student_id) as total_students,
coalesce(sum(p.amount_paid),0) as total_collected_amount,
c.price * count(e.student_id) as total_expected_revenue,
c.price * count(e.student_id) -coalesce(sum(p.amount_paid),0) as pending_amount,
case when coalesce(sum(p.amount_paid),0) = 0
	then 'No Revenue Collected'

when c.price * count(e.student_id) -coalesce(sum(p.amount_paid),0)= 0
    then 'Fully Collected'

when c.price * count(e.student_id) -coalesce(sum(p.amount_paid),0) > 0 AND  
c.price * count(e.student_id) -coalesce(sum(p.amount_paid),0) <= 200
    then 'Small Pending Revenue'

when c.price * count(e.student_id) -coalesce(sum(p.amount_paid),0) > 200
    then 'High Pending Revenue'

when c.price * count(e.student_id) -coalesce(sum(p.amount_paid),0) < 0
    then  'Over Collected' 
    end as revenue_status
    from courses as c 
left join instructors as i on c.instructor_id = i.instructor_id
left join enrollments as e on e.course_id = c.course_id
left join payments as p on e.course_id =p.course_id and e.student_id = p.student_id
group by c.course_id);

drop view vw_course_revenue_summary;

select * from vw_course_revenue_summary;

























