-- RANKING

-- basic dense ranking
select dense_rank() over (order by salary desc) as rank,
name, department, salary
from employees
order by rank, id
;

-- partition by department
select dense_rank() over (partition by department order by salary desc) as rank,
name, department, salary
from employees
order by department, rank, id
;

-- groups based on salary value: ntile(N)
select ntile(3) over (order by salary desc) as tile,
name, department, salary
from employees
order by salary desc, id
;

-- exercise to return top earner from each department
with cte as (
select dense_rank() over (partition by department order by salary desc) as rn,
id, name, department, salary
from employees
order by department, rn, id
)
select id, name, department, salary
from cte
where cte.rn = 1


-- LAG/LEAD


select 
id, name, department, salary,
lag(salary, 1) over (order by salary) as prev,
lead(salary, 1) over (order by salary) as next,
round(
(salary - lag(salary, 1) over (order by salary)) * 100 /salary)
from employees
;

-- every row/salary should have cols with "low" & "high" salaries of the same department.
/*
practising the usage of first_value(salary)/last_value(salary) over "some window" as low
The query below will return correct values for "low" but weird for "high". The reason is that 
both functions operate not in a section defined by "partition by" but within a frame which is
dynamic. The solution is to bound the frame size to section boundaries (query 2)
*/
select
  name, department, salary,
  first_value(salary) over (partition by department order by salary) as low,
  last_value(salary) over (partition by department order by salary) as high
from employees
order by department, salary, id;

-- boundung a frame to a section
select
  name, department, salary,
  first_value(salary) over (partition by department order by salary
    rows between unbounded preceding and unbounded following) as low,
  last_value(salary) over (partition by department order by salary
    rows between unbounded preceding and unbounded following) as high
from employees
order by department, salary, id;

-- alternative solution (but required second sorting within each row)
select
  name, department, salary,
  first_value(salary) over (partition by department order by salary asc) as low,
  first_value(salary) over (partition by department order by salary desc) as high
from employees
order by department, salary, id;

-- percentage
with cte as (
select
  name, 
  city, 
  salary,
 first_value(salary) over (partition by city order by salary desc)  as max
from employees
order by city, salary, id)
select 
  name, 
  city, 
  salary,
ROUND(salary*1.0*100/max) as percent
from cte


-- AGGREGATION 
select
  name, department, salary,
  sum(salary) over (partition by city) as fund,
  round(salary * 100.0 / sum(salary) over (partition by city)) as perc
from employees
order by city, salary, perc;

-- some extra fields
select
  name, department, salary,
  count(id) over (partition by department) as emp_cnt,
  round(avg(salary) over (partition by department)) as sal_avg,
round(100.0*((salary - round(avg(salary) over (partition by department)))/round(avg(salary) over (partition by department)))) as diff
from employees
order by department, salary, id;