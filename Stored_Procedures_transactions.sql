use onlineedudb;
select * from students;
select * from enrollments;
select * from payments;
select * from assessments;
select * from courses;

-- Simple rule

-- Use OUT when you want one value:

-- total_revenue
-- average_score
-- student_status
-- 1. OUT is good when answer is ONE value

-- Example question:
-- What is the total amount paid by student 1?
-- Answer is one value:
-- Do not use OUT when you want many rows:

-- payment list
-- student list
-- course list
-- report table
-- 2. OUT is NOT good when answer is many rows

-- Example question:
-- Show all payments between two dates.
-- Answer is a table/list:
#--------------------------------------------------------------------------------
-- Stored Procedure Question: make_course_payment
-- Create a stored procedure that records a student’s payment for a course.
-- Insert a new payment record into the payments table safely using:
-- Validations before inserting
-- Before inserting payment:
-- 1. Student must exist
-- 2. Course must exist
-- 3. Student must be enrolled in that course
-- 4. Payment amount must be greater than 0
-- 5. Payment date cannot be in the future
-- 6. Student should not overpay
-- then throw error:
-- Payment exceeds course price
-- Insert rule
-- If all validations pass, insert into payments.
-- Expected insert columns:payment_id,course_id,amount_paid,payment_date

delimiter //
create procedure make_course_payment(in student_id_input int, in course_id_input int, in pay_amount decimal(10,2),
in p_date_taken date)
begin
declare course_price decimal(10,2);
declare already_paid decimal(10,2);

declare exit handler for sqlexception
begin
	rollback;
    resignal;
end;

start transaction;
if not exists (select 1 from students
where student_id = student_id_input) then
	signal sqlstate '45000'
    set message_text ='student does not exists';
end if;

if not exists(select 1 from courses
where course_id = course_id_input)then 
	signal sqlstate '45000'
    set message_text ='course does not exists';
end if;

if not exists( select 1 from enrollments
where student_id = student_id_input and course_id = course_id_input) then
	signal sqlstate '45000'
    set message_text ='student not enrolled';
end if;

if pay_amount < 0 or pay_amount is null then 
	signal sqlstate '45000'
    set message_text ='pay amount shud be > then 0';
end if;

if p_date_taken > curdate() then 
	signal sqlstate '45000'
    set message_text ='payment date cannot be a future date';
end if;

select 
price into course_price 
from courses
where course_id = course_id_input;

select 
coalesce(sum(amount_paid),0) into already_paid 
from payments
where student_id = student_id_input and course_id = course_id_input;

if already_paid+pay_amount > course_price then 
	signal sqlstate '45000'
    set message_text ='amount overpaid';
end if;

insert into payments (student_id,course_id,amount_paid,payment_date)
values (student_id_input,course_id_input,pay_amount,p_date_taken);
commit;

select 'payment added successfully' as message;

end//
delimiter ;

drop procedure if exists make_course_payment;
call make_course_payment(13,1005,40,curdate());

select * from payments;




#--------------------------------------------------------------
-- Stored Procedure Question:get_course_performance_by_category
-- Create a stored procedure that takes one input:
-- category_input VARCHAR(50)
-- Example:
-- CALL get_course_performance_by_category('Frontend');
-- Expected Outputcourse_id,course_title,category,instructor_name,total_enrollments,completed_count,dropped_count
-- avg_score,total_revenue,course_rank,performance_status

