CREATE DATABASE OnlineEduDB;

use OnlineEduDB;

CREATE TABLE Students (
  student_id INT PRIMARY KEY,
  name VARCHAR(50),
  city VARCHAR(50),
  join_date DATE
);

CREATE TABLE Instructors (
  instructor_id INT PRIMARY KEY,
  name VARCHAR(50),
  expertise VARCHAR(50)
);

CREATE TABLE Courses (
  course_id INT PRIMARY KEY,
  title VARCHAR(100),
  category VARCHAR(50),
  price DECIMAL(8,2),
  instructor_id INT,
  FOREIGN KEY (instructor_id) REFERENCES Instructors(instructor_id)
);

CREATE TABLE Enrollments (
  enrollment_id INT PRIMARY KEY,
  student_id INT,
  course_id INT,
  enroll_date DATE,
  status VARCHAR(20),
  FOREIGN KEY (student_id) REFERENCES Students(student_id),
  FOREIGN KEY (course_id) REFERENCES Courses(course_id)
);

CREATE TABLE Assessments (
  assessment_id INT PRIMARY KEY,
  student_id INT,
  course_id INT,
  score DECIMAL(5,2),
  date_taken DATE,
  FOREIGN KEY (student_id) REFERENCES Students(student_id),
  FOREIGN KEY (course_id) REFERENCES Courses(course_id)
);

CREATE TABLE Payments (
  payment_id INT PRIMARY KEY,
  student_id INT,
  course_id INT,
  amount_paid DECIMAL(8,2),
  payment_date DATE,
  FOREIGN KEY (student_id) REFERENCES Students(student_id),
  FOREIGN KEY (course_id) REFERENCES Courses(course_id)
);

INSERT INTO Students (student_id, name, city, join_date) VALUES
(1, 'Alice', 'Berlin', '2022-01-24'),
(2, 'Bob', 'Frankfurt', '2022-04-08'),
(3, 'Clara', 'Munich', '2022-12-04'),
(4, 'David', 'Stuttgart', '2022-02-19'),
(5, 'Eva', 'Hamburg', '2022-01-01'),
(6, 'Frank', 'Berlin', '2022-04-08'),
(7, 'Grace', 'Stuttgart', '2022-10-01'),
(8, 'Hank', 'Stuttgart', '2022-04-23'),
(9, 'Ivy', 'Stuttgart', '2022-07-08'),
(10, 'Jack', 'Hamburg', '2022-10-09'),
(11, 'Kara', 'Berlin', '2022-03-23'),
(12, 'Liam', 'Hamburg', '2022-06-09'),
(13, 'Mona', 'Munich', '2022-04-25'),
(14, 'Nina', 'Frankfurt', '2022-02-03'),
(15, 'Oscar', 'Hamburg', '2022-02-12');

INSERT INTO Instructors (instructor_id, name, expertise) VALUES
(101, 'Prof. Smith', 'Data Science'),
(102, 'Dr. Allen', 'Web Development'),
(103, 'Ms. Jain', 'Cloud Computing');

INSERT INTO Courses (course_id, title, category, price, instructor_id) VALUES
(1001, 'Intro to Python', 'Programming', 177.12, 103),
(1002, 'React & Redux', 'Frontend', 140.56, 101),
(1003, 'AWS for Beginners', 'Cloud', 171.07, 102),
(1004, 'ML with Python', 'Data Science', 159.46, 103),
(1005, 'Advanced SQL', 'Databases', 130.43, 101),
(1006, 'Docker & Kubernetes', 'DevOps', 195.97, 102),
(1007, 'JavaScript Mastery', 'Frontend', 106.78, 103),
(1008, 'Deep Learning', 'AI', 132.81, 101);

