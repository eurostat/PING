## ano_var_round {#sas_ano_var_round}
Round (personal or household) variables for a given list of countries.

~~~sas
	%ano_var_round(geo, iudb, var=, vartype=, where=, round=1, lib=WORK);
~~~

### Arguments
* `geo` : list of (blank separated) countries ISO-codes;
* `iudb` : input temporary UDB table; note that variables `DB010`, `DB020`, `&psuvar`
	and `&psuvar._F` must exist in the table;
* `var` : (_option_) list of variables to round; if empty, nothing is done (masking is
	skipped); 
* `vartype` : (_option_) type of variables passed, either personal (`P`), household (`H`)
	register (`R`) or (`D`); if empty (not recommended), the first letter of the first variable 
	in `var` will be used in place of `vartype`; 
* `where` : (_option_) additional `WHERE` clause used to further refine the conditions applied
	to select the values (observations) where the rounding occurs;
* `round` : (_option_) rounding value; default: `round=1` (integer rounding); 
* `lib` : (_option_) input library; default: `lib=WORK`.

### Return
Update the table `iudb` by rounding any/all of the (personal or household) variables that 
are passed to `var`.
	
### Example
Let us consider the following list of income variables to be rounded to the closest 50 euros
for UK:

~~~sas
	%let list_of_vars = PY010N PY010G; 
	%ano_var_round(UK , UDB_P, round=50, var=&list_of_vars, vartype=P, lib=WORK);
~~~ 
This is actually operating the following:
~~~sas
	PROC SQL;
		UPDATE WORK.UDB_P
		SET 	
			PY010N=(ROUND(&PY010N, 50)),
			PY010G=(ROUND(&PY010G, 50))
		 WHERE PB020 in ("UK"); 
	quit;
~~~ 

### See also
[%ano_var_mask](@ref sas_ano_var_mask).
