use onlineedudb;
select * from students;
select * from enrollments;
select * from payments;
select * from assessments;
select * from courses;

-- Window Function Challenge – Longest Improvement Streak
-- 🎯 Task
-- For each student in each course:

-- 1️⃣ Compare each score with the previous attempt
-- 2️⃣ Identify whether the score improved (score > previous_score)
-- 3️⃣ Calculate the longest consecutive improvement streak
-- 4️⃣ Return only students whose longest streak ≥ 3

with base as (
select student_id, course_id, date_taken, score,
lag(score) over (partition by student_id,course_id order by date_taken) as prev_score
 from assessments
 where score is not null),
 flagged  as
 (
	select *,
	case 
	when prev_score is not null and score > prev_score then 1 else 0 
	end as is_improved
	from base
),
grouped as (
 select * ,
 sum(case when is_improved =0 then 1 else 0 end) over
 (partition by student_id,course_id order by date_taken) as grp
 from flagged),
 streaks as (
    SELECT 
        student_id,
        course_id,
        grp,
        COUNT(*) AS streak_length
    FROM grouped
    WHERE is_improved = 1
    GROUP BY student_id, course_id, grp)
SELECT 
    student_id,
    course_id,
    MAX(streak_length) AS longest_streak
FROM streaks
GROUP BY student_id, course_id
HAVING MAX(streak_length) >= 1;


#--------------------------------
 
 with base as (
select student_id, course_id, date_taken, score,
lag(score) over (partition by student_id,course_id order by date_taken) as prev_score
 from assessments
 where score is not null),
 flagged  as
 (
	select *,
	case 
	when prev_score is not null and score > prev_score then 1 else 0 
	end as is_improved
	from base
),
grouped as (
 select * ,
 sum(case when is_improved =0 then 1 else 0 end) over
 (partition by student_id,course_id order by date_taken) as grp
 from flagged)
 SELECT 
        student_id,
        course_id,
        grp,
        COUNT(*) AS streak_length
    FROM grouped
    WHERE is_improved = 1
    GROUP BY student_id, course_id, grp;
 
 #----------------------------------------------------------------------
 
--  Stored Procedure Challenge — Course Drop With Conditional Refund
-- 📌 Scenario
-- te a stored procedure:
-- 🧠 Business Rules
-- 1️⃣ Student must exist
-- 2️⃣ Course must exist
-- 3️⃣ Student must be enrolled
-- 4️⃣ Enrollment must NOT already be dropped or completed
-- 💰 Refund Policy

-- Calculate:total_paid = SUM(amount_paid > 0)
-- Then:
-- Case 1:
-- If total_paid = 0
-- → No refund
-- → Just mark dropped

-- Case 2:
-- If total_paid > 0 AND
-- student has taken less than 2 assessments
-- → 100% refund
-- Case 3:
-- If total_paid > 0 AND
-- student has taken 2 or more assessments
-- → 50% refund

-- ⚙️ Transaction Logic
-- Inside transaction:
-- 1️⃣ Insert negative refund record into payments
-- 2️⃣ Update enrollment → status = 'dropped'
-- 3️⃣ Commit
-- If ANY error → Rollback

delimiter //
create procedure refund_policy(in student_id_input int, in course_id_input int, out total_assessments int, 
out total_paid decimal(10,2), out refund_amt decimal(10,2), out v_status varchar(50))
begin

declare exit handler for sqlexception
begin
rollback;
signal sqlstate '45000'
set message_text ='refund failed';
end;

if not exists (select 1 from students
where student_id = student_id_input) then 
	signal sqlstate '45000'
    set message_text ='student does not exists';
end if;

if not exists (select 1 from courses
where course_id = course_id_input) then
	signal sqlstate '45000'
    set message_text ='course does not exists';
end if;

if not exists(select 1 from enrollments 
where student_id = student_id_input and course_id = course_id_input) then 
	signal sqlstate '45000'
    set message_text ='student not enrolled';
end if;

select status into v_status from enrollments
where student_id = student_id_input and course_id = course_id_input;

if v_status in ('dropped', 'completed') then 
	signal sqlstate '45000'
    set message_text ='student enroll status should not be dropped or completed';
end if;

select count(*) into total_assessments from assessments
where student_id = student_id_input and course_id = course_id_input and score is not null;