INSERT INTO Enrollments (enrollment_id, student_id, course_id, enroll_date, status) VALUES
(501, 1, 1006, '2023-01-02', 'dropped'),
(502, 1, 1005, '2023-02-25', NULL),
(503, 1, 1002, '2023-01-28', 'in-progress'),
(504, 2, 1002, '2023-03-15', NULL),
(505, 3, 1006, '2023-02-22', 'in-progress'),
(506, 3, 1002, '2023-06-22', 'in-progress'),
(507, 3, 1003, '2023-01-20', 'dropped'),
(508, 4, 1003, '2023-02-15', 'completed'),
(509, 4, 1005, '2023-03-21', 'in-progress'),
(510, 4, 1006, '2023-05-08', 'dropped'),
(511, 5, 1006, '2023-01-26', 'completed'),
(512, 5, 1007, '2023-04-09', 'in-progress'),
(513, 5, 1001, '2023-02-19', 'completed'),
(514, 6, 1006, '2023-04-21', 'in-progress'),
(515, 6, 1002, '2023-02-09', 'in-progress'),
(516, 6, 1008, NULL, 'completed'),
(517, 7, 1005, '2023-05-13', 'in-progress'),
(518, 7, 1006, '2023-02-05', 'in-progress'),
(519, 7, 1008, NULL, 'dropped'),
(520, 8, 1002, '2023-06-06', 'completed'),
(521, 9, 1007, '2023-04-20', NULL),
(522, 9, 1005, '2023-05-09', 'in-progress'),
(523, 9, 1001, '2023-01-22', 'dropped'),
(524, 10, 1002, '2023-06-11', 'in-progress'),
(525, 10, 1006, '2023-03-14', 'completed'),
(526, 10, 1005, '2023-04-01', 'completed'),
(527, 11, 1005, '2023-01-28', 'dropped'),
(528, 11, 1008, '2023-03-27', NULL),
(529, 11, 1002, '2023-05-20', 'dropped'),
(530, 12, 1003, '2023-02-18', 'in-progress'),
(531, 13, 1001, '2023-01-04', NULL),
(532, 13, 1005, '2023-03-08', 'in-progress'),
(533, 13, 1003, '2023-02-19', 'completed'),
(534, 14, 1002, '2023-04-27', 'dropped'),
(535, 15, 1003, '2023-06-16', 'completed');


INSERT INTO Assessments (assessment_id, student_id, course_id, score, date_taken) VALUES
(801, 1, 1006, 58.26, '2023-05-28'),
(802, 1, 1005, 98.22, '2023-05-25'),
(803, 1, 1002, NULL, '2023-03-13'),
(804, 2, 1002, 82.49, '2023-04-17'),
(805, 3, 1006, 62.4, '2023-01-11'),
(806, 3, 1003, 79.42, '2023-01-03'),
(807, 4, 1003, 52.94, '2023-01-02'),
(808, 4, 1005, NULL, '2023-02-09'),
(809, 4, 1006, 60.71, '2023-02-24'),
(810, 5, 1006, 78.55, '2023-04-08'),
(811, 5, 1007, 90.37, '2023-02-04'),
(812, 6, 1006, 71.18, '2023-04-28'),
(813, 6, 1002, NULL, '2023-06-04'),
(814, 7, 1005, 90.03, '2023-01-08'),
(815, 7, 1008, 57.01, '2023-02-09'),
(816, 8, 1002, 93.72, '2023-01-15'),
(817, 9, 1007, NULL, '2023-01-02'),
(818, 9, 1005, 77.03, '2023-01-03'),
(819, 9, 1001, NULL, '2023-02-14'),
(820, 10, 1002, 60.69, '2023-04-02'),
(821, 11, 1005, 96.33, '2023-04-10'),
(822, 11, 1008, 97.87, '2023-05-22'),
(823, 11, 1002, NULL, '2023-03-07'),
(824, 12, 1003, 78.96, '2023-05-02'),
(825, 13, 1001, 52.86, '2023-05-16'),
(826, 13, 1005, 92.64, '2023-02-02'),
(827, 13, 1003, 54.01, '2023-02-03'),
(828, 14, 1002, 83.76, '2023-02-13');

