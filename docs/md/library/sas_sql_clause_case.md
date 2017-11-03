## sql_clause_case {#sas_sql_clause_case}
Generate a quoted text that can be interpreted by the `CASE` clause of a SQL procedure.

~~~sas
	%sql_clause_case(dsn, var, _case_=, when=, then=, lib=);
~~~

### Arguments
* `dsn` : a dataset reference;
* `var` : list of fields/variables that will be added to `dsn` through 'ADD' clause;
* `when` : list of expressions to use as conditions (`WHEN`) in `CASE` statement; it 
	should be of same length, or length+1/-1, as `then`; 
* `then` : (_option_) list of expressions to use as executions (`THEN` values) in `CASE` 
	statement; it should be of same length, or length+1/-1, as `then`; when of length -1, 
	then an empty value is used;
* `lib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.

### Returns
`_case_` : name of the macro variable storing the SQL-like expression based on `var`, 
	`when`, and `then` input parameters and that can be used as is in a `CASE` expression.

### Examples
The simple example below:

~~~sas
~~~
returns .

### See also
[%ds_select](@ref sas_ds_select), [%sql_clause_where](@ref sas_sql_clause_where), 
[%sql_clause_as](@ref sas_sql_clause_as), [%sql_clause_add](@ref sas_sql_clause_add), 
[%sql_clause_by](@ref sas_sql_clause_by), [%sql_clause_modify](@ref sas_sql_clause_modify). 
