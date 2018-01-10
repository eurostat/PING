## ds_merge {#sas_ds_merge} 
Create a dataset by applying filtering conditions (when it exists), and/or stacking it
with annother dataset (one-to-one or one-to-many merge).

~~~sas
	%ds_merge(ref, rlib=WORK, dsn=, lib=WORK, by=, cond=, if=);
~~~

### Arguments
* `ref` : a master/reference dataset; may exist or not;
* `rlib` : (_option_) name of the library where the master dataset `ref` is stored; by 
	default: empty, _i.e._ `WORK` is used; however, if `ref` does not exist and `dsn` is 
	given, then it is set to `lib` (see below), otherwise it is set to the default value; 
* `dsn` : (_option_) a secondary datasets to stack/merge with the reference dataset;
* `lib` : (_option_) name of the library where the dataset `dsn` is stored; by default: 
	empty and `WORK` is used;
* `by` : (_option_) list of variables to use for (smart) sorted output stack; both datasets 
	`ref` and `dsn` need to be sorted by the same variables beforehand; 
* `cond` : (_option_) condition to apply to dsn data set;
* `if` : (_option_) condition to apply to dsn input data sets.

### Returns
Updates or creates the master dataset `ref`.

### Example
Let us consider both tables `_dstest30` and `_dstest31`, as respectively: 
The following table is stored in `_dstest30`:
geo | value 
----|-------
 BE |  0    
 AT |  0.1  
 BG |  0.2  
 '' |  0.3 
 FR |  0.4  
 IT |  0.5 

The following table is stored in `_dstest31`:
geo | value | unit
----|-------|-----
 BE |  0    | EUR
 AT |  0.1  | EUR
 BG |  0.2  | NAC
 LU |  0.3  | EUR
 FR |  0.4  | NAC
 IT |  0.5  | EUR

then we can "merge" `_dstest30` into `_dstest31` by invoking the macro as follows:
 
~~~sas
    	%let cond=%quote(in=a in=b);
	%let by=%quote(geo );
	%let if=%quote(A and B);
~~~
so that we get the output table:
geo | value | unit
----|-------|-----
AT	|  0.1	| EUR
BE	|  0	| EUR
BG	|  0.2	| NAC
FR	|  0.4	| NAC
IT	|  0.5	| EUR

since the condition `cond` applies on the table `ds_input_vi`.

Run macro `%%_example_ds_merge` for more examples.

### Note
The macro `%%ds_merge` processes several occurrences of the `data setp merge`, _e.g._ in short it runs
something like:

~~~sas
	DATA  &rlib..&ref;
		merge  
	 	%do _i=1 %to &ndsn;
			%let _dsn = %scan(&dsn, &_i);
			%if &nlib >1 %then %do;
				%let _lib = %scan(&lib, &_i);
			%end;
		    &_lib..&_dsn 
			%if &existcond=1 %then %do;
				(%scan(&cond, &_i))
			%end;
		%end; 
		;
       	%if not %macro_isblank(by)  %then   %do;  
	   		by &by;
	   	%end;
        %if not %macro_isblank(cond) and not %macro_isblank(if)  %then %do;
			if &if;
		%end;
 	run; 
~~~

### References
1. Michael J. Wieczkowski, IMS HEALTH, Plymouth Meeting: [Alternatives to Merging SAS Data Sets ... But Be Careful] (http://www.ats.ucla.edu/stat/sas/library/nesug99/bt150.pdf)
2. IDRE Research Technology Group["SAS learning module match merging data files in SAS"](http://www.ats.ucla.edu/stat/sas/modules/merge.htm).

### See also
[%ds_check](@ref sas_ds_check), [%ds_delete](@ref sas_ds_delete), [%ds_sort](@ref sas_ds_sort). 
