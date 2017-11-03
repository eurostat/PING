## ano_var_mask {#sas_ano_var_mask}
Set (personal or household) variables to missing for a given list of countries.

~~~sas
	%ano_var_mask(geo, iudb, var=, vartype=, where=, flag=yes, lib=WORK);
~~~

### Arguments
* `geo` : list of (blank separated) countries ISO-codes; note that when `geo=_ALL_`, all
	countries will be processed, _i.e._ no condition on ISO-code will be imposed;
* `iudb` : input temporary UDB table; 
* `var` : (_option_) list of variables to set to missing value `.`; if empty, nothing is 
	done (_i.e._, masking is skipped);
* `vartype` : (_option_) type of variables passed, either personal (`P`), household (`H`)
	register (`R`) or (`D`); this is used to define the georeferencing variable as `&vartype.B020`; 
	if empty (not recommended), the first letter of the first variable in `var` will be used in 
	place of `vartype`; 
* `where` : (_option_) additional `WHERE` clause used to further refine the conditions applied
	to select the values (observations) to set to missing;
* `flag` : (_option_) numeric or boolean (`yes/no`) value defined when the corresponding flag 
	variable shall also be masked (`flag=yes` or any value) or not (`flag=no`); when `flag=yes`,
	the value used for the flag is -1;
* `lib` : (_option_) input library; default: `lib=WORK`.

### Return
Update the table `iudb` by masking any/all of the (personal or household) variables 
that are passed to `var`.
	
### Note
Let us consider two personal income variables to set to missing for SI in the personal 
dataset `UDB_P`:

~~~sas
	%let list_of_vars = PY091G PY092G;
	%udb_var_mask(SI, UDB_P, var=&list_of_vars, flag=-1, vartype=P, lib=WORK);
~~~ 
This is actually operating the following:
~~~sas
	PROC SQL;
		UPDATE WORK.UDB_P
		SET 	
			PY091G=., PY091G_F=-1,
			PY092G=., PY092G_F=-1
		 WHERE PB020 in ("SI"); 
	quit;
~~~ 

### See also
[%ano_var_round](@ref ano_var_round).
