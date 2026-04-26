use onlineedudb;
select * from students;
select * from enrollments;
select * from payments;
select * from assessments;
select * from courses;


👉 -- A view is just a saved SELECT query

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


































