use onlineedudb;
select * from students;
select * from enrollments;
select * from payments;
select * from assessments;
select * from courses;
#-----------------------------------------------------------------
-- Add Assessment Score Safely
-- Create a procedure:
-- add_assessment_with_validation
-- ask
-- Insert a new assessment record into assessments using transaction handling.
-- Validations
-- Before inserting:
-- 1. Student must exist
-- 2. Course must exist
-- 3. Student must be enrolled in that course
-- 4. Score must be between 0 and 100
-- 5. Student should not already have an assessment for that same course on same date
-- Transaction rule
select * from assessments;
delimiter //
create procedure add_assessment_with_validation( in student_id_input int, in course_id_input int,
in p_score decimal(5,2),
    in p_date_taken date)
begin


declare exit handler for sqlexception
begin
rollback;
signal sqlstate '45000'
set message_text ="assessment addition failed";
end;

if not exists( select 1 from students
where student_id = student_id_input) then 
	signal sqlstate '45000'
    set message_text = 'student does not exists';
end if;

if not exists(select 1 from courses 
where course_id = course_id_input) then 
	signal sqlstate '45000'
    set message_text = 'course does not exists';
end if;

if not exists(select 1 from enrollments
where student_id = student_id_input and course_id = course_id_input) then 
	signal sqlstate '45000'
    set message_text ='student not enrolled';
end if;

if p_score is null OR p_score < 0 OR p_score > 100 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'score should be between 0 and 100';
    END IF;
-- select score into p_score from assessments
-- where student_id = student_id_input and course_id = course_id_input and score between 0 and 100
-- and score is not null;

-- if exists (select 1 from assessments
-- where student_id = student_id_input and course_id = course_id_input and score not between 0 and 100
-- and score is  null) then 
-- 	signal sqlstate '45000'
--     set message_text ='score shud be between 0 and 100 and not null';
-- end if;

select date_taken into p_date_taken from assessments
where student_id = student_id_input and course_id = course_id_input;
-- 5. Student should not already have an assessment for that same course on same date
if exists (select 1 from assessments
where student_id = student_id_input and course_id = course_id_input and date_taken = p_date_taken) then
	signal sqlstate '45000'
    set message_text ='student already has an assesmmnet on that date';
end if;

start transaction;
insert into assessments (student_id, course_id, score, date_taken) values
(student_id_input, course_id_input, p_score, p_date_taken);
commit;

end//
delimiter ;
CALL add_assessment_with_validation(3, 1002, 88.50, CURDATE());

drop procedure if exists add_assessment_with_validation;
alter table assessments
modify assessment_id int auto_increment;
select * from assessments;
#----------------------------------------------------------------------------

-- Student Course Detail Report
-- Create procedure:
-- get_student_course_detail
-- Output
-- student_id | student_name | course_id | course_title | instructor_name | enroll_date | status
select * from instructors;
select * from courses;
delimiter //
create procedure get_student_course_detail(in student_id_input int)
begin
select s.student_id, s.name, c.course_id, c.title, i.name, e.enroll_date, e.status
 from students as s
left join enrollments as e on s.student_id = e.student_id
left join courses as c on e.course_id = c.course_id
left join instructors as i on i.instructor_id = c.instructor_id
where s.student_id = student_id_input;
end//
delimiter ;

call get_student_course_detail(5);

#-----------------------------------------------------------------------------
-- get Student Learning Health Repor
-- Create a procedure:
-- get_student_learning_health
-- Output
-- student_id | student_name | total_courses | completed_courses | dropped_courses | avg_score| total_paid | health_status

delimiter //
create procedure get_student_learning_health(in student_id_input int, out total_courses int, out comp int,
out dropped int, out avg_score decimal(10,2), out total_paid decimal(10,2), out h_status varchar(50) )
begin
select count(e.course_id),
count(case when e.status ="completed" then 1 end),
count(case when e.status = "dropped" then 1 end) ,
avg(a.score) ,
sum(p.amount_paid),
case
	when count(case when e.status = "dropped" then 1 end) >= 2 then "high risk"
    when avg(a.score) >= 80 and count(case when e.status ="completed" then 1 end) >= 2 then "excelent"
    when avg(a.score) >= 60 and sum(p.amount_paid)> 300 then "good"
    when count(e.course_id) =0 then "inactive"
    else "need improvenmet"
    end
    into total_courses, comp, dropped, avg_score, total_paid, h_status
    from enrollments as e 
left join assessments as a on e.student_id = a.student_id and e.course_id = a.course_id
left join payments as p on e.student_id = p.student_id and e.course_id = p.course_id
where e.student_id = student_id_input;
end//
delimiter ;