delimiter //
create procedure get_course_performance_by_category(in course_cat varchar(100))
begin
with enroll_data as
(
	select 
    c.course_id, c.title, c.category ,i.name as instructor_name,
    count(e.student_id) as total_enrollments,
    count(case when e.status = "completed" then 1 end) as completed_count,
    count(case when e.status = "dropped" then 1 end) as dropped_count
    from courses as c 
	left join enrollments as e on c.course_id = e.course_id
	left join instructors as i on c.instructor_id = i.instructor_id
	where c.category = course_cat
    group by c.course_id,c.title, c.category 
),
assess_data as
(select 
    c.course_id, c.title, c.category ,i.name as instructor_name,
	avg(a.score) as avg_score
    from courses as c 
	left join assessments as a on c.course_id = a.course_id
	left join instructors as i on c.instructor_id = i.instructor_id
	where c.category = course_cat
    group by c.course_id,c.title, c.category 
),
pay_data as
(
select 
    c.course_id, c.title, c.category ,i.name as instructor_name,
	coalesce(sum(p.amount_paid),0) as total_paid
    from courses as c 
	left join payments as p on c.course_id = p.course_id
	left join instructors as i on c.instructor_id = i.instructor_id
	where c.category = course_cat
    group by c.course_id,c.title, c.category 
)
	select 
		e.course_id,e.title, e.category,e.total_enrollments,e.instructor_name,
		e.completed_count,e.dropped_count
		,a.avg_score, p.total_paid,
		dense_rank() over ( order by p.total_paid desc) as course_rank ,
		case 
			when e.total_enrollments = 0 then 'No Enrollments'
			when e.dropped_count >= 2 then 'High Drop Risk'
			when a.avg_score >= 80 and p.total_paid >= 300 then 'Top Performing'
			when a.avg_score >= 60 then 'Average Performing'
			else  'Needs Improvement'
		end as performance_status
	from enroll_data as e
	join assess_data as a on e.course_id = a.course_id
	join pay_data as p on e.course_id = p.course_id
	where e.category = course_cat;

end//
delimiter ;

drop procedure if exists get_course_performance_by_category;

call get_course_performance_by_category("Frontend");



#----------------------------------------------------------------
-- Question 5: Stored Procedure with LIMIT Input
-- get_top_n_students_by_payment
-- Create a procedure that takes one input:
-- top_n_input
-- Example:CALL get_top_n_students_by_payment(5);
-- Expected output:student_id,student_name,city,total_paid,payment_rank
drop procedure if exists get_top_n_students_by_payment;

delimiter //
create procedure get_top_n_students_by_payment(in top_n int)
begin
select s.student_id, s.name,s.city, 
coalesce(sum(p.amount_paid),0) as total_paid ,
dense_rank() over (order by sum(p.amount_paid) desc) as payment_rank
from students as s
left join payments as p on s.student_id = p.student_id
group by s.student_id,s.name,s.city
order by coalesce(sum(p.amount_paid),0) desc
limit top_n;
end//
delimiter ;

call get_top_n_students_by_payment(5);


#--------------------------------------------------------------

-- Question 3: Stored Procedure with IF / ELSE
-- check_course_price_level
-- Create a procedure that takes course_id_input as input and returns course price level.
-- Expected output:course_id | course_title | price | price_level
drop procedure if exists check_course_price_level;

delimiter //
create procedure check_course_price_level(in course_id_input int)
begin
declare price_level varchar(100);
declare course_price decimal(10,2);
declare course_title varchar(100);

select price,title 
into course_price, course_title 
from courses
where course_id = course_id_input;

if course_price >= 180 then 
set price_level ="expenisve";

elseif course_price >= 140 then
set price_level = "medium";

else 
set price_level = "low";
end if;

select course_id_input as course_id,
course_price as price, course_title as title, price_level;

end//
delimiter ;

call check_course_price_level(1006);



#-----------------------------------------------------------------
-- Question 1: Stored Procedure with Date Range
-- get_payments_between_dates
-- Create a procedure that takes two input dates:
-- start_date_input
-- end_date_input
-- Return all payments made between those dates.
-- Expected output:payment_id,student_name,course_title,amount_paid,payment_date,payment_status
select * from payments;
drop procedure if exists get_payments_between_dates;

