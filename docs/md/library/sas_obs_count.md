## obs_count {#sas_obs_count}
Check how many observations (rows) of a dataset verify a given condition.

~~~sas
	%obs_count(dsn, _ans_=, where=, pct=yes, distinct=no, lib=WORK);
~~~

### Arguments
* `dsn` : a dataset, for which the condition has to be verified;
* `where` : (_option_) SAS expression used to further refine the selection (`WHERE` option); 
	should be passed with `%%str`; default: empty;
* `pct` : (_option_) a boolean flag (`yes/no`) set to return the result as a percentage of the
	total observations in `dsn` that verify the condition `cond` above; default: `pct=yes`, 
	_i.e._ result is returned as a percentage [0,100] of the total numbers of observations;
* `distinct` : (_option_) boolean flag (`yes/no`) set to count only distinct values; in practice, 
	runs a SQL `SELECT DISTINCT` process instead of a simple `SELECT`; default: `no`, _i.e._ all 
	values are counted;
* `lib` : (_option_) the library in which the dataset `dsn` is stored.

### Returns
`_ans_` : name of the macro variable used to store the (quantitative) output of the test, which
	is, depending on the value of the flag `pct`: 
		+ `n`, the number of observations that verify the condition `cond` when `pct=yes`;
		+ 100*`n/N`, where `N` is the total number of observations in the dataset `dsn`, and `n` 
		is like above;

	hence the nul result corresponds to the situation `n=0`. where no observation in the dataset 
	verifies the input condition. 

### Examples
Let's perform some test on the values of test datatest #1000 (with 1000 observations sequentially
enumerated), _e.g._:
	
~~~sas
	%_dstest1000;
	%let ans=;
	%let cond=%quote(i le 0);
	%obs_count(_dstest1000, where=&cond, _ans_=ans);
~~~
returns `ans=0`, while:

~~~sas
	%let cond=%quote(i gt 0);
	%obs_count(_dstest1000, where=&cond, _ans_=ans);
~~~
returns `ans=100`, and:

~~~sas
	%let cond=%quote(i lt 400);
	%obs_count(_dstest1000, where=&cond, _ans_=ans);
~~~
returns `ans=40`.

Run `%%_example_obs_count` for more examples.

### Notes
1. For very large tables, the accuracy of the result returned when `pct=yes` is relative to
the precision of your machine. 
In practice, for tables with more than 1E9 observations where all but 1 verify the condition 
`cond`, the percentage calculated may still be equal to 100 (instead of a value<100). In that 
case, it is preferred to set the flag `pct` to `no` (see `%%_example_obs_count`).
2. Note in general the use of `%%str` (or `%%quote`) so as to express a condition. 

### Reference
Gupta, S. (2006): ["WHERE vs. IF statements: Knowing the difference in how and when to apply"](http://www2.sas.com/proceedings/sugi31/238-31.pdf).

### See also
[%ds_count](@ref sas_ds_count), [%ds_check](@ref sas_ds_check), [%ds_delete](@ref sas_ds_delete), 
[%ds_select](@ref sas_ds_select).
