## ano_var_replace {#sas_ano_var_replace}
Replace some old values of (personal or household) variables with new ones for a given list
of countries and given conditions.

~~~sas
	%ano_var_replace(geo, iudb, var=, vartype=, where=, old=, new=, lib=WORK);
~~~

### Arguments
* `geo` : list of (blank separated) countries ISO-codes; note that when `geo=_ALL_`, all
	countries will be processed, _i.e._ no condition on ISO-code will be imposed;
* `iudb` : input temporary UDB table; 
* `var` : (_option_) variable to replace `.`; if empty, nothing is done (_i.e._, masking is skipped);
* `vartype` : (_option_) type of variables passed, either personal (`P`), household (`H`)
	register (`R`) or (`D`); if empty (not recommended), the first letter of the first variable 
	in `var` will be used in place of `vartype`;
* `new` : (_option_) new replacement value; if both `new` and `expr` (see below) are emtpy, the 
	macro will replace the observations with old values (defined using the `old` or `where` arguments
	below) for `var` with this `new` value; incompatible with `expr`;
* `where` : (_option_) additional `WHERE` clause used to further refine the conditions applied
	to select the values (observations) to be replaced;
* `expr` : (_option_) replacement expression; it will be used to formulate the new values for 
	`var`; incompatible with `expr`;
* `old` : (_option_) list of old values to be replaced; if both `old` and `where` are emtpy, the macro 
	will replace missing values for `var`; this is equivalent to passing `where=%quote(&var = &old)`;
* `lib` : (_option_) input library; default: `lib=WORK`.

### Return
Update the table `iudb` by replacing any/all of the variables that are passed to `var`.
	
### Note
Let us consider the variable `DB040` where 'FI20' values need to be replaced with 'FI1B'
in `UDB_D1` for FI:

~~~sas
	%let var = DB040;
	%let old='FI20';
	%let new='FI1B';
	%ano_var_replace(FI, UDB_D1, var=&var, old=&old, new=&new, lib=WORK);
~~~ 
This is actually operating the following:
~~~sas
	PROC SQL;
		Update WORK.UDB_D1
			set DB040 = 'FI1B'
		where DB040 = 'FI20' and DB020 in ('FI');
	quit;
~~~ 
Note that one could also have ran the equivalent instructions:
~~~sas
	%ano_var_replace(FI, UDB_D1, var=&var, where=%quote(&var = &old), new=&new, lib=WORK);
~~~ 

### See also
[%ano_var_round](@ref sas_ano_var_round), [%ano_var_mask](@ref sas_ano_var_mask).
