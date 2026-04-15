use onlineedudb;
select * from students;
select * from enrollments;
select * from payments;
select * from assessments;
select * from courses;


-- Q. Get Student Course Summary
-- Create a stored procedure :
-- Requirements:
-- Count total enrolled courses
-- Calculate average assessment score
-- Calculate total payment made
-- Show result only for the given student
select s.student_id, count(e.course_id) , avg(a.score) , sum(p.amount_paid) from students as s
left join enrollments as e on s.student_id = e.student_id
left join assessments as a on e.student_id = a.student_id and e.course_id = a.course_id
left join payments as p on e.student_id = p.student_id and e.course_id = p.course_id
group by s.student_id;

delimiter //
create procedure student_course_summary(in student_id_input int, out total_courses int, out avg_score decimal(10,2),
out total_pay decimal(10,2))
begin
	select 
		count(e.course_id),
		avg(a.score), 
		sum(p.amount_paid)
	into total_courses, avg_score, total_pay from students as s
	left join enrollments as e on s.student_id = e.student_id
	left join assessments as a on e.student_id = a.student_id and e.course_id = a.course_id
	left join payments as p on e.student_id = p.student_id and e.course_id = p.course_id
	where s.student_id = student_id_input;

	select 
		s.student_id, total_courses as tc, avg_score as ascore, total_pay as tp
	from students as s
	left join enrollments as e on s.student_id = e.student_id
	left join assessments as a on e.student_id = a.student_id and e.course_id = a.course_id
	left join payments as p on e.student_id = p.student_id and e.course_id = p.course_id
	where s.student_id = student_id_input;
end//
delimiter ;
drop procedure if exists student_course_summary;

set @total_courses =0;
set @avg_score =0.0;
set @total_pay =0.0;
call student_course_summary(1,@total_courses, @avg_score,@total_pay);
select @total_courses, @avg_score,@total_pay;

#-----------------------------------------------------------------------------
-- Stored Procedure Question 2
-- Q. Get Course Enrollment By Status
-- Output should show:
-- course_id | title | dropped_count | completed_count | in_progress_count | pending_count

delimiter //
create procedure course_enroll_by_status
(in course_id_input int, out dropp int, out comp int, out in_prog int, out pending int)
begin
select 
count(case when status = "dropped" then 1 end),
count(case when status = "completed" then 1 end),
count(case when status = "in-progress" then 1 end),
count(case when status is null then 1 end)
into dropp, comp, in_prog, pending
from enrollments
where course_id = course_id_input;
end//
delimiter ;

set @dropp =0;
set @comp =0;
set @in_prog =0;
set @pending =0;
call course_enroll_by_status(1001, @dropp, @comp,@in_prog,@pending);
select @dropp, @comp,@in_prog,@pending;



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

SELECT @total_assessments,@total_paid ,@refund_amt, @v_status; 

#---------------------------------------------------------------------------------------

-- Transaction Challenge — Course Completion & Certificate Issuance
-- 📌 Scenario

-- When a student completes a course, the system must:

-- ✔ verify completion eligibility
-- ✔ update enrollment
-- ✔ issue certificate
-- ✔ lock further assessments
-- ✔ ensure transaction safety
-- 🧠 Business Rules
-- ✅ Validation Rules
-- 1️⃣ Student must exist
-- 2️⃣ Course must exist
-- 3️⃣ Student must be enrolled
-- 4️⃣ Enrollment status must be in-progress
-- 5️⃣ Course must be fully paid

-- 🎓 Completion Eligibility
-- Student can complete course only if:
-- ✔ at least 2 assessments attempted
-- ✔ latest score ≥ 60

-- ⚙️ Transaction Operations
-- Inside ONE TRANSACTION:
-- 1️⃣ Update enrollment
-- status → 'completed'
-- 2️⃣ Insert certificate record

-- 👉 create a new table:
-- CREATE TABLE Certificates (
--   certificate_id INT AUTO_INCREMENT PRIMARY KEY,
--   student_id INT,
--   course_id INT,
--   issued_date DATE
-- );

-- Insert certificate after completion.
-- 3️⃣ Lock further assessments

-- After completion:
-- ❌ student cannot take more assessments
-- (Prevent future inserts)

-- 👉 enforce by inserting a record in:
-- CREATE TABLE CourseLocks (
--   student_id INT,
--   course_id INT,
--   locked_on DATE
-- );
-- 4️⃣ Commit
-- If ANY error → rollback

CREATE TABLE Certificates (
  certificate_id INT AUTO_INCREMENT PRIMARY KEY,
  student_id INT,
 course_id INT,
 issued_date DATE
);


CREATE TABLE CourseLocks (
 student_id INT,
 course_id INT,
 locked_on DATE
);

delimiter //
create procedure certificate_issue(in student_id_input int, in course_id_input int, out total_paid decimal(10,2),
out total_assessments int, out v_score decimal(10,2), out set_status varchar(50))
begin
declare v_status varchar(50);
declare v_price decimal(10,2);

declare exit handler for sqlexception
begin
rollback;
signal sqlstate '45000'
set message_text ='certifcae issue failed';
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

if not exists (select 1 from enrollments
where student_id = student_id_input and course_id = course_id_input) then 
	signal sqlstate '45000'
    set message_text ='student not enrolled';
end if;

select 
status into v_status 
from enrollments
where student_id = student_id_input and course_id = course_id_input;

if v_status <> 'in-progress'
then signal sqlstate '45000'
	set message_text ='enrollment status is not in-progress';
end if;

select price into v_price
from courses
where course_id = course_id_input;

select 
coalesce(sum(amount_paid),0) into total_paid
from payments
where student_id = student_id_input and course_id = course_id_input and amount_paid >0;

if v_price < total_paid  then 
	signal sqlstate '45000'
    set message_text = 'course price is not fully paid';
end if;

select count(*) into total_assessments 
from assessments
where student_id = student_id_input and course_id = course_id_input and score is not null;

select score
into v_score
from assessments
where student_id = student_id_input and course_id = course_id_input and score is not null
order by date_taken desc
limit 1 ;

if v_score < 60 and total_assessments < 2 then 
	signal sqlstate '45000'
    set message_text ='student cannot complete the course';
end if;

start transaction;
update enrollments set status ='completed' 
where student_id = student_id_input and course_id = course_id_input ;

-- prevent duplicate certificate
if not exists(select 1 from Certificates
where student_id = student_id_input and course_id = course_id_input ) then 
insert into Certificates (student_id, course_id, issued_date) values
(student_id_input, course_id_input, curdate());
end if;

-- lock further assessments
insert into CourseLocks (student_id, course_id, locked_on) values
(student_id_input, course_id_input , curdate());

set set_status ='completed' ;
commit;
end//
delimiter ;

set @total_paid = 0;
set @total_assessments = 0;
set @latest_score = 0;
set @status = '';

call certificate_issue(3,  1006, @total_paid, @total_assessments,@latest_score,@status);
       
SELECT @total_paid as total_paid,
@total_assessments as attempts,
@latest_score as latest_score
,@status as final_status;
       
select student_id, course_id, max(date_taken) ,score
from assessments
group by course_id, student_id,score;
select score from assessments where score in (select student_id, course_id, max(date_taken) from assessments
group by course_id, student_id);
       
#-----------------------------------------------------------------------
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