INSERT INTO Payments (payment_id, student_id, course_id, amount_paid, payment_date) VALUES
(901, 1, 1006, 195.97, '2023-02-19'),
(902, 1, 1005, 130.43, '2023-05-03'),
(903, 1, 1002, 140.56, '2023-05-19'),
(904, 2, 1002, NULL, '2023-03-07'),
(905, 3, 1006, 195.97, '2023-03-08'),
(906, 3, 1002, 140.56, '2023-02-22'),
(907, 3, 1003, NULL, '2023-04-11'),
(908, 4, 1003, NULL, '2023-01-01'),
(909, 4, 1005, NULL, '2023-05-04'),
(910, 5, 1006, NULL, '2023-03-05'),
(911, 5, 1007, 106.78, '2023-01-08'),
(912, 5, 1001, 177.12, '2023-02-15'),
(913, 6, 1006, 195.97, '2023-06-10'),
(914, 6, 1002, 140.56, '2023-06-17'),
(915, 7, 1005, 130.43, '2023-03-22'),
(916, 7, 1008, 132.81, '2023-03-04'),
(917, 8, 1002, 140.56, '2023-06-18'),
(918, 9, 1005, 130.43, '2023-02-23'),
(919, 9, 1001, 177.12, '2023-06-21'),
(920, 10, 1002, 140.56, '2023-05-16'),
(921, 10, 1006, 195.97, '2023-01-03'),
(922, 10, 1005, NULL, '2023-03-02'),
(923, 11, 1008, 132.81, '2023-06-09'),
(924, 12, 1003, 171.07, '2023-06-14'),
(925, 13, 1001, 177.12, '2023-01-03'),
(926, 13, 1005, 130.43, '2023-06-05'),
(927, 13, 1003, 171.07, '2023-03-19'),
(928, 14, 1002, 140.56, '2023-04-05');

select * from Students;
select * from Courses;
select * from instructors;
select * from enrollments;
select * from assessments;
select * from payments;

# List all students along with the courses they are enrolled in (include students with no enrollments).
select * from Students;
select * from Courses;
select * from Enrollments;

select s.student_id, s.name, e.enrollment_id,c.course_id, c.title from Students as s
left join Enrollments as e on s.student_id = e.student_id
left join Courses as c on c.course_id = e.course_id;

# Show course titles with instructor names, even if a course has no instructor assigned
select * from Courses;
select * from Instructors;

select c.course_id, c.instructor_id, i.instructor_id,c.title, i.name from Courses as c
left join instructors as i on c.instructor_id = i.instructor_id;

select * from instructors;
insert into instructors values (104, "Prof. Song", "Business intelligence");

# List all instructors and the total number of students they have across all their courses.

select * from Instructors;
select * from Students;
select * from courses;
select * from enrollments;

select i.instructor_id,
 count(e.student_id)
 from Instructors as i
left join courses as c on i.instructor_id = c.instructor_id
left join enrollments as e on c.course_id = e.course_id
group by i.instructor_id;

#Find students who have any NULL values in their enrollments (either status or enroll_date)
select * from enrollments where status is null or enroll_date is null;

# Find students who have never made a payment.
select * from students;
select * from payments;
select student_id from payments where amount_paid is null;

# Find the course with the most enrollments. Show its title and total count.
select * from enrollments;
select * from courses;

select c.course_id, count(c.course_id),c.title from enrollments as e
join courses as c on e.course_id = c.course_id
group by c.course_id
order by count(c.course_id) desc limit 1;

#For each assessment, show whether the student 'Passed' or 'Failed'.
#(Assume pass threshold is 60)

select * from Students;
select * from assessments;

select *,
case 
when score >= 60 then "pass"
else "Fail"
end as exam_status
from assessments;