delimiter //
create procedure get_payments_between_dates(in start_date_input date, in end_date_input date)
begin
select 
p.payment_id, p.student_id, 
c.title, p.amount_paid, p.payment_date,
case when p.amount_paid is null then "not paid"
when p.amount_paid > 0 then "paid"
end as payment_status
 from payments as p
join students as s on p.student_id = s.student_id
join courses as c on p.course_id = c.course_id
where p.payment_date between start_date_input and end_date_input;
end//
delimiter ;

set @payment_status ="";
call get_payments_between_dates("2023-02-19","2023-05-03");


select * from payments;

#----------------------------------------------------------------
-- Question 2: Stored Procedure with Category Filter
-- Create a procedure that takes category name as input.
-- Example:CALL get_courses_by_category('Frontend');
-- Expected output:course_id,course_title,category,price,instructor_name,total_enrollments
-- Rules:
-- Show only courses from that category.
-- Even if course has no enrollments, it should still appear.
select * from courses;
select * from instructors;
drop procedure if exists get_courses_by_category;

delimiter //
create procedure get_courses_by_category(in course_cat varchar(50))
begin
select c.course_id, c.title,c.category, c.price, i.name, 
count(e.student_id) as total_enrollments
 from courses as c
right join instructors as i on c.instructor_id = i.instructor_id
join enrollments as e on e.course_id = c.course_id
where c.category = course_cat
group by c.course_id,c.title,c.category,c.price,i.name;
end//
delimiter ;

call get_courses_by_category("Frontend");







#---------------------------------------------------------------
-- Question: Enroll Student Safely

-- Create a stored procedure called: enroll_student_safe
-- It should insert a new row into the enrollments table using transaction handling.
-- Before inserting, check:
-- 1. Student must exist in students table
-- 2. Course must exist in courses table
-- 3. Enroll date cannot be NULL
-- 4. Status must be only:
--    'completed', 'in-progress', 'dropped'
-- 5. Student should not already be enrolled in the same course
select * from enrollments;

delimiter //
create procedure enroll_student_safely(in student_id_input int, in course_id_input int, in p_status varchar(50), 
in p_enroll_date date)
begin

declare exit handler for sqlexception
begin
rollback;
signal sqlstate '45000'
set message_text ='student enrollment failed ';
end;

start transaction;

if not exists(select 1 from students
where student_id = student_id_input) then 
	signal sqlstate '45000'
    set message_text ='student does not exists';
end if;

if not exists(select 1 from courses
where course_id = course_id_input) then 
	signal sqlstate '45000'
    set message_text ='course does not exists';
end if;

if p_enroll_date is null then 
	signal sqlstate '45000'
    set message_text ="enroll_date cannot be null";
end if;

if p_status not in ('completed', 'in-progress', 'dropped') then 
	signal sqlstate '45000'
    set message_text ="status shiud be 'completed', 'in-progress', 'dropped'";
end if;

-- 5. Student should not already be enrolled in the same course

if exists (select 1 from enrollments
where student_id = student_id_input and course_id = course_id_input) then 
	signal sqlstate '45000'
    set message_text ='student cannot be enrolled in the same course';
end if;


insert into enrollments ( student_id, course_id, enroll_date, status) values
(student_id_input, course_id_input, p_enroll_date, p_status);
commit;
end//
delimiter ;

CALL enroll_student_safely(2, 1003, 'in-progress', CURDATE());
CALL enroll_student_safely(1, 1006, 'completed', CURDATE());
select * from enrollments;


alter table enrollments
modify enrollment_id int auto_increment;

#---------------------------------------------------------------
-- Create a procedure called: course_performance_summary
-- For a given course, calculate:

-- total_students = total enrolled students
-- avg_score = average assessment score
-- pass_count = students with score >= 60
-- fail_count = students with score < 60
-- course_status = based on avg_score and total_students
-- Validations

-- Before calculation:
-- Course must exist.
-- Course must have at least one enrolled student.

