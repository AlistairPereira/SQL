use onlineedudb;
select * from students;
select * from enrollments;
select * from payments;
select * from assessments;
select * from courses;

-- A CTE is like a temporary table where you write a query, give it a name, and then use its results in the main query.
-- A CTE is a named temporary result set that is defined 
-- using a query and can be used in the main query to make complex SQL more readable and structured.

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



-- QUESTION: Detect First Payment per Student
-- 🎯 Task
-- For each student:
-- 👉 Identify their first payment (chronologically)
-- 👉 Compare all other payments against it
-- 📊 Output
-- student_id | course_id | payment_date | amount_paid | first_payment | diff_from_first
-- 📌 Requirements
-- Find first payment amount per student
-- Show it on every row

select * from (select student_id, course_id,payment_date, amount_paid,
row_number() over (partition by student_id order by payment_date asc) as first_payment
from payments) as p
where first_payment =1;
 
select 
student_id, 
course_id,
payment_date,
 amount_paid,
row_number() 
over (partition by student_id order by payment_date asc) as first_pay_date_wise,
first_value(amount_paid)
 over (partition by student_id order by payment_date asc) as first_payment,
abs(amount_paid - first_value(amount_paid) 
over (partition by student_id order by payment_date asc)) as diff_from_first_pay
from payments;

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
 
 
 #------------------------------------------------------------
--  Question: Top Performers Within Each Course
-- For each course:
-- 👉 rank students based on their assessment score (highest first)
-- 👉 show only students who have a score (ignore NULL)
-- 👉 display the top 3 performers per course

select * from (select student_id, course_id, score,
dense_rank() over (partition by course_id order by score desc) as top_scorers
from assessments
where score is not null) as r
where top_scorers <=3;


select * from (select course_id, student_id, date_taken,score,
dense_rank() over (partition by course_id order by score desc) as student_rank
 from assessments
 where score is not null) as r
 where student_rank <= 3;

#------------------------------------------------------

-- Question: Identify Consistently Improving Students
-- For each student & course:
-- 1️⃣ Compare each assessment score with the previous attempt
-- 2️⃣ Show whether the student improved, declined, or stayed same
-- 3️⃣ Calculate the score difference from the previous attempt
select * from assessments;
alter table assessments
modify assessment_id int auto_increment;
INSERT INTO assessments (student_id, course_id, score, date_taken)
VALUES (11, 1008, 95, CURDATE());

select student_id, course_id, score, date_taken,
lag(score) over (partition by course_id , student_id order by date_taken) as previous_score,
abs(score - lag(score) over (partition by course_id , student_id order by date_taken)) as score_diff,
case
when lag(score) over (partition by course_id , student_id order by date_taken) is null then null
when score > lag(score) over (partition by course_id , student_id order by date_taken) then "improved"
when score < lag(score) over (partition by course_id , student_id order by date_taken) then "declined"
else "same"
end as tag
 from assessments;


select student_id, course_id, date_taken,score,
lag(score) over (partition by course_id, student_id order by date_taken) as prev_score,
abs(score - lag(score) over (partition by course_id, student_id order by date_taken)) as score_diff,
case
	when lag(score) over (partition by course_id, student_id order by date_taken)is null then null
	when score > lag(score) over (partition by course_id, student_id order by date_taken) then 'improved'
    when score < lag(score) over (partition by course_id, student_id order by date_taken) then 'declined'
    else 'same'
    end as "label"
 from assessments
 where score is not null;
 
 
 #-----------------------------------------------------------------------
 -- 🧠 Question: Detect Revenue Leakage (Unpaid Enrollments)
-- The academy wants to find enrollments where:
-- ✅ student enrolled
-- ✅ course has a price
-- ❌ payment missing OR incomplete
-- AND also compute:total course price, total paidamount, amount_due, payment_status

with base as 
(
	select 
		c.title, e.student_id, e.course_id,c.price,
		coalesce(sum(p.amount_paid),0)as total_paid
	from enrollments as e
	left join courses as c on e.course_id = c.course_id
	left join payments as p on e.course_id = p.course_id and e.student_id = p.student_id
	where c.price is not null
	group by c.title, e.student_id,c.price,e.course_id
),
stud_info as
(
		select
			s.student_id,b.course_id, s.name,b.title, b.price, b.total_paid,
			b.price- b.total_paid as amount_due
		from students as s
		join base as b on s.student_id = b.student_id
)
select *,
case
    when total_paid < price then 'partital paid'
    when total_paid = 0 then 'unpaid'
    else 'paid'
    end as 'payment_status'
 from stud_info;


#Question: Students with Above Average Score
-- Find students whose average score is greater than 70

with stud_score as
(
	select 
    student_id, course_id, 
    avg(score) as avg_score 
    from assessments
	group by student_id, course_id
)
select * from stud_score
where avg_score > 70
and avg_score is not null;

