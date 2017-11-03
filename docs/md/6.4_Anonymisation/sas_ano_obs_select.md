## ano_obs_select {#sas_ano_obs_select}
Select a given observation/set of observations from a UDB dataset.

~~~sas
	%ano_obs_select(geo, time, idsn, odsn, var=, vartype=, where=, flag=, distinct=, ilib=, olib=);
~~~

### Arguments
* `geo` : list of (blank separated) countries ISO-codes; note that when `geo=_ALL_`, all
	countries will be processed, _i.e._ no condition on ISO-code will be imposed;
* `time` : year of interest; note that when `time=_ANY_`, all will be processed, _i.e._ no 
	condition on time will be imposed;
* `idsn` : (_option_) input dataset;
* `odsn` : (_option_) output dataset;
* `var` : (_option_) list of fields/variables of `idsn` upon which the extraction is performed; 
	default: `var` is empty (or `var=_ALL_`) and all variables are selected; 
* `vartype` : (_option_) type of variables passed, either personal (`P`), household (`H`)
	register (`R`) or (`D`); if empty (not recommended), the first letter of the first variable 
	in `var` will be used in place of `vartype`;
* `where` : (_option_) expression used to refine the selection (`WHERE` option); should be passed 
	with `%%str` or `%%quote`; default: empty;
* `flag` : (_option_) name of an additional flag variable (set to 1) added to the output dataset;
	default: ignored;
* `distinct` : (_option_) boolean flag (`yes/no`) set to use the `DISTINCT` option of the `PROC SQL` 
	selection procedure;
* `ilib` : (_option_) input library; default: `ilib=WORK`;
* `olib` : (_option_) output library; default: `olib=WORK`.

### Returns

### Example
Imagine one needs to create a table with UK households containing more than 10 members (`HHsize>=10`), 
_e.g._:
~~~sas
	PROC SQL:
	 	CREATE TABLE work.removeH AS 
		SELECT DISTINCT
		 	HB020, HB030,
			(1) as remove
	 	FROM pdb.udbh 
	 	WHERE HB020 = 'UK' AND HHSIZE >= 10;
	quit;
~~~

The procedure above can be ran equivalently using the following command:
~~~sas
	%ano_obs_select(UK, _ANY_, udbh, removeH, var=HB020 HB030, vartype=H, 
		where=%quote(HHSIZE>=10), flag=remove, ilib=pdb);
~~~

### See also
[%obs_select](@ref sas_obs_select), [%ds_select](@ref sas_ds_select).
