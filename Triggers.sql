use onlineedudb;
select * from students;
select * from enrollments;
select * from payments;
select * from assessments;
select * from courses;


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


