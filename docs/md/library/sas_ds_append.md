## ds_append {#sas_ds_append}
Conditionally append reference datasets to a master dataset using multiple occurences of 
`PROC APPEND`.

~~~sas
	%ds_append(dsn, idsn, icond=, cond=, drop=, ikeep=_NONE_, lib=WORK, ilib=WORK);
~~~

### Arguments
* `dsn` : input master dataset;
* `idsn` : (list of) input reference dataset(s) to append to the master dataset;
* `drop` : (_option_) list of variable(s) present in the input master dataset to be removed
	from the final output dataset; default: `drop=`, no variable is dropped;
* `ikeep` : (_option_) list of variable(s) present in the input reference dataset(s) to be 
	kept in the final dataset; note the use of the predefined flag `_ALL_` so that a variable
	present in any of the `idsn` will be kept; default: `ikeep=`, _i.e._ only the variables 
	present in `dsn` (and not listed in `drop`) are kept;
* `cond`: (_option_) `where` condition/filter to apply on the master dataset; default: `cond=`,
	_i.e._ no filtering is applied;
* `icond`: (_option_) `where` condition/filter to apply on (all) the input reference dataset(s); 
	default: `icond=`, _i.e._ no filtering is applied;
* `lib` : (_option_) name of the library with (all) reference dataset(s); default: `lib=WORK`;
* `ilib` : (_option_) name of the library with master dataset; default: `ilib=WORK`.

### Returns
The table `dsn` is updated using datasets in `idsn`.

### Examples
Let us consider test dataset #32 in `WORK`ing library:
geo	   | value  
:-----:|-------:
BE	   |      0 
AT	   |     0.1
BG     |     0.2
LU     |     0.3
FR     |     0.4
IT     |     0.5
and update it using test dataset #33:
geo	   | value  
:-----:|-------:
BE	   |     1 
AT	   |     .
BG     |     2
LU     |     3
FR     |     .
IT     |     4
For that purpose, we can run for the macro `%%ds_append ` using the `drop`, `icond` and `ocond` 
options as follows:

~~~sas
	%let geo=BE;
	%let icond=(geo = "&geo");
	%let cond=(not(geo = "&geo"));
	%let drop=value;
	%ds_append(_dstest32, _dstest33, drop=&drop, icond=&icond, cond=&ocond);
~~~

so as to reset `_dstest32` to the table:
 geo | value  
:---:|-------:
AT	 |     0.1
BG   |     0.2
LU   |     0.3
FR   |     0.4
IT   |     0.5
BE	 |      1 

### Notes
1. The condition/filter on the input master dataset are applied prior to any processing, using the
following when both options `drop` and `cond` are set:

~~~sas
	DATA &lib..&dsn(DROP=&drop);
		SET &lib..&dsn;
		WHERE &cond;
	run;
~~~
2. Then, depending on the setting of option `ikeep`, the macro `%%ds_append` may process several 
occurrences of the `PROC APPEND` procedure like this:

~~~sas
	%do i=1 %to %list_length(&idsn);
		%let _idsn=%scan(&idsn, &_i);
		PROC APPEND
			BASE=&lib..&dsn
			DATA=&ilib..&_idsn(WHERE=&icond)
			FORCE NOWARN;
		run;
	%end;
~~~
when `ikeep=`, otherwise it consists in a `DATA step` similar to this:

~~~sas
	DATA  &lib..&dsn;
		SET &lib..&dsn 	
		%do i=1 %to %list_length(&idsn);
			%let _idsn=%scan(&idsn, &_i);
			%ds_contents(&_idsn, _varlst_=var, lib=&ilib);
			%let _ikeep&i=%list_intersection(&var, &ikeep);
			&ilib..&_idsn(WHERE=&icond KEEP=&&_ikeep&i)
		%end;
		;
	run;
~~~
3. If you aim at creating a dataset with `n`-replicates of the same table, _e.g._ running something like:

~~~sas
	   %ds_append(dsn, dsn dsn dsn); * !!! AVOID !!!;
~~~
so as to append to `dsn` a number `n=3` of copies of itself, you should instead consider to copy beforehand 
the table into another dataset to be used as input reference. Otherwise, you will create, owing to the `do` 
loop above, a table with (2^n-1) replicates instead, _i.e._ if you will append to `dsn` (2^3-1)=7 copies of 
itself in the case above. 

### References
0. SAS institute: ["Combining SAS datasets: Methods"](https://v8doc.sas.com/sashtml/lrcon/z1081414.htm).
1. Zdeb, M.: ["Combining SAS datasets"](http://www.albany.edu/~msz03/epi514/notes/p121_142.pdf).
2. Thompson, S. and Sharma, A. (1999): ["How should I combine my data, is the question"](http://www.lexjansen.com/nesug/nesug99/ss/ss134.pdf).
3. Dickstein, C. and Pass, R. (2004): ["DATA Step vs. PROC SQL: What's a neophyte to do?"](http://www2.sas.com/proceedings/sugi29/269-29.pdf).
4. Philp, S. (2006): ["Programming with the KEEP, RENAME, and DROP dataset options"](http://www2.sas.com/proceedings/sugi31/248-31.pdf).
5. Carr, D.W. (2008): ["When PROC APPEND may make more sense than the DATA STEP"](http://www2.sas.com/proceedings/forum2008/085-2008.pdf).
6. Groeneveld, J. (2010): ["APPEND, EXECUTE and MACRO"](http://www.phusewiki.org/wiki/index.php?title=APPEND,_EXECUTE_and_MACRO).
7. Logothetti, T. (2014): ["The power of PROC APPEND"](http://analytics.ncsu.edu/sesug/2014/BB-18.pdf).

### See also
[APPEND](https://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000070934.htm).
