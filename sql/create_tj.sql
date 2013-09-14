use TJ_Test1;
create table test.TJ_R1_R2_R3
select
   distinct A, D, F
from
   (R1 natural join
    R2 natural join 
    R3);
