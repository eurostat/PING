## var_to_distinct {#sas_var_to_distinct}
Create a macro variable for each distinct value of a given variable in a dataset.

~~~sas
	%var_to_distinct(dsn, var, oname=, _count_=, lib=WORK);
~~~

### Arguments
* `dsn` : ; 
* `var` : ;
* `oname` : (_option_);
* `lib` : (_option_).
* `global` : (_option_) boolean flag (`yes/no`) set declare the created macro variables as
	global;

### Returns
* `_count_` : (_option_).

### References
1. Hemedinger, C. (2012): ["Implement BY processing for your entire SAS program"](http://blogs.sas.com/content/sasdummy/2012/03/20/sas-program-by-processing/).

### See also
[%var_to_list](@ref sas_var_to_list).