set @total_courses =0;
set @comp =0;
set @dropped =0;
set @avg_score =0.0;
set @total_paid=0;
set @h_status ="";
call get_student_learning_health(2,@total_courses, @comp,@dropped,@avg_score,@total_paid,@h_status);
select @total_courses, @comp,@dropped,@avg_score,@total_paid,@h_status;


-- #-------------------------------------------------------------------------
-- Top Performer Course for a Student
-- Create a procedure:
-- get_student_best_course
-- For the given student:
-- Find the course where the student scored highest
-- Return:
-- student_id
-- course_id
-- course title (from courses)
-- score
select a.student_id, c.course_id, c.title, max(a.score)
 from courses as c
left join assessments as a on c.course_id = a.course_id
group by a.student_id;

select * from assessments;
select student_id,  max(score) from assessments
group by student_id;

delimiter //
create procedure get_student_best_course(in student_id_input int)
begin
	select 
		a.student_id, 
		c.coursE_id,
		c.title, a.score,
		case
		when a.score >= 80 then "outstanding"
		when a.score >=60 then "good"
		else "okay"
		end as perform_tag
	 from assessments as a
	join courses as c on a.course_id = c.course_id
	where student_id = student_id_input 
	and a.score is not null and 
	a.score = (
				select max(score) from assessments
				where student_id = student_id_input and score is not null
			);
end//
delimiter ;

drop procedure if exists get_student_best_course;
call get_student_best_course(11);

#---------------------------------------------------------------------------
-- Detect Student Risk Level
-- Create a stored procedure:
-- get_student_risk_level
-- 📥 Input
-- IN p_student_id INT
-- 📊 Output
-- student_id | student_name | avg_score | total_courses | dropped_courses | risk_level

delimiter //
create procedure student_risk_level(in student_id_input int, out total_courses int, out dropped_courses int,
out risk_level varchar(50), out avg_score decimal(10,2))
begin
select count(e.course_id) ,
avg(a.score),
count(case when e.status ="dropped" then 1 end) ,
case 
	when count(case when e.status ="dropped" then 1 end) >= 2 then "high risk"
    when avg(a.score) <= 60 then "medium risk"
    when count(e.course_id) =0 then "inactive"
    else "low risk"
    end 
    into total_courses, avg_score, dropped_courses, risk_level
    from enrollments as e
left join assessments as a on e.student_id = a.student_id and e.course_id = a.course_id
where e.student_id = student_id_input;
end//
delimiter ;

drop procedure if exists student_risk_level;

set @total_courses =0;
set @dropped_courses =0;
set @risk_level = "";
set @avg_score =0.0;
call student_risk_level(2, @total_courses, @dropped_courses, @risk_level, @avg_score);
select @total_courses, @dropped_courses, @risk_level, @avg_score;

#------------------------------------------------------------------
-- Task: Write a stored procedure that does both of these in a single transaction:
-- Insert a new row into Enrollments
-- Insert a new row into Payments
-- Business Rule
-- Before inserting payment:
-- check the course price from Courses
-- if p_amount_paid is greater than course price, then:
-- do not insert anything
-- rollback transaction
-- Also:
-- if student does not exist → rollback
-- if course does not exist → rollback
-- Expected behavior
-- If everything is valid:
-- insert into Enrollments
-- insert into Payments
-- COMMIT
-- If any error happens:
-- ROLLBACK

delimiter //
create procedure enroll_student_with_payment
(in student_id_input int, in course_id_input int, in p_amount_paid decimal(10,2))
begin

declare v_price decimal(10,2);
declare exit handler for sqlexception
begin
rollback;
signal sqlstate '45000'
set message_text = 'insert failed';
end;

if not exists(Select 1 from students
where student_id = student_id_input) then
	signal sqlstate '45000'
    set message_text ='student does not exists';
end if;

if not exists(Select 1 from courses
where course_id = course_id_input) then
	signal sqlstate '45000'
    set message_text ='course does not exists';
end if;

if exists (select 1 from enrollments 
where student_id = student_id_input and course_id = course_id_input) then 
	signal sqlstate '45000'
    set message_text ='student enrolled';
end if;

select price into v_price from courses
where course_id = course_id_input ;


IF p_amount_paid > v_price THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'paid more than course price';
    END IF;

start transaction;
insert into enrollments(student_id, course_id, enroll_date, status) values
(student_id_input, course_id_input, curdate(), 'in-progress');

insert into payments (student_id, course_id, amount_paid, payment_date) values
(student_id_input, course_id_input, p_amount_paid,curdate());

commit;
end//
delimiter ;
drop procedure if exists enroll_student_with_payment;

call enroll_student_with_payment(8,1006,200);

ALTER TABLE enrollments 
MODIFY enrollment_id INT AUTO_INCREMENT;
alter table payments
modify payment_id int auto_increment;

