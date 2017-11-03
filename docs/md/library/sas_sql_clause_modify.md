## sql_clause_modify {#sas_sql_clause_modify}
Generate a statement (text) that can be interpreted by the `MODIFY` clause of a SQL procedure.

~~~sas
	%sql_clause_modify(dsn, var, _mod_=, fmt=, len=, lab=, lib=);
~~~

### Arguments
* `dsn` : a dataset reference;
* `var` : list of fields/variables of the input dataset `dsn` that will be modified;
* `fmt, len, lab`  : (_options_) format, length and label associated to the list of variables
	passed through `var`; must all be of the same lenght as `var`;
* `lib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.

### Returns
`_mod_` : name of the macro variable storing the SQL-like expression based on `var`, `fmt`,
	`len` and `lab` input parameters, and that can be typically in a `MODIFY` clause of a 
	SQL-procedure (_e.g._, `PROC ALTER`).

### Examples
The simple example below:

~~~sas
	%_dstest6;
	%let var=	d  		e;
    %let len=	20 		8;
	%let fmt=	$20. 	10.2; 
    %let lab=	d2 		e2;
	%let modexpr=;
	%sql_clause_modify(_dstest6, &var, fmt=&fmt, lab=&lab, len=&len, _mod_=modexpr);
~~~
returns `modexpr=d FORMAT=$20. LENGTH=20 LABEL='d2', e FORMAT=10.2 LENGTH=8 LABEL='e2'`.

### See also
[%ds_alter](@ref sas_ds_alter), [%sql_clause_add](@ref sas_sql_clause_add), 
[%sql_clause_as](@ref sas_sql_clause_as), [%sql_clause_by](@ref sas_sql_clause_by), 
[%sql_clause_where](@ref sas_sql_clause_where),
[MODIFY](https://support.sas.com/documentation/cdl/en/lestmtsref/63323/HTML/default/viewer.htm#n0g9jfr4x5hgsfn17gtma5547lt1.htm).
