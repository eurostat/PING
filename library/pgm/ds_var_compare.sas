options mprint;

data a;

input id a b c;

cards;

1 1.1 1.2 1.3

2 2.1 2.2 2.3

3 3.1 3.2 3.3

;

data b;

input idx abc bcd cde def efg fgh;

cards;

1 1.1 1.2 1.3 1.4 1.5 1.6

2 2.1 2.2 2.3 2.4 2.5 2.6

3 3.1 3.2 3.3 2.4 2.5 2.6

;

run;

%macro crazy_compare();

%let a=%sysfunc(open(work.a));

%let b=%sysfunc(open(work.b));

proc compare base=a compare=b /*listequalvar novalues nodate*/ noprint outstat=foobar(where=(_type_='NDIF' and sum(_BASE_, _COMP_)=0));

var %do i=1 %to %sysfunc(attrn(&a., nvars));

       %do j=1 %to %sysfunc(attrn(&b., nvars));

          %sysfunc(varname(&a., &i.))

       %end;

    %end;

;

with %do i=1 %to %sysfunc(attrn(&a., nvars));

        %do j=1 %to %sysfunc(attrn(&b., nvars));

           %sysfunc(varname(&b., &j.))

        %end;

     %end;

;

run;

%let rc=%sysfunc(close(&a.));

%let rc=%sysfunc(close(&b.));

%mend;

%crazy_compare;