#For each enrollment, label the status as: 'No Status' if it's NULL otherwise show the original status value

select * from enrollments;

select *,
case when status is null then "no status"
else status
end as status_check
from enrollments;

# List all payments with a flag column:
#'Full' if amount_paid equals course price
#'Partial' if less
#'Overpaid' if more

select * from Courses;
select * from payments;

select c.course_id,
p.course_id,
p.amount_paid,
c.price,
case 
when p.amount_paid = c.price then "Full"
when p.amount_paid < c.price then "Partial"
when p.amount_paid > c.price then "Overpaid"
else "unknown"
end as price_check
 from payments as p 
join courses as c on p.course_id = c.course_id;

#Show each student and count how many courses they are:
#'Active' in (status = 'in-progress')
#'Dropped' (status = 'dropped')
#'Completed' (status = 'completed')

select * from Students;
select * from Courses;
select * from enrollments;
select student_id, count(student_id) from enrollments
group by student_id;

SET SQL_SAFE_UPDATES = 0;


update enrollments set status = "inprogress" where status = "in-progress";

select 
s.student_id, 
s.name as student_name,
count(case when e.status = "inprogress" then 1 END) as active_course,
count(case when e.status = "dropped" then 1 END)as dropped_course,
count(case when e.status = "completed" then 1 END) as completed_course
from students as s
join enrollments as e on s.student_id = e.student_id
group by e.student_id;

select * from enrollments;

SELECT 
  s.student_id,
  s.name AS student_name,
  COUNT(CASE WHEN e.status = 'in-progress' THEN 1 END) AS active_courses,
  COUNT(CASE WHEN e.status = 'dropped' THEN 1 END) AS dropped_courses,
  COUNT(CASE WHEN e.status = 'completed' THEN 1 END) AS completed_courses
FROM Students s
LEFT JOIN Enrollments e ON s.student_id = e.student_id
GROUP BY s.student_id, s.name;

#------------------------------------------------------
#Count how many students joined:
#'This year' (join_date in 2024 or 2025)
#'Earlier' otherwise

select * from Students;
select * from enrollments;

select *,
case
when join_date like "%24" or join_date like "%25" then "this_year"
else "Earlier"
end as date_check
 from students;
 
 #------------------------------------------
 
#For each student, count how many payments they made above 100 (label as 'High') and how many at or below 100 ('Low').
select * from Students;
select * from payments;

select *,
case when p.amount_paid > 150 then "high"
else "low" 
end as price_labels
 from students as s
left join payments as p on s.student_id = p.student_id;

#----------------------------------------------

#show all enrollments with status 'dropped' or 'completed' and add a flag:
#'Finalized' if status is one of those
#'Ongoing' otherwise

select *,
case 
when status = "dropped" or status ="completed" then "Finalized"
when status is null then null
else "ongoing"
end as status_check
 from enrollments;
 
 #Multi-Condition Grouping
#Classify students into tiers based on:
#Enrolled in 3+ active courses → 'Highly Engaged'
#Enrolled in 1–2 active courses → 'Moderately Engaged'
#Otherwise → 'Not Engaged'

select * from students;
select * from enrollments;
select * from courses;
update enrollments set status = "inprogress" where course_id in (1008) and student_id in (6);

 #Multi-Condition Grouping
#Classify students into tiers based on:
#Enrolled in 3+ active courses → 'Highly Engaged'
#Enrolled in 1–2 active courses → 'Moderately Engaged'
#Otherwise → 'Not Engaged'
select * from enrollments;

select e.student_id , s.name,
count(case when e.status = "inprogress" then 1 end) as active_courses,
case
	when count(case when e.status = "inprogress" then 1 end) >= 3  then "highly_engaged"
	when count(case when e.status = "inprogress" then 1 end) between 1 and 2 then "moderately engaged"
	else " not engaged"
   end as engagement_level