select 
coalesce(sum(amount_paid),0) into total_paid
from payments
where student_id = student_id_input and course_id = course_id_input and amount_paid > 0;

if exists (select 1 from payments 
where student_id = student_id_input and course_id = course_id_input and amount_paid <0) then 
	signal sqlstate '45000'
    set message_text ='refund already issued';
end if;

set refund_amt = -1*total_paid;
start transaction;
if total_paid =0 then 
set refund_amt =0;
end if;

if total_paid >0 and total_assessments < 2 then 
insert into payments (student_id, course_id, amount_paid, payment_date) values
(student_id_input, course_id_input, refund_amt, curdate());
end if;

if total_paid >0 and total_assessments >= 2 then 
insert into payments (student_id, course_id, amount_paid, payment_date) values
(student_id_input, course_id_input, refund_amt/2, curdate());
end if;

update enrollments set status ='dropped'
where student_id = student_id_input and course_id = course_id_input ;
set v_status ='dropped';

commit;
end//
delimiter ;
 
 
set @total_assessments = 0;
set @total_paid = 0;
set @refund_amt = 0;
set @v_status = '';
call refund_policy(1, 1002, @total_assessments, @total_paid, @refund_amt, @v_status);

SELECT @total_assessments AS total_assessments,
       @total_paid        AS total_paid,
       @refund_amt        AS refund_amt,
       @v_status          AS v_status;
       
#-------------------------------------------------------------------------

-- Stored Procedure Challenge — Student Engagement Report
-- 🎯 Goal
-- Create a procedure that returns a summary for one student across all courses.
-- ✅ Inputs
-- student_id_input INT
-- ✅ Outputs
-- total_courses INT (distinct courses enrolled)
-- completed_courses INT
-- inprogress_courses INT
-- dropped_courses INT
-- avg_score DECIMAL(10,2) (only non-NULL scores)
-- total_paid DECIMAL(10,2) (only non-NULL payments)
-- engagement_label VARCHAR(30)
-- 🧠 Label Rules (CASE)
-- Condition	engagement_label
-- total_courses = 0	'NO_ENROLLMENTS'
-- completed_courses >= 2 AND avg_score >= 70	'HIGH_ENGAGEMENT'
-- dropped_courses >= 2	'HIGH_DROP_RISK'
-- avg_score < 60	'LOW_PERFORMANCE'
-- else	'NORMAL'

delimiter //
create procedure student_report(in student_id_input int,out total_courses int, out comp int, out in_prog int, out inprog int, 
out dropp int, 
out avg_score decimal(10,2), out total_paid decimal(10,2) ,out label varchar(50))
begin

if not exists (Select 1 from students
where student_id = student_id_input) then 
	signal sqlstate '45000'
    set message_text = 'student does not exists';
end if;

select count(distinct e.course_id) ,
count(distinct case when e.status ='completed' then 1 end ) ,
count(distinct case when e.status ='in-progress' then 1 end ),
count(distinct case when e.status ='inprogress' then 1 end ),
count(distinct case when e.status ='dropped' then 1 end ),
avg(case when a.score is not null then a.score end) ,
coalesce(sum(amount_paid),0),
case
	when count(distinct e.course_id) =0 then 'no enrollments'
	when count(distinct case when e.status ='completed' then 1 end ) >=2 and avg(a.score) >= 70 then 'high engagement'
	when count(distinct case when e.status ='dropped' then 1 end ) >=2 then 'high risk'
	when avg(a.score)<60 then 'low performance'
    else 'normal'
    end as label
    into total_courses, comp, in_prog, inprog, dropp, avg_score, total_paid, label
 from enrollments as e
left join assessments as a on e.student_id = a.student_id and e.course_id = a.course_id
left join payments as p on e.student_id = p.student_id and e.course_id = p.course_id
where e.student_id = student_id_input;
end//
delimiter ;
 
 drop procedure if exists student_report;
 
 set @total_courses=0;
 set @comp =0;
 set @in_prog=0;
 set @inprog=0;
 set @dropp =0;
 set @avg_score =0.0;
 set @total_paid =0.0;
 set @label ='';
 call student_report(1,@total_courses, @comp,@in_prog,@inprog,@dropp,@avg_score,@total_paid,@label);
 select @total_courses, @comp,@in_prog,@inprog,@dropp,@avg_score,@total_paid,@label;
 
 select * from enrollments where student_id =1;
 
 
 
 
 
 
 
 
 