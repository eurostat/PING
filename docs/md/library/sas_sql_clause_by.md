## sql_clause_by {#sas_sql_clause_by}
Generate a quoted text that can be interpreted by the `BY` clause of a SQL procedure.

~~~sas
	%sql_clause_by(dsn, var, _by_=, lib=);
~~~

### Arguments
* `dsn` : a dataset reference;
* `var` : list of fields/variables of the input dataset `dsn` that will be used inside a 
	'BY' clause;
* `lib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.

### Returns
`_by_` : name of the macro variable storing the SQL-like expression based on `var` input 
	parameter and that can be used by in a `BY` clause of a SQL-procedure.

### Examples
The simple example below:

~~~sas
	%_dstest6;
	%let var=a b z h;
	%let exprby=;
	%sql_clause_by(_dstest6, a b z h, _by_=by);
~~~
returns `exprby=a, b, h` since variable `z` is not present in `_dstest6`.

### See also
[%ds_select](@ref sas_ds_select), [%sql_clause_as](@ref sas_sql_clause_as), 
[%sql_clause_add](@ref sas_sql_clause_add), [%sql_clause_modify](@ref sas_sql_clause_modify), 
[%sql_clause_where](@ref sas_sql_clause_where).
