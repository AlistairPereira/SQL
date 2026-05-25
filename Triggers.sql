use onlineedudb;
select * from students;
select * from enrollments;
select * from payments;
select * from assessments;
select * from courses;
-- What is a Trigger?
-- A trigger is a special SQL program that runs automatically when something happens in a table.
-- That “something” can be:
-- INSERT
-- UPDATE
-- DELETE

-- Trigger = automatic action after/before data changes in a table.
-- Example:
-- When a new payment is inserted into payments, automatically save a log in another table


-- Why do we use Triggers?
-- Triggers are used when we want the database to automatically handle some logic.

-- Common uses:
-- 1. Maintain audit logs
-- 2. Track old and new values
-- 3. Validate data before insert/update
-- 4. Automatically update another table
-- 5. Prevent wrong changes

-- Example:
-- If someone updates enrollment status from in-progress to completed, we can automatically save this change in a log table.

-- Types of Triggers
-- In MySQL, triggers mainly depend on timing and event.

-- Timing
-- BEFORE
-- AFTER
-- Event
-- INSERT
-- UPDATE
-- DELETE

-- So combinations are:

-- BEFORE INSERT
-- AFTER INSERT

-- BEFORE UPDATE
-- AFTER UPDATE

-- BEFORE DELETE
-- AFTER DELETE

-- Simple understanding
-- BEFORE INSERT
-- Runs before new row is inserted.
-- Used for validation or modifying data before saving.

-- Example:
-- Before inserting payment, check amount is not negative.

-- AFTER INSERT
-- Runs after new row is inserted.
-- Used for logs or summary updates.
-- Example:

-- After inserting payment, add entry into payment_log table.

-- BEFORE UPDATE
-- Runs before row is updated.
-- Used to stop wrong updates.
-- Example:
-- Before updating score, check score is between 0 and 100.

-- AFTER UPDATE
-- Runs after row is updated.
-- Used to record old and new values.
-- Example:
-- After updating enrollment status, save old status and new status in log table.

-- BEFORE DELETE
-- Runs before deleting a row.
-- Used to stop deletion or save backup.
-- Example:
-- Before deleting student, check if student has payments.

-- AFTER DELETE
-- Runs after deleting a row.
-- Used to save deleted data in backup/log table.
-- Example:
-- After deleting enrollment, save deleted enrollment info in audit table.

-- NEW

-- Used for new values.

-- Available in:

-- INSERT
-- UPDATE

-- OLD

-- Used for old values.

-- Available in:

-- UPDATE
-- DELETE

#---------------------------------------------------------------------------------
-- Create triiger to  stop negative payment amount.
delimiter //
create trigger stop_negative_payment_values
before insert on payments
for each row
begin
if new.amount_paid is null or new.amount_paid <=0 then
	signal sqlstate '45000'
    set message_text ='amount should be positive or greater than 0';
end if;
end//
delimiter ;

INSERT INTO payments (student_id, course_id, amount_paid, payment_date)
VALUES (4, 1006, -50, CURDATE());

show triggers;

select * from payments;
#-----------------------------------------------------------------
-- Stop Invalid Assessment Score 

delimiter //
create trigger stop_invalid_assessment_score
before insert on assessments
for each row
begin
if new.score is null or new.score <0 or new.score > 100 then 
	signal sqlstate '45000'
    set message_text = 'score shud be between 0 and 100';
end if;
end//
delimiter ;

INSERT INTO assessments (assessment_id, student_id, course_id, score, date_taken)
VALUES (900, 3, 1002, null, CURDATE());

#-----------------------------------------------------

CREATE TABLE enrollment_status_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    enrollment_id INT,
    student_id INT,
    course_id INT,
    old_status VARCHAR(20),
    new_status VARCHAR(20),
    changed_at DATETIME
);

select * from enrollment_status_log;

-- Whenever enrollment status changes, insert old and new status into enrollment_status_log

delimiter //
create trigger log_enrollment_status_update
after update on enrollments
for each row
begin

if old.status <> new.status then 
insert into enrollment_status_log( enrollment_id,student_id,course_id,old_status,new_status,changed_at)
values (old.enrollment_id, old.student_id, old.coursE_id, old.status, new.status, curdate());
end if;
end//
delimiter ;

select * from enrollments;
update enrollments set status = "dropped" where enrollment_id = 535;
select * from enrollment_status_log;
#----------------------------------------------------
-- Trigger Question: Auto Log New Payments
-- Create a trigger that automatically logs every new payment inserted into the payments table.
CREATE TABLE payment_insert_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    payment_id INT,
    student_id INT,
    course_id INT,
    amount_paid DECIMAL(10,2),
    payment_date DATE,
    logged_at DATETIME
);

