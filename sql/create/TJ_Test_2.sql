create database if not exists TJ_Test_2;
use TJ_Test_2;

create table if not exists R1
(
A varchar(255),
B varchar(255),
C varchar(255)
);

Insert into R1 (A,B,C) values ('a2','b2','c2');
Insert into R1 (A,B,C) values ('a2','b3','c2');
Insert into R1 (A,B,C) values ('a1','b1','c1');
Insert into R1 (A,B,C) values ('a3','b4','c3');
Insert into R1 (A,B,C) values ('a2','b5','c4');
Insert into R1 (A,B,C) values ('a2','b6','c2');
Insert into R1 (A,B,C) values ('a1','b7','c1');

create table if not exists R2
(
C varchar(255),
D varchar(255),
E varchar(255)
);

Insert into R2 (C,D,E) values ('c1','d1','e1');
Insert into R2 (C,D,E) values ('c2','d1','e2');
Insert into R2 (C,D,E) values ('c4','d1','e3');
Insert into R2 (C,D,E) values ('c3','d1','e4');
Insert into R2 (C,D,E) values ('c4','d1','e5');
Insert into R2 (C,D,E) values ('c3','d1','e6');

create table if not exists R3
(
E varchar(255),
F varchar(255),
G varchar(255)
);

Insert into R3 (E,F,G) values ('e1','f1','g20');
Insert into R3 (E,F,G) values ('e2','f2','g20');
Insert into R3 (E,F,G) values ('e3','f3','g20');
Insert into R3 (E,F,G) values ('e4','f4','g20');
Insert into R3 (E,F,G) values ('e5','f5','g20');
Insert into R3 (E,F,G) values ('e6','f5','g20');