delimiter //
create procedure course_performance_summary(in course_id_input int, out total_students int, out avg_score decimal(10,2),
out pass_count int, out fail_count int, out course_status varchar(50))
begin

declare exit handler for sqlexception
begin
signal sqlstate '45000'
set message_text ='course does not exits or student not enrolled';
end;

if not exists(select 1 from courses
where course_id = course_id_input) then 
	signal sqlstate '45000'
    set message_text ='course does not exists';
end if;

select count(student_id) into total_students from enrollments
where course_id =course_id_input ;

if total_students < 1 then 
	signal sqlstate '45000'
    set message_text = 'course must have atleast 1 student enrolled';
end if;

select count(e.student_id), avg(a.score),
count(case when a.score >= 60 then 1 end),
count(case when a.score < 60 then 1 end),
case when avg(a.score) IS NULL
    then  'No Assessment Data'
when avg(a.score) >= 80
    then 'Excellent Course Performance'
when avg(a.score) >= 60 AND avg(a.score) < 80
    then 'Good Course Performance'
when avg(a.score) < 60
    then 'Poor Course Performance' 
    end
into total_students, avg_score, pass_count, fail_count,course_status
    from enrollments as e
left join assessments as a on e.course_id = a.course_id and e.student_id = a.student_id
where e.course_id = course_id_input;

end//
delimiter ;

CALL course_performance_summary(
    1006,
    @total_students,
    @avg_score,
    @pass_count,
    @fail_count,
    @course_status
);
SELECT 
    @total_students AS total_students,
    @avg_score AS avg_score,
    @pass_count AS pass_count,
    @fail_count AS fail_count,
    @course_status AS course_status;
    
#---------------------------------------------------------------
-- Create a procedure called: make_course_payment_safe

-- Insert a new payment into the payments table safely.

-- Validations before insert
-- Student must exist.
-- Course must exist.
-- Student must be enrolled in that course.
-- Payment amount must be greater than 0.
-- Payment date cannot be NULL.
-- Student should not already have a payment record for the same course.

delimiter //
create procedure make_course_payment_safe(in student_id_input int, in course_id_input int, in p_amount_paid decimal(10,2),
in payment_date date)
begin
declare exit handler for sqlexception
begin
rollback;
signal sqlstate '45000'
set message_text = 'new payments cannot be added in payments table';
end;

start transaction;

if not exists(select 1 from students
where student_id = student_id_input)then 
	signal sqlstate '45000'
    set message_text ='student does not exists';
end if;

if not exists(select 1 from courses
where course_id = course_id_input)then 
	signal sqlstate '45000'
    set message_text ='course does not exists';
end if;

if not exists( select 1 from enrollments
where student_id = student_id_input and course_id = course_id_input) then
	signal sqlstate '45000'
    set message_text ='student not enrolled';
end if;

if p_amount_paid is null or p_amount_paid <= 0 then 
	signal sqlstate '45000'
    set message_text = 'payment amount shud be greater than 0';
end if;

if payment_date is null then 
	signal sqlstate '45000'
    set message_text ='payment date cannot be null';
end if;

if exists (select 1 from payments
where student_id = student_id_input and course_id = course_id_input) then 
	signal sqlstate '45000'
    set message_text = 'Student has a payment record for the same course';
end if;


insert into payments ( student_id, course_id, amount_paid, payment_date) values
(student_id_input, course_id_input, p_amount_paid, payment_date);
commit;

end//
delimiter ;


alter table payments
modify payment_id int auto_increment;

CALL make_course_payment_safe(4, 1006, 195.97, CURDATE());

SELECT *
FROM payments
WHERE student_id = 4
  AND course_id = 1006;
  
  select * from payments;

#---------------------------------------------------------------

