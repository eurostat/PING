## silc_ind_ref {#sas_silc_ind_ref}
List default aggregates calculated when estimating EU-SILC indicators in a given year. 

~~~sas
	%silc_ind_ref( odsn, ref=, ind=, _ref_=, _ind_=, replace=NO,
		cdsn=META_INDICATOR_CODES, clib=LIBCFG, olib=WORK);
~~~

### Arguments
* `ref` : (_option_) input list of library reference(s), _e.g._ any string(s) in `RDB`, 
	`RDB2`, `EDB`, `LDB`; incompatible with any of the parameters `ind` or `_ref_` 
	(below);
* `ind` : (_option_) input list of indicators; incompatible with any of the parameters 
	`ref` (above) or `_ind_` (below);
* `replace` : (_option_) boolean flag (`yes/no`) set when the output table `odsn` (see
	below) shall be overwritten in the case it already exists; default: `replace=NO`, _i.e._
	results will be appended to `odsn`;
* `cdsn` : (_option_) name of the metadata table containing the codes and reference
	libraries of all indicators created in production; it looks like this:
| code  | survey | lib |
|------:|:------:|:---:|
| DI01	| EUSILC | RDB |
| DI02	| EUSILC | RDB |
| DI03	| EUSILC | RDB |
| DI04	| EUSILC | RDB |
| DI05	| EUSILC | RDB |
| di06	| ECHP   |     |
| DI07	| EUSILC | RDB |
| di07h	| ECHP   |     |
| ...   |  ...   | ... |
	default: `cdsn=META_INDICATOR_CODES` (see `clib` below);
* `clib` : (_option_) library where `cdsn` is stored; default: `clib=LIBCFG`.

### Returns
* `odsn` : (_option_) excerpt of the metadata table `cdsn` where the output observations 
	are: 
		+ either all observations in `cdsn` for which the variable `lib` matches any of
		the reference library(ies) listed in `ref` when this argument is passed;
		+ or all observations in `cdsn` for which the variable `code` matches any of
		the indicator(s) listed in `ind` when this argument is passed instead;

* `_ref_` : (_option_) name of the variable storing the output list of all reference 
	libraries that contain any of the indicator(s) passed through `ind` as input; 
	incompatible with any of the parameters `ref` (above) or `_ind_` (below);
* `_ind_` : (_option_) name of the variable storing the output list of indicators contained
	in any of the library(ies) passed through `ref` as input.

### Examples
Given the table `META_INDICATOR_CODES` in `LIBCFG`, the following command:

~~~sas	
	%let list=;
	%silc_ind_ref( dsn, ind=PEPS01 E_MDDD11, _ref_=list, replace=YES);
~~~
will set `list=EDB RDB` and create the following `dsn` table:
| code      | survey    | lib |
|----------:|:---------:|:---:|
| E_MDDD11	| EUSILC	| EDB | 
| PEPS01	| EUSILC	| RDB | 

See `%%_example_silc_ind_ref` for more examples.
	
### See also
[%silc_ref2lib](@ref sas_silc_ref2lib), [%silc_agg_compute](@ref sas_silc_agg_compute).