delimiter //
create trigger log_new_payment_insert
after insert on payments
for each row
begin
insert into payment_insert_log (payment_id,student_id,course_id,amount_paid,payment_date,logged_at)
values(new.payment_id, new.student_id, new.course_id, new.amount_paid, curdate(), now());
end//
delimiter ;

select * from payments;
INSERT INTO payments (student_id, course_id, amount_paid, payment_date)
VALUES (4, 1006, 195.97, CURDATE());
select * from payment_insert_log;

#--------------------------------------------------------
-- Trigger Question: Stop Invalid Assessment Score
-- Create a trigger to stop invalid score values before inserting into assessments.
-- Rule
-- score can be NULL
-- but if score is entered, it must be between 0 and 100

delimiter //
create trigger stop_invalid_score
before insert on assessments
for each row
begin
if new.score < 0 or new.score > 100 then 
	signal sqlstate '45000'
    set message_text ='score shud be between 0 and 100   ';
end if;
end//
delimiter ;
#--------------------------------------------------------

-- Trigger Question: Prevent Deleting Students Who Have Payments
-- Create a trigger that stops deleting a student if that student has any payment records.
-- Trigger name

delimiter //
create trigger prevent_student_delete_if_payments_exist
before delete on students
for each row
begin
if exists (select 1 from payments
	where student_id = old.student_id
    and amount_paid is not null 
    and amount_paid > 0)
    then 
signal sqlstate '45000'
set message_text ='cannot delete student that has paid ';
end if;
end//
delimiter ;

select * from payments;

delete from students where student_id =3;

#-----------------------------------------------------
-- Question: Auto-Set Default Enrollment Status
-- When a new enrollment is inserted:
-- If status is NULL
-- Automatically set it to 'in-progress'

delimiter //
create trigger auto_set_status
before insert on enrollments
for each row
begin
if new.status is null then
set new.status ='in-progress';
end if;
end//
delimiter ;

INSERT INTO enrollments (student_id, course_id, enroll_date)
VALUES (17, 1006, CURDATE());
#----------------------------------------------------------

-- Question: Block Deleting Completed Enrollments
-- Business Rule:
-- If enrollment status = 'completed'
-- Prevent DELETE operation
-- Show error:
-- 'Completed enrollments cannot be deleted'

delimiter //
create trigger block_delete_completed_enrollments
before delete on enrollments
for each row
begin
if old.status ='completed' and old.status is not null then 
signal sqlstate '45000'
set message_text = 'completed status cannot be deleted';
end if;
end//
delimiter ;

select * from enrollments where status ='completed';
delete from enrollments where student_id =1 and course_id = 1006;

#---------------------------------------------------------

-- Auto-Complete Enrollment on 2 Passing Assessments
-- 🎯 Business Rule
-- When a student gets a new assessment inserted, and:
-- NEW.score >= 60
-- The student has at least 2 assessments with score >= 60 for that same course
-- And enrollment status is currently 'in-progress'
-- ✅ Then automatically update:
-- enrollments.status = 'completed'


delimiter //
create trigger pass_assessments
after insert on assessments
for each row
begin
declare total_attempts int;
declare v_status varchar(50);

if not exists(select 1 from enrollments
where student_id = new.student_id and course_id = new.course_id) then 
signal sqlstate '45000'
set message_text = 'student not enrolled';
end if;

select count(*) into total_attempts from assessments 
where student_id = new.student_id and course_id = new.course_id and score is not null;

select status into v_status from enrollments
where student_id = new.student_id and course_id = new.course_id ;

if new.score is not null and new.score >=60 and total_attempts >=2 and v_status ='in-progress' then 
update enrollments set status ='completed'
where student_id = new.student_id and course_id = new.course_id ;
end if;

end//
delimiter ;


UPDATE enrollments
SET status = 'in-progress'
WHERE student_id = 1 AND course_id = 1006;
INSERT INTO assessments (student_id, course_id, score, date_taken)
VALUES (1, 1006, 75, CURDATE());
#---------------------------------------------------------------------

-- Prevent Overpayment & Auto-Set Paid Status
-- 📌 Scenario: When a payment is inserted, the system must:
-- 1️⃣ Prevent students from paying more than the course price
-- 2️⃣ Automatically mark enrollment as 'paid' once full amount is reached
drop trigger auto_set_pay_status;
delimiter //
create trigger auto_set_pay_status
before insert on payments
for each row
begin
declare v_price decimal(10,2);
declare total_paid decimal(10,2);
if new.amount_paid is null or new.amount_paid <= 0 then
	signal sqlstate '45000'
	set message_text = 'Invalid payment amount';
end if;

select price into v_price 
from courses
where course_id = new.course_id;

select coalesce(sum(amount_paid),0) into total_paid from payments
where student_id = new.student_id and course_id = new.course_id and amount_paid > 0;

if total_paid+new.amount_paid > v_price then 
	signal sqlstate '45000'
    set message_text ='payment excedds course_price';
end if;

end//
delimiter ;