select * from enrollments;
select * from payments;
select * from courses;
#----------------------------------------------------------------

-- Stored Procedure Question: Course Performance Report
-- 🎯 Create Procedure
-- get_course_performance_report
-- course_id | title | total_students | avg_score | pass_count | fail_count | pass_percentage
-- 📌 Requirements
-- 1. Total Students
-- 2. Average Score
-- 3. Pass / Fail Logic
-- score ≥ 60 → Pass
-- score < 60 → Fail
-- NULL → ignore
-- 4. Pass Count
-- 👉 Number of students who passed
-- 5. Fail Count
-- 👉 Number of students who failed
-- 6. Pass Percentage
-- (pass_count / total_students) * 100

select c.course_id, count(distinct(e.student_id)),
count(case when a.score >=60 then 1 end) as pass_count,
count(case when a.score < 60 then 1 end) as fail_count,
count(case when a.score is null then 1 end) as not_attempted,
round(count(case when a.score >=60 then 1 end)/count(distinct(e.student_id))*100,2) as pass_percentage
 from courses as c
left join enrollments as e on c.course_id = e.course_id
left join assessments as a on e.course_id = a.course_id and e.student_id = a.student_id
group by c.course_id;

delimiter //
create procedure get_course_performance_report(in course_id_input int)
begin

select c.course_id,c.title, count(distinct(e.student_id)) as total_students,
avg(a.score) as avg_score,
count(case when a.score >=60 then 1 end) as pass_count,
count(case when a.score < 60 then 1 end) as fail_count,
count(case when a.score is null then 1 end) as not_attempted,
round(count(case when a.score >=60 then 1 end)/count(distinct(e.student_id))*100,2) as pass_percentage
 from courses as c
left join enrollments as e on c.course_id = e.course_id
left join assessments as a on e.course_id = a.course_id and e.student_id = a.student_id
-- where course_id = course_id_input
group by c.course_id,c.title;
end//
delimiter ;

drop procedure if exists get_course_performance_report;
call get_course_performance_report(1001);

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

#-----------------------------------------------------------------------------

-- Create a stored procedure:
-- get_student_payment_summary
-- student_id | student_name | total_courses | pending_payments | completed_payments | total_amount_paid
select * from students;
select s.student_id, s.name,count(e.course_id),
count(case when p.amount_paid is null then 1 end) as pending_pays,
count(case when p.amount_paid >= c.price then 1 end) as comp_pays,
sum(p.amount_paid)
from students as s
left join enrollments as e on s.student_id = e.student_id
left join courses as c on e.course_id = c.course_id
left join payments as p on e.student_id = p.student_id and e.course_id = p.course_id
group by s.student_id;

delimiter //
create procedure stud_payment_summary(in student_id_input int, out total_courses int, out pen_pay int, out comp_pay int,
out total_paid decimal(10,2))
begin
select 
	count(e.course_id),
	count(case when p.amount_paid is null then 1 end) as pending_pays,
	count(case when p.amount_paid >= c.price then 1 end) as comp_pays,
	sum(p.amount_paid)
into total_courses, pen_pay, comp_pay, total_paid
from students as s
left join enrollments as e on s.student_id = e.student_id
left join courses as c on e.course_id = c.course_id
left join payments as p on e.student_id = p.student_id and e.course_id = p.course_id
where s.student_id = student_id_input;

select 
	s.student_id,
	 s.name, count(e.course_id) as total_courses,
	count(case when p.amount_paid is null then 1 end) as pending_pays,
	count(case when p.amount_paid >= c.price then 1 end) as comp_pays,
	sum(p.amount_paid) as total_paid_amt
from students as s
left join enrollments as e on s.student_id = e.student_id
left join courses as c on e.course_id = c.course_id
left join payments as p on e.student_id = p.student_id and e.course_id = p.course_id
group by s.student_id;

end//
delimiter ;
drop procedure if exists stud_payment_summary;

set @total_courses =0;
set @pen_pay=0;
set @comp_pay =0;
set @total_paid =0.0;
call stud_payment_summary(1, @total_courses, @pen_pay, @comp_pay, @total_paid);
select @total_courses, @pen_pay, @comp_pay, @total_paid;

#------------------------------------------------------------

delimiter //
create procedure stud_payment_summary_1(in student_id_input int)
begin
select 
s.student_id, s.name,
	count(e.course_id) as total_courses,
	count(case when p.amount_paid is null then 1 end) as pending_pays,
	count(case when p.amount_paid >= c.price then 1 end) as comp_pays,
	sum(p.amount_paid) as total_amt_paid
from students as s
left join enrollments as e on s.student_id = e.student_id
left join courses as c on e.course_id = c.course_id
left join payments as p on e.student_id = p.student_id and e.course_id = p.course_id
where s.student_id = student_id_input
group by s.student_id;
end//
delimiter ;