from students as s
left join enrollments as e on s.student_id = e.student_id
group by e.student_id,s.name;

SELECT 
  s.student_id,
  s.name AS student_name,
  COUNT(CASE WHEN e.status = 'inprogress' THEN 1 END) AS active_courses,
  CASE 
    WHEN COUNT(CASE WHEN e.status = 'inprogress' THEN 1 END) >= 3 THEN 'Highly Engaged'
    WHEN COUNT(CASE WHEN e.status = 'inprogress' THEN 1 END) BETWEEN 1 AND 2 THEN 'Moderately Engaged'
    ELSE 'Not Engaged'
  END AS engagement_level
FROM Students s
LEFT JOIN Enrollments e ON s.student_id = e.student_id
GROUP BY s.student_id, s.name;

#For each assessment:Show student name, course title, score
#Add a column:
#'Pass' if score ≥ 60
#'Fail' if score < 60
#'Absent' if score is NULL

select 
s.student_id,
s.name,
c.title,
a.score,
(case when a.score >= 60 then "pass" end) as pass,
(case when a.score < 60 then "fail" end) as fail,
(case when a.score is null then "absent" end) as absent
 from students as s
left join assessments as a on s.student_id = a.student_id
left join courses as c on c.course_id = a.course_id;

select *,
case when a.score >= 60 then "pass"
when a.score <60 then "Fail"
else "absent"
end as exam_status
 from students as s
left join assessments as a on s.student_id = a.student_id
left join courses as c on c.course_id = a.course_id;

#Latest Activity Flag For each enrollment:
#Add a column:
#'Recent' if enrolled within last 30 days
#'Old' otherwise
#(Assume current date = CURDATE())

select * from enrollments;

select *,
case when enroll_date >= curdate() - interval 30 day then "recent"
else "old"
end as enroll_status
 from enrollments;
 
#curdate() - interval 30 day then ( “Give me the date exactly 30 days ago.”It subtracts 30 days from the current date:)

#1. Students Without Any Payments
#List all students who are enrolled in at least one course but have not made any payments yet.

select * from students;
select * from payments;
select * from students as s
join payments as p on s.student_id = p.student_id
where p.amount_paid is null;

#2. Course Completion Report 
#Show each course with:
#total number of enrollments
#number of completions (status = 'completed')
#completion rate as a percentage

select * from courses;
select * from enrollments ;

select e.course_id,
count(e.course_id) as total_no_of_enrollments,
count(case when e.status = "completed" then 1 end) as no_of_completions,
count(case when e.status = "completed" then 1 end) /count(e.course_id) * 100 as completoion_rate
 from enrollments as e
left join courses as c on e.course_id = c.course_id
group by e.course_id
order by no_of_completions desc;

select e.course_id,
count(e.course_id) as total_no_of_enrollments
 from enrollments as e
join courses as c on e.course_id = c.course_id
where e.status = "completed"
group by e.course_id;

#3. Instructor Revenue Report
#For each instructor, show:
#total number of courses
#total revenue from all payments to those courses

select * from courses;
select * from instructors;
select * from payments;

select c.instructor_id,c.course_id,c.title,
 count(c.instructor_id) as total_courses,
 sum(p.amount_paid) as revenue
 from instructors as i
join courses as c on i.instructor_id = c.instructor_id
join payments as p on p.course_id = c.course_id
group by c.instructor_id,c.course_id;

#4. Missing Assessments
#List students who enrolled in a course but did not appear for assessment (i.e., no matching record in Assessments).

select * from students;
select * from enrollments;
select * from assessments;

select * from students as s
join enrollments as e on s.student_id = e.student_id
left join assessments as a on e.student_id = a.student_id and e.course_id = a.course_id
where a.amount_paid is null;

select distinct s.student_id, s.name, e.course_id
from Students s
join Enrollments e on s.student_id = e.student_id
left join Assessments a on e.student_id = a.student_id and e.course_id = a.course_id
where a.assessment_id is null;