#-----------------------------------------------------------------------------------

-- #Above Average Scorers per Course
-- 👉 Find students whose score is above the average score of their course
-- 📊 Output
-- student_id | course_id | score | course_avg
select * from assessments;

with course_avg_score as
 (
select 
	course_id, 
	avg(score) as avg_score 
from assessments
group by course_id
)
select 
	a.student_id, 
	c.course_id, 
	a.score, 
	c.avg_score 
from assessments as a 
join course_avg_score as c on a.course_id = c.course_id
where a.score > c.avg_score;

#---------------------------------------------------------------------------------
-- Q. Highest Paying Student per Course
-- Using payments:
-- Create a CTE to rank students by amount_paid within each course, then return only the highest paying student for each course.
-- Output:
-- student_id | course_id | amount_paid

with ranking as 
(select 
	student_id, course_id,amount_paid, 
	dense_rank() over (partition by course_id order by amount_paid desc) as rank_by_paid
from payments
where amount_paid is not null
  )
select * from ranking where rank_by_paid = 1;

#----------------------------------------------------------------------
-- Students with Both High Score and High Payment
-- Find students who:
-- have average score > 75
-- and total payment > 300
-- Output:
-- student_id | avg_score | total_payment

with avg_sc as (select student_id, avg(score)  as avg_score
from assessments
where score is not null
group by student_id),
total_pay as
(
select student_id, sum(amount_paid) as total_paid 
from payments
where amount_paid is not null 
group by student_id)
select s.student_id, s.name, a.avg_score, t.total_paid
 from students as s
join avg_sc as a on s.student_id = a.student_id
join total_pay as t on s.student_id = t.student_id
where a.avg_score > 75 and t.total_paid > 300;

#Q. Multiple CTEs
-- Find students who:
-- enrolled in more than 2 courses
-- have average score above the overall average score of all students
-- Expected output:
-- student_id | total_courses | avg_score

with stud_info as (
select
	 e.student_id, 
     count(e.course_id) as total_courses,
	avg(a.score) as avg_score
 from enrollments as e
join assessments as a on e.student_id = a.student_id and e.course_id = a.course_id
group by e.student_id
),
overall_stud_score as
(
select 
	student_id, 
	avg(score) over () as overall_avg_score 
from assessments
)
select s.student_id, s.total_courses,
o.overall_avg_score,
s.avg_score from stud_info as s
join overall_stud_score as o on s.student_id = o.student_id
where s.avg_score > o.overall_avg_score
and s.total_courses >=2;

#--------------------------------------------

with stud_info as (
select
	 e.student_id, 
     count(e.course_id) as total_courses,
	avg(a.score) as avg_score
 from enrollments as e
join assessments as a on e.student_id = a.student_id and e.course_id = a.course_id
group by e.student_id
),
overall_stud_score as
(
select 
	avg(score) as overall_avg_score 
from assessments
)
select s.student_id, s.total_courses,
o.overall_avg_score,
s.avg_score from stud_info as s
cross join overall_stud_score as o 
where s.avg_score > o.overall_avg_score
and s.total_courses >=2;

#----------------------------------------------------------------------------

-- CTE Question (Medium–Advanced)
-- 🎯 Question: Course with Highest Revenue
-- 👉 Find the course(s) that generated the highest total revenue
-- 📊 Expected Output
-- course_id | total_revenue
-- 👉 total revenue per course 
-- 👉 find the maximum revenue
-- 👉 return the course(s) whose revenue = max revenue

select * from courses;
select * from payments;

with course_total_paid as 
(
	select 
		course_id, 
		sum(amount_paid) as total_paid
	 from payments
	 where amount_paid is not null
	group by course_id
),
max_amt as 
(
	select 
		max(total_paid) as maximum_course_amt
	from course_total_paid
)
	select 
		c.course_id, 
        c.total_paid as total_rev, 
        m.maximum_course_amt
	 from course_total_paid as c
	cross join max_amt as m
	where c.total_paid = m.maximum_course_amt;

#------------------------------------------------------------------
-- QUESTION: Student Performance Category per Course
-- 🎯 Task
-- For each student in each course:
-- 👉 Compare their score with course average
-- 👉 Assign a performance category using CASE
-- 📊 Expected Output
-- student_id | course_id | score | course_avg | performance_tag

select 
	student_id, 
    course_id,
    score,
	avg(score) over (partition by course_id) as  course_avg,
dense_rank() over (partition by course_id order by score desc) as score_Wise_rank,
case
	when score > avg(score) over (partition by course_id) then "above avg"
    when score < avg(score) over (partition by course_id) then "below avg"
    when score = avg(score) over (partition by course_id) then "same"
    end as performance_tag
from assessments
where score is not null;

select course_id, avg(score) from assessments
group by course_id;
#--------------------------------------------------------------------------

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