-- Task
-- Update the status in the enrollments table for the given student and course.
-- Validations before update
-- Student must exist.
-- Course must exist.
-- Enrollment must exist for that student and course.
-- New status must be only one of these:
-- 'completed'
-- 'in-progress'
-- 'dropped'
-- If current status is already 'completed', do not allow changing it to 'dropped'.
-- Transaction rule
-- Use transaction handling:

delimiter //
create procedure update_enrollment_status_safe(in student_id_input int, in course_id_input int,
in p_new_status varchar(50))
begin

declare current_status varchar(50);
declare exit handler for sqlexception
begin
rollback;
signal sqlstate '45000'
set message_text ='enrollment status updation failed';
end;

if not exists(select 1 from students
where student_id = student_id_input) then 
	signal sqlstate '45000'
    set message_text ="student does not exists";
end if;

if not exists(select 1 from courses
where course_id = course_id_input) then 
	signal sqlstate '45000'
    set message_text ='course does not exists';
end if;

if not exists (Select 1 from enrollments
where student_id = student_id_input and course_id = course_id_input) then 
	signal sqlstate '45000'
    set message_text = 'student not enrolled';
end if;

select status into current_status from enrollments a
where student_id = student_id_input and course_id = course_id_input;

if p_new_status not in ('completed', 'dropped', 'in-progress') then 
	signal sqlstate '45000'
    set message_text = 'status not matched';
end if;

if current_status = 'completed' and p_new_status = 'dropped' then 
	signal sqlstate '45000'
    set message_text='compketed status cannot be chnaged to dropped';
end if;

start transaction;
update enrollments set status = p_new_status where 
student_id = student_id_input and course_id = course_id_input;
commit;

end//
delimiter ;

drop procedure if exists update_enrollment_status_safe;

call update_enrollment_status_safe(3,1002,'dropped');
CALL update_enrollment_status_safe(4, 1003, 'dropped');
select * from enrollments;
SELECT *
FROM enrollments
WHERE student_id = 4
  AND course_id = 1003;

#-----------------------------------------------------------------
-- Question: Student Course Report by Student ID
-- Create a stored procedure called:
-- student_course_report
-- Expected output columns
-- student_id,student_name,course_id,course_title,enrollment_status,score,amount_paid,payment_status,result_status

delimiter //
create procedure stud_course_report(in student_id_input int)
begin
select s.student_id,s.name ,
c.course_id, c.title, e.status,
a.score, p.amount_paid,
case
when p.amount_paid is null then "payment pending"
when p.amount_paid > c.price then "overpaid"
when p.amount_paid < c.price then "underpaid"
else "fully paid"
end as payment_status,
case
when a.score is null then "assessment pending"
when a.score < 60 then "fail"
when a.score >= 60 then "pass"
end as result_status
  from students as s
left join enrollments as e on s.student_id = e.student_id
left join courses as c on e.course_id = c.course_id
left join assessments as a on e.student_id = a.student_id and e.course_id = a.course_id
left join payments as p on e.student_id = p.student_id and e.course_id = p.course_id
where s.student_id = student_id_input;
end//
delimiter ;
drop procedure if exists stud_course_report;

call stud_course_report(1);
#-----------------------------------------------------------------

-- Question: Student Payment Summary with OUT Parameters
-- Create a procedure called: student_payment_summary
-- total_course_price 
-- total_paid 
-- pending_amount 
-- payment_status

delimiter //
create procedure student_pay_summary(in student_id_input int, out course_price decimal(10,2),
out total_paid decimal(10,2), out pend_amt decimal(10,2), out pay_status varchar(50))
begin
select sum(c.price),
coalesce(sum(p.amount_paid),0),
 sum(c.price)-coalesce(sum(p.amount_paid),0),
 case
	when coalesce(sum(p.amount_paid),0) =0 then "no payment"
    when sum(c.price)-coalesce(sum(p.amount_paid),0) = 0 then "fully paid"
    when sum(c.price)-coalesce(sum(p.amount_paid),0) > 0 and sum(c.price)-coalesce(sum(p.amount_paid),0) <= 150 then "small pending"
    when sum(c.price)-coalesce(sum(p.amount_paid),0)> 150 then "high pending"
    when sum(c.price)-coalesce(sum(p.amount_paid),0) < 0 then "overpaid"
    end 
 into course_price, total_paid, pend_amt , pay_status
 from enrollments as e 
