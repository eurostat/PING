## ds_count {#sas_ds_count}
Count the number of observations in a dataset, possibly missing or non missing for a given 
variable.

~~~sas
	%ds_count(dsn, _nobs_=, miss=, nonmiss=, distinct=no, lib=WORK);
~~~

### Arguments
* `dsn` : a dataset;
* `miss` : (_option_) the name of variable/field in the dataset for which only missing
	observations are considered; default: `miss` is not set;
* `nonmiss` : (_option_) the names of variable/field in the dataset for which only NON 
	missing observations are considered; this is obviously compatible with the `miss` 
	argument above only when the variables differ; default: `nonmiss` is not set;
* `distinct` : (_option_) boolean flag (`yes/no`) set to count only distinct values; in practice, 
	runs a SQL `SELECT DISTINCT` process instead of a simple `SELECT`; default: `no`, _i.e._ all 
	values are counted;
* `lib` : (_option_) name of the input library; by default: `WORK` is used.

### Returns
`_nobs_` : name of the macro variable used to store the result number of observations; 
	by default (_i.e._, when neither miss nor nonmiss is set, the total number of 
	observations is returned).

### Example
Let us consider the table `_dstest28`:
geo | value 
:--:|------:
 ' '|  1    
 AT |  .  
 BG |  2  
 '' |  3 
 FR |  .  
 IT |  5 

then we can compute the TOTAL number of observations in `_dstest28`:

~~~sas
	%local nobs;
	%ds_count(_dstest28, _nobs_=nobs);
~~~
returns `nobs=6`, while:

~~~sas
	%ds_count(_dstest28, _nobs_=nobs, nonmiss=value);
~~~
returns the number of observations with NON MISSING `value`, _i.e._ `nobs=4`, and:

~~~sas
	%ds_count(_dstest28, _nobs_=nobs, miss=value, nonmiss=geo);
~~~
returns the number of observations with MISSING `value` and NON MISSING `geo` at the same 
time, _i.e._ `nobs=1`.

Run macro `%%_example_ds_count` for more examples.

### Notes
1. This macro relies on [%obs_count](@ref sas_obs_count) macro since it actually runs:

~~~sas
	%obs_count(&dsn, _ans_=&_nobs_, where=&where, pct=no, lib=&lib);
~~~
with `where` defined, when both `miss` and `nonmiss` parameters are passed for instance,
as the SAS expression `&miss is missing and not(&nonmiss is missing)`.
2. In practice, running the commands (which imply the creation of an intermediary table):

 ~~~sas
	 %ds_count(dsn, _nobs_=c0, lib=lib);
	 %ds_select(dsn, _tmp, where=&cond, ilib=lib);
	 %ds_count(_tmp, _nobs_=c1, lib=lib);
~~~
provides with a result equivalent to simply launching:
	
~~~sas
	%let ans=;
	%obs_count(dsn, where=&cond, _ans_=ans, pct=yes, lib=WORK);
~~~
and comparing the values of `c0` and `c1`:

~~~sas
	 %if &c1=&c0 %then 			%let ans=100;
	 %else %if &c1 < &c0 %then 	%let ans=%sysevalf(100* &c1/&c0);
	 %else						%let ans=0;
~~~

### References
1. ["Counting the number of missing and non-missing values for each variable in a data set"](<http://support.sas.com/kb/44/124.html>).
2. Hamilton, J. (2001): ["How many observations are in my dataset?"](http://www2.sas.com/proceedings/sugi26/p095-26.pdf).

### See also
[%obs_count](@ref sas_obs_count), [%var_count](@ref sas_var_count), [%ds_check](@ref sas_ds_check), 
[%ds_isempty](@ref sas_ds_isempty), [%var_check](@ref sas_var_check).
