## sql_clause_add {#sas_sql_clause_add}
Generate a statement that can be interpreted by the `ADD` clause of a SQL procedure.

~~~sas
	%sql_clause_add(dsn, var, _add_=, typ=CHAR, lib=WORK);
~~~

### Arguments
* `dsn` : a dataset reference;
* `var` : list of fields/variables that will be added to `dsn` (if they don't already exist
	in the dataset)through 'ADD' clause;
* `typ` : (_option_) type(s) of the `var` fields/variables added to the dataset; it must be
	of length 1 or of the same lenght as `var`: in the former case, it will be replicated to
	the lenght of `var`; default: `type=CHAR`;
* `lib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.

### Returns
`_add_` : name of the macro variable storing the SQL-like expression based on `var` and `typ` 
	input parameters and that can be used by in an `ADD` clause of a SQL-procedure (_e.g._, 
	`PROC ALTER`).

### Examples
The simple example below:

~~~sas
	%_dstest6;
	%let var=a b y z h;
	%let typ=char;
	%let expradd=;
	%sql_clause_add(_dstest6, &var, typ=&typ, _add_=expradd);
~~~
returns `expradd=y char, z char` since variables `y` and `z` are the only ones not already present 
in `_dstest6`.

### See also
[%ds_alter](@ref sas_ds_alter), [%sql_clause_modify](@ref sas_sql_clause_modify), [%sql_clause_as](@ref sas_sql_clause_as),
[%sql_clause_by](@ref sas_sql_clause_by), [%sql_clause_where](@ref sas_sql_clause_where).