left join courses as c on e.course_id = c.course_id
left join payments as p on e.course_id =p.course_id and e.student_id = p.student_id
where e.student_id = student_id_input;
end//
delimiter ;
drop procedure if exists student_pay_summary;

set @course_price =0.0;
set @total_paid =0.0;
set @pend_amt =0.0;
set @pay_status="";
call student_pay_summary(3,@course_price, @total_paid, @pend_amt, @pay_status);
select @course_price, @total_paid, @pend_amt, @pay_status;

select * from payments where student_id =4;
select * from courses where course_id in (1003, 1005);
#---------------------------------------------------------------------------


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

delimiter //
create procedure adding_assessment(in student_id_input int, in course_id_input int, in p_score decimal(10,2),
in p_date_taken date)
begin

declare exit handler for sqlexception
begin
	rollback;
	resignal;
end;

start transaction;

if not exists (Select 1 from students
where student_id = student_id_input) then
	signal sqlstate '45000'
	set message_text = "student does not exists";
end if;

if not exists(select 1 from courses
where course_id = course_id_input) then 
	signal sqlstate '45000'
    set message_text = "course does not exists";
end if;

-- 3. Student must be enrolled in that course

if not exists (select 1 from enrollments 
where student_id = student_id_input and course_id = course_id_input) then 
	signal sqlstate '45000'
    set message_text ='student not enrolled';
end if;

-- 4. Score must be between 0 and 100
select score into p_score from assessments
where student_id = student_id_input and course_id = course_id_input
and score is not null;

if p_score is null or p_score < 0 or p_score > 100 then
	signal sqlstate '45000'
    set message_text ='score must be between 0 and 100';
end if;

-- 5. Student should not already have an assessment for that same course on same date

if exists (select 1 from assessments 
where student_id = student_id_input and course_id = course_id_input and date_taken = p_date_taken) then
	signal sqlstate '45000'
    set message_text ='student has an assessment on that day for the course';
end if;

insert into assessments (student_id, course_id, score, date_taken) values
(student_id_input, course_id_input, p_score, p_date_taken);

commit;
SELECT 'Assessment added successfully' AS message;
end//
delimiter ;

drop procedure if exists adding_assessment;

call adding_assessment(1,1005,34,"2023-05-25");

select * from assessments;

delimiter //
create procedure add_assessments(in student_id_input int, in course_id_input int, in p_score decimal(10,2),
in p_date_taken date)
begin

declare exit handler for sqlexception
begin
rollback;
signal sqlstate '45000'
set message_text = "assessment addition failed";
end;

if not exists (select 1 from students
where student_id = student_id_input) then 
	signal sqlstate '45000'
    set message_text = "student does not exists";
end if;

if not exists (select 1 from courses
where course_id = course_id_input) then
	signal sqlstate '45000'
    set message_text = "course does not exists";
end if;

if not exists(select 1 from enrollments
where student_id = student_id_input and course_id = course_id_input) then 
	signal sqlstate '45000'
    set message_text ="student not enrolled";
end if;

if p_score is null or p_score < 0 or p_score > 100 then 
	signal sqlstate '45000'
    set message_text ="score shud be between 0 and 100";
end if;

IF p_date_taken IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'assessment date is required';
    END IF;
    
if exists (Select 1 from assessments
where student_id =student_id_input and course_id = course_id_input and date_taken = p_date_taken) then
	signal sqlstate '45000'
    set message_text ="student already has an assesmmnet on that date";
end if;

start transaction;
insert into assessments (student_id, course_id, score, date_taken) values
(student_id_input, course_id_input, p_score, p_date_taken);
commit;