#5. Payment Discrepancy
#Show each payment where amount_paid does not match the course's price.
#Include student name, course title, course price, and amount paid.

select * from students;
select * from payments;
select * from courses;

select s.student_id, s.name , c.title, c.price, p.amount_paid from courses as c
join payments as p on c.course_id = p.course_id
join students as s on p.student_id = s.student_id
where c.price != p.amount_paid;

#6. Cross Table Course Progress
#List each student's enrollment, payment (if any), and assessment (if any) for each course.
#Show all in one row, even if some are missing

select * from students;
select * from courses;
select * from enrollments;
select * from payments;
select * from assessments;

select * from students as s
left join enrollments as e on s.student_id = e.student_id
left join courses as c on e.course_id = c.course_id
left join payments as p on e.student_id = p.student_id and e.course_id = p.course_id
left join assessments as a on e.student_id = a.student_id and e.course_id = a.course_id
order by s.student_id, e.course_id;

#7 Unassigned Courses
#List all courses that have no students enrolled.

select * from courses;
select * from enrollments;

select * from courses as c
left join enrollments as e on c.course_id = e.course_id
where e.course_id is null;

#8. Inactive Instructors
#Show instructors who have no courses assigned to them.

select * from instructors;
select * from courses;

select * from instructors as i
left join courses as c on i.instructor_id = c.instructor_id
where c.instructor_id is null;

#STORED PROCEDURES

delimiter //
create procedure students()
begin
select * from students;
end//
delimiter ;

call students();

delimiter //
create procedure high_priced_courses()
begin
select * from courses where price > 100;
end//
delimiter ;

#DROP PROCEDURE IF EXISTS high_priced_courses;
call high_priced_courses();

delimiter //
create procedure get_students_by_city(in city_name varchar(50))
begin
select * from students where city = city_name;
end//
delimiter ;

call get_students_by_city("berlin");

delimiter //
create procedure count_students_by_city( in city_name varchar(50), out student_count int)
begin
select count(*) into student_count
from students where city = city_name;
end//
delimiter ;

set @total = 0;
call count_students_by_city('Berlin',@total);
SELECT @total;

#3. Conditional Logic & Loops
delimiter //
create procedure check_student_volume(in city_name varchar(50))
begin
declare total int;
select count(*) into total from students where city = city_name;

if total >=5 then
	select "hihg number" as message;
else
	select "low number" as message;
end if;
end//
delimiter ;

call check_student_volume("Berlin");


#List all courses priced above a certain value
delimiter //
create procedure high_price_courses(in score_price int)
begin
select * from courses where price > score_price;
end//
delimiter ;

call high_price_courses(120);


#List  count of courses priced above a certain value
delimiter //
create procedure high_price_courses_count(in score_price int, out total_count int)
begin
select count(*) into total_count from courses where price > score_price;
end//
delimiter ;

set @total=0;
call high_price_courses_count(120,@total);
select @total as high_priced;

# Count how many courses a student is enrolled in
select * from courses;
select * from enrollments;
delimiter //
create procedure count_student_enrolled(in student_id_input int, out course_count int)
begin
select count(*) into course_count
from enrollments
where student_id = student_id_input;
end//
delimiter ;

set @total=0;
call count_student_enrolled(2,@total);
select @total;

delimiter //
create procedure total_student_enrolled()
begin
select student_id, count(*) 
from enrollments
group by student_id;
end//
delimiter ;

call total_student_enrolled();


#5. Return a student’s payment summary
-- IN: student_id
-- OUT: total_paid (sum of all payments made by that student

select * from payments;

delimiter //
create procedure student_payments(in student_id_input int, out total_paid int)
begin
select sum(amount_paid) into total_paid from payments 
where student_id = student_id_input;
end//
delimiter ;

set @amount=0;
call student_payments(1,@amount);
select @amount;






















