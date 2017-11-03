## income_components_disaggregated {#sas_income_components_disaggregated}
Retrieve (count) the occurrences of (dis)aggregated income variables in the input database. 

~~~sas
	%income_components_disaggregated(geo, year, var, idsn=, level=, weight=, cond=FILLED,
		index=0 1 2 3 4, odsn=SUMMARY_INC, ilib=WORK, olib=WORK);
~~~

### Arguments
* `geo` : a list of countries or a geographical area; default: `geo=EU28`; 
* `year` : year of interest;
* `var` : list of (personal and household) income components to be considered for 
	disaggregation; 
* `index` : (_option_) index defining the disaggregated income component to analyse; it is
	any integer (or list of integers) in [0-4], where 0 means that the aggregated variable 
	will also be analysed; default: `index=0 1 2 3 4`, _i.e._ all disaggregated components 
	are analysed;
* `cond` : (_option_) flag/expression used to define which properties of the disaggregated
	variable is analysed; it can be:
		+ `MISSING` for counting the number of observations where the flag is 1;
		+ `NOTMISSING`, ibid for observations where the flag is NOT -1;
		+ `NULL` for counting the number of observations where either the variable or the flag
			are null (value =0),
		+ `NOTNULL`, ibid for observations where both the variable and the flag are non null 
			(value >0);
		+ `FILLED` for counting observations with non null variable (value >0) and observations 
			with non null flag (value >0);
 
* `idsn` : (_option_) name of the input dataset; when passed, all the variables listed in `var` 
	should be present in the dataset `idsn`; when not passed, the input dataset will be set
	automatically to the PDB for the given year and the type of the given variable (see macro
	[silc_db_locate](@ref sas_silc_db_locate)); default: not passed;
* `ilib` : (_option_) name of the input library passed together with `idsn`; default: not passed,
	_i.e._ set automatically to the library of the PDB;
* `weight` : !!! NOT IMPLEMENTED YET (_option_) personal weight variable used to weighting 
	the distribution; default: `weight=RB050a` !!!

### Returns
* `odsn` : (_option_) name of the output dataset; default: `odsn=SUMMARY_INC`;
* `olib` : (_option_) name of the output library; by default, when not set, `olib=WORK`.

### Notes
1. This macro simply counts the occurrences of disaggregated income components according to
the condition(s) expressed in `COND`. It does not use any `PROC FREQ` for instance.
2. The weight `weight` is currently not used.

### Reference
EU-SILC survey reference document [doc65](https://circabc.europa.eu/sd/a/2aa6257f-0e3c-4f1c-947f-76ae7b275cfe/DOCSILC065%20operation%202014%20VERSION%20reconciliated%20and%20early%20transmission%20October%202014.pdf).

### See also
[income_components_gini](@ref sas_income_components_gini), [silc_db_locate](@ref sas_silc_db_locate).