call stud_payment_summary_1(1);

#-----------------------------------------------------------------

-- Create a stored procedure:
-- update_student_bonus
-- For a given student (p_student_id):
-- Step 1: Count enrollments
-- If enrolled courses ≥ 3 → add +50
-- If enrolled courses = 2 → add +20
-- If enrolled courses = 1 → add +10
-- If no enrollments → no change
-- Step 2: Check performance
-- If avg score ≥ 80 → add +30
-- If avg score between 60–79 → add +10
-- If avg score < 60 → subtract -10
-- If no score → no change
-- 📤 Final Output

-- 👉 Updated value of p_bonus

delimiter //
create procedure update_bonus(in student_id_input int, inout p_bonus decimal(10,2))
begin
declare total_courses int;
declare avg_score decimal(10,2);

select count(course_id) into total_courses from enrollments
where student_id = student_id_input;

select avg(score) into avg_score from assessments
where student_id = student_id_input;

if total_courses >= 3 then
set p_bonus = p_bonus+50;
elseif total_courses =2 then 
set p_bonus =p_bonus+20;
elseif total_courses =1 then 
set p_bonus =p_bonus+10;
end if;

if avg_score >= 80 then
        set p_bonus = p_bonus + 30;
    elseif  avg_score >= 60 then
        set p_bonus = p_bonus + 10;
    elseif avg_score < 60 then 
        set p_bonus = p_bonus - 10;
    end if;


end//
delimiter ;

set @p_bonus =100;
call update_bonus(2, @p_bonus);
select @p_bonus;

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
create procedure refund (in student_id_input int, in course_id_input int,
out total_paid decimal(10,2), out total_assessments int, out refund_amt decimal(10,2), out v_status varchar(50))
begin
declare exit handler for sqlexception
begin
rollback;
signal sqlstate '45000'
set message_text ='refund failed';
end;


if not exists (select 1 from students
where student_id = student_id_input )then
	signal sqlstate '45000'
    set message_text = 'student does not exists';
end if;

if not exists (Select 1 from courses 
where course_id = course_id_input) then 
	signal sqlstate '45000'
    set message_text = 'course does not exists';
end if;

if not exists (select 1 from enrollments 
where student_id = student_id_input and course_id = course_id_input) then 
	signal sqlstate '45000'
    set message_text = 'student not enrolled';
end if;

-- Enrollment must NOT already be dropped or completed 
select status into v_status from enrollments
where student_id = student_id_input and course_id = course_id_input;

-- if v_status in ('dropped', 'completed') then 
-- 	signal sqlstate '45000'
--     set message_text = 'student status shud not be dropped or completed';
-- end if;

if exists (select 1 from enrollments 
where student_id = student_id_input and course_id = course_id_input 
and v_status in ('dropped', 'completed')) then 
	signal sqlstate '45000'
    set message_text ='student status must not be dropped or completed';
end if;

select sum(amount_paid) into total_paid
from payments 
where student_id = student_id_input and course_id = course_id_input
and amount_paid > 0;

if exists (select 1 from payments
where student_id = student_id_input and course_id = course_id_input
and amount_paid < 0)then
	signal sqlstate '45000'
    set message_text = 'refund already issued';
end if;

select count(score) into total_assessments from assessments
where student_id = student_id_input and course_id = course_id_input
and score is not null;

set refund_amt =-1*total_paid;

start transaction;
-- Case 1:
-- If total_paid = 0
-- → No refund
-- → Just mark dropped

if total_paid =0 then
set refund_amt=0;
end if;

 -- Case 2:
-- If total_paid > 0 AND
-- student has taken less than 2 assessments
-- → 100% refund
if total_paid >0 and total_assessments < 2 then 
insert into payments (student_id, course_id, amount_paid, payment_date) values
(student_id_input, course_id_input, refund_amt, curdate());
end if;

-- Case 3:
-- If total_paid > 0 AND
-- student has taken 2 or more assessments
-- → 50% refund
if total_paid >0 and total_assessments >= 2 then 
insert into payments (student_id, course_id, amount_paid, payment_date) values
(student_id_input, course_id_input, refund_amt/2, curdate());
end if;

update enrollments set status ='dropped' 
where student_id = student_id_input and course_id = course_id_input;
set v_status='dropped';

commit;
end//
delimiter ;
set @total_assessments = 0;
set @total_paid = 0;
set @refund_amt = 0;
set @v_status = '';
call refund(7, 1006, @total_assessments, @total_paid, @refund_amt, @v_status);

SELECT @total_assessments,@total_paid ,@refund_amt, @v_status; 

select * from enrollments;
select * from assessments where student_id =7 and coursE_id =1006;

#------------------------------------------------------------------------------------------

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