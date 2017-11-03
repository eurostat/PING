## ano_var_add {#sas_ano_var_add}
Add variable(s) to a dataset.

~~~sas
	%udb_var_add(dsn, lib=WORK, old1=new1, old2=new2, ...);
~~~

### Arguments
* `dsn` : input dataset where variables to be renamed;
* `lib` : (_option_) input library; default: `lib=WORK`; note that when this is passed,
	it should be set in 2nd position;
* `old1=new1, old2=new2` : (_option_) set of renaming couple of the form `old=new` so that
	the variable `old` shall be renamed into `new`.

### See also
[%ano_ds_select](@ref sas_ano_ds_select), [%ano_var_mask](@ref sas_ano_var_mask).