#--------------------------------------------------------------------------
-- Question: Most Active Students
-- 👉 Find students who have enrolled in more courses than the average number of courses per student
-- 📊 Expected Output
-- student_id | total_courses | avg_courses
-- 📌 Requirements
-- Step 1:👉 Calculate total courses per student
-- Step 2:👉 Calculate overall average number of courses
-- Step 3:👉 Return students where:
-- total_courses > avg_courses

with total_enrolled as 
(
	select
		 student_id, 
		 count(course_id) as total_courses 
	 from enrollments
	group by student_id
),
avg_courses as 
(
	select 
		avg(total_courses) as avg_courses 
	from total_enrolled
)
select * ,
case 
	when t.total_courses >= a.avg_courses +2 then "highly active"
	when t.total_courses > a.avg_courses  then "active"
    else "normal"
	end as activity
    from total_enrolled as t
cross join avg_courses as a
where t.total_courses > a.avg_courses;

#--------------------------------------------------------------
-- Now your Window Function Question
-- 🧠 Question: Identify Top Growing Payments
-- 👉 For each student:
-- Compare current payment with previous payment
-- Calculate difference
-- Tag the trend using CASE
-- 📊 Expected Output
-- student_id | payment_date | amount_paid | prev_payment | diff | trend

select student_id, amount_paid, payment_date,
lag(amount_paid) over (partition by student_id order by payment_date) as prev_payment,
amount_paid - lag(amount_paid) over (partition by student_id order by payment_date) as diff,
case
	when lag(amount_paid) over (partition by student_id order by payment_date) is null then "first payment"
	when amount_paid > lag(amount_paid) over (partition by student_id order by payment_date) then "increased"
	when amount_paid < lag(amount_paid) over (partition by student_id order by payment_date) then "decreased"
    else "same"
    end as trend
from payments
where amount_paid is not null;

#------------------------------------------------------------------------

delimiter //
create procedure get_course_summary(in student_id_input int, out total_courses int, out avg_score decimal(10,2),
out high_scores decimal(10,2), out low_scores decimal(10,2), out performance_tag varchar(50))
begin
select count(e.course_id) ,
avg(a.score) ,
sum( case when a.score >=80 then 1 end) ,
sum(case when a.score >= 60 then 1 end),
case
	when avg(a.score) >= 80 then "excellent"
    when avg(a.score) >= 60 then "good"
    else "needs improvement"
    end 
    into total_courses, avg_score, high_scores, low_scores, performance_tag
    from enrollments as e
join assessments as a on e.course_id = a.course_id and e.student_id = a.student_id
where e.student_id = student_id_input;
end//
delimiter ;

set @total_courses =0;
set @avg_score =0.0;
set @high_scores =0.0;
set @low_scores =0.0;
set @performance_tag = "";
call get_course_summary(1, @total_courses,@avg_score,@high_scores,@low_scores,@performance_tag);
select @total_courses,@avg_score,@high_scores,@low_scores,@performance_tag ;

#-------------------------------------------------------------------------------------

-- Q: Students Who Improved Over Time
-- 👉 Find students whose latest score is higher than their first score
-- 📊 Expected Output
-- student_id | first_score | latest_score

with ein_score as 
(
	select * from 
		(
			select student_id, score as first_score,date_taken,
			row_number() over (partition by student_id order by date_taken asc) as f_score_rank
		from assessments
		where score is not null
        ) as f
	where f_score_rank =1
 ),
zwei_score as 
(
	select * from 
		(select 
			student_id, score as last_score,date_taken,
			row_number() over (partition by student_id order by date_taken desc) as l_score_rank
		 from assessments
		 where score is not null) as l
	 where l_score_rank =1
 )
	 select 
		e.student_id, e.first_score , z.last_score
	 from ein_score as e
	 join zwei_score as z on e.student_id = z.student_id
	 where z.last_score > e.first_score ;

#--------------------------------------------------------------------------

-- Q: Consecutive Payment Increase
-- 👉 Find students who have 2 consecutive payments where the amount increased
-- 📊 Expected Output
-- student_id | payment_date | amount_paid | prev_payment | prev2_payment

select student_id, payment_date, amount_paid,
lag(amount_paid,1) over (partition by student_id order by payment_date) as prev_payment,
lag(amount_paid,2) over (partition by student_id order by payment_date) as prev2_payment,
case 
when lag(amount_paid,2) over (partition by student_id order by payment_date)<
lag(amount_paid,1) over (partition by student_id order by payment_date) and 
lag(amount_paid,1) over (partition by student_id order by payment_date) < amount_paid then "imcreasing"
when lag(amount_paid,2) over (partition by student_id order by payment_date)>
lag(amount_paid,1) over (partition by student_id order by payment_date) and 
lag(amount_paid,1) over (partition by student_id order by payment_date) > amount_paid then "decrese"
else "fluctuating"
end as trend_flag
 from payments
 where amount_paid is not null;
 
 
 
 
 