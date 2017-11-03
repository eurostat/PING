## ds_insert {#sas_ds_insert}
Insert  variables into a given dataset using the DATA step statemens 																																																																																																																																																																																																																														.

~~~sas
	%ds_insert(idsn, odsn=, var=, value=, ilib=WORK, olib=WORK);
~~~

### Arguments
* `idsn` : a dataset reference;
* `var`  : (_option_) list of variables to insert in `odsn` dataset; if empty no variable is inserted;
* `value`: (_option_) list of values that are assigned to each variable;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.
  
### Returns
* `odsn` : (_option_) name of the output dataset; by default: empty, _i.e._ `idsn` is also used;
    it will contain the variable/s inserted;
* `olib` : (_option_) name of the output library; by default: empty, _i.e._ `WORK` is also used;

### Examples
Let us consider the test dataset #38:
geo | EQ_INC20 | RB050a
:--:|---------:|------:
 BE |   10     |   10 
 MK |   50     |   10    
 MK |   60     |   10
 .. |   ..     |   ..   
and run the following:
	
~~~sas
	%let var =FMT DIM;
	%let value=%quote('fmt'||'_'||strip(geo)||'_') 4;
    %let odsn=TMP
   	%_dstest38;
	%ds_insert(_dstest38, odsn=&odsn,var=&var, value=&value);
~~~
to create the output table `TMP`:
geo | EQ_INC20 | RB050a   |   FMT  | DIM 
:--:|:--------:|---------:|-------:|-----:
 BE |   10     |    10    |fmt_BE_ |  4
 MK |   50     |    50    |fmt_MK_ |  4     
 MK |   60     |    60    |fmt_MK_ |  4
 .. |  ..      |    ..    |   ..   |  ..  

Run macro `%%_example_ds_insert` for examples.

### Notes
In short the macro runs the following `DATA STEP` statements:

~~~sas
	data &odsn;
	 	set &idsn;
		%do _i=1 %to &_nvar;
			  %scan(&var, &_i, &sep)=%scan(&value, &_i, &sep);
 		%end;
	run;
~~~

### See also
[%ds_contents](@ref sas_ds_contents)
