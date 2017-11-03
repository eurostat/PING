## sql_clause_as {#sas_sql_clause_as}
Generate a quoted text that can be interpreted by the `AS` clause of a SQL procedure.

~~~sas
	%sql_clause_as(dsn, var, _as_=, as=, op=, lib=);
~~~

### Arguments
* `dsn` : a dataset reference;
* `var` : list of fields/variables that will be added to `dsn` through 'ADD' clause;
* `as` : (_option_) list of alias (`AS`) to use for the variables in `var`; if not empty, 
	then should be of same length as `var`; default: empty, _i.e._ the names of the variables 
	are retained;
* `op` : (_option_) list of unary operations (_e.g._, `min`, `max`, ...) to run (separately) 
	over the list of variables in `var`; if not empty, then should be of same length as `var`; 
	note that the string `_ID_` (see also variable `G_PING_IDOP`) is used for the identity 
	operation (_i.e._, no operation); default: empty, _i.e._ `_ID_` is used for all variables;
* `lib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.

### Returns
`_as_` : name of the macro variable storing the SQL-like expression based on `var`, `as`, and
	`op` input parameters and that can be used as is in an `AS` expression.

### Examples
The simple example below:

~~~sas
	%_dstest6;
	%let var= 	a 		b 		h
	%let as= 	ma 		B 		mh
	%let op= 	max 	_ID_ 	min
	%let asexpr=;
	%sql_clause_as(_dstest6, &var, as=&as, op=&op, _as_=asexpr);
~~~
returns `asexpr=max(a) AS ma, b, min(h) AS mh`.

### See also
[%ds_select](@ref sas_ds_select), [%sql_clause_where](@ref sas_sql_clause_where), 
[%sql_clause_case](@ref sas_sql_clause_case), [%sql_clause_add](@ref sas_sql_clause_add), 
[%sql_clause_by](@ref sas_sql_clause_by), [%sql_clause_modify](@ref sas_sql_clause_modify). 