select  'Assessment added successfully' as message;
end//
delimiter ;

drop procedure if exists add_assessments;

CALL add_assessments(8, 1002, 89.50, CURDATE());
select * from assessments;




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
drop procedure if exists student_learn_health;

delimiter //
create procedure student_learn_health(in student_id_input int, out total_courses int, out comp int, out dropped int, 
out avg_score decimal(10,2), out total_paid decimal(10,2) , out health_status varchar(50))
begin
select
count(e.course_id) ,
count(case when e.status ="completed" then 1 end) ,
count(case when e.status ="dropped" then 1 end) ,
round(avg(a.score),2),
coalesce(sum(p.amount_paid),0),
case
	when count(case when e.status = "dropped" then 1 end) >= 2 then "high risk"
    when avg(a.score) >= 80 and count(case when e.status ="completed" then 1 end) >= 2 then "excelent"
    when avg(a.score) >= 60 and sum(p.amount_paid)> 300 then "good"
    when count(e.course_id) =0 then "inactive"
    else "need improvenmet"
    end
into total_courses, comp,dropped,avg_score,total_paid, health_status
 from students as s
left join enrollments as e on s.student_id = e.student_id
left join assessments as a on e.student_id = a.student_id and e.course_id = a.course_id
left join payments as p on e.student_id = p.student_id and e.course_id = p.course_id
where s.student_id = student_id_input;

select s.name, total_courses, comp as completed_courses, dropped as dropped_courses, avg_score, total_paid, health_status
 from students as s
left join enrollments as e on s.student_id = e.student_id
left join assessments as a on e.student_id = a.student_id and e.course_id = a.course_id
left join payments as p on e.student_id = p.student_id and e.course_id = p.course_id
where s.student_id = student_id_input;
end//
delimiter ;


set @total_courses =0;
set @comp=0;
set @dropped =0;
set @avg_score =0.0;
set @total_paid =0.0;
set @health_status = "";
call student_learn_health(2,@total_courses,@comp,@dropped,@avg_score,@total_paid,@health_status);
select @total_courses,@comp,@dropped,@avg_score,@total_paid,@health_status;



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
create procedure stud_risk_level(in student_id_input int, out avg_score decimal(10,2),
out total_courses int, out dropped_courses int, out risk_level varchar(50))
begin
select avg(a.score),
count(e.course_id),
count(case when e.status ="dropped" then 1 end),
case 
	when count(case when e.status ="dropped" then 1 end) >= 2 then "high risk"
    when avg(a.score) <= 60 then "medium risk"
    when count(e.course_id) =0 then "inactive"
    else "low risk"
    end 
into avg_score, total_courses, dropped_courses, risk_level
 from enrollments as e
join assessments as a on e.student_id = a.student_id and e.course_id = a.course_id
where e.student_id = student_id_input;
end//
delimiter ;

set @avg_score =0.0;
set @total_courses =0;
set @dropped_courses =0;
set @risk_level ="";
call stud_risk_level(1, @avg_score, @total_courses, @dropped_cpurses, @risk_level);
select @avg_score, @total_courses, @dropped_cpurses, @risk_level;

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
delimiter //
create procedure course_perf()
begin
select c.course_id, c.title, count(distinct(e.student_id)) as total_students,
avg(a.score) as avg_score, 
count(case when a.score > 60 then 1 end) as pass_count,
count(case when a.score < 60 then 1 end) as fail_count,
count(case when a.score > 60 then 1 end)/count(e.student_id) * 100 as pass_percentage
 from courses as c
left join enrollments as e on c.course_id = e.course_id
left join assessments as a on e.course_id = a.course_id and e.student_id = a.student_id
-- where c.course_id = course_id_input
group by c.course_id, c.title;
end//
delimiter ;

drop procedure if exists course_perf;

call course_perf();





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