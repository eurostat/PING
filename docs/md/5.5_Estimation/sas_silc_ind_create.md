## silc_ind_create {#sas_silc_ind_create}
Create an indicator table from a common variable template and a list of additional labels.

~~~sas
	%silc_ind_create(dsn, dim=, var=, type=, len=, 
		ignore_var_dim=no, force_Nwgh=no, 
		cds_ind_con=META_INDICATOR_CONTENTS, cds_var_dim=META_VARIABLE_DIMENSION, 
		lib=WORK);
~~~
  
### Arguments
* `dsn` : name of the output (created) dataset;
* `dim` : (_option_) names of the (additional, Eurobase compatible) dimensions present in 
	the generated dataset, _i.e._ used as breadowns for the indicator; `dim` is incompatible 
	with `var` parameter (see below); default: `dim` is empty, _i.e._ the common template alone 
	is used (see `cds_ind_con` below);
* `var` : (_option_) when `dim` is not passed, it is possible to provide with the names of 
	the EU-SILC source variables used as breadowns for the indicator; then, corresponding 
	dimensions will be searched for in the configuration file that stores the correspondance 
	table between EU-SILC variable and Eurobase dimensions (see `cds_var_dim` below); `var` 
	is incompatible with `dim` parameter (see above); by default, `var` is empty and `dim` is
	used;
* `ignore_var_dim` : (_option_) 
* `type` , `len` : (_option_) types and lengths of the (additional) fields; must be the same 
	length as `var` or `dim`; see examples in [%ds_create](@ref sas_ds_create) for further 
	description; these are compatible with `ignore_var_dim=YES` only;
* `cds_ind_con` : (_option_) configuration file storing the template for the indicator, _i.e._
	generic variables common to EU-SILC indicators; by default,	it is named after the value 
	`&G_PING_INDICATOR_CONTENTS` (_e.g._, `META_INDICATOR_CONTENTS`); for further description, 
	see [%meta_indicator_contents](@ref meta_indicator_contents);
* `cds_var_dim` : (_option_) configuration file storing the correspondance table between EU-SILC
	variables and Eurobase dimensions; by default,	it is named after the value 
	`&G_PING_VARIABLE_DIMENSION` (_e.g._, `META_VARIABLE_DIMENSION`); for further description, 
	see [%meta_variable_dimension](@ref meta_variable_dimension);
* `force_Nwgh` : (_option_) additional boolean flag (`yes/no`) set when an additional
	variable `nwgh` (representing the weighted sample) is added to the indicator
	dataset; default: `force_Nwgh=no`, hence the variable `nwgh` will not be present in the 
	output indicator;
* `lib` : (_option_) name of the output library where `dsn` shall be stored; by default: 
	empty, _i.e._ `WORK` is used;
* `clib` : (_option_) name of the library where the configuration files are stored; default to 
	the value `&G_PING_LIBCFG`(_e.g._, `LIBCFG`) when not set.

### Returns
In `dsn`, an empty dataset where the (list of) variable(s) provided in `dim` has(ve) been added 
to the following template table: 
| geo | time | unit | ivalue | iflag | unrel | n | nwgh |ntot | ntotwgh | lastup | lastuser |
|-----|------|------|--------|-------|-------|---|------|-----|---------|--------|----------|
|     |      |      |        |       |       |   |      |     |         |        |          |
In practice, the variable(s) in `dim` is(are) added in between `unrel` and `n` variables of the
template.

### Examples
Running for instance

~~~sas
	%let dims=AGE 	RB090 	HT1;
	%silc_ind_create(dsn, dim=&dims);
~~~

creates the table `dsn` in the `WORK`ing library as:
| geo | time | unit | ivalue | iflag | unrel | AGE | SEX | HHTYP | n | nwgh | ntot | ntotwgh | lastup | lastuser |
|-----|------|------|--------|-------|-------|-----|-----|-------|---|------|------|---------|--------|----------|
|     |      |      |        |       |       |     |     |       |   |      |      |         |        |          |
where all dimensions `AGE, SEX, HHTYP` are of type `CHAR` and length 15. 

Run macro `%%_example_silc_ind_create` for examples.

### Notes
1. The common variables in the template dataset `cds_ind_con` are defined by default. However, 
they may be parameterised since their names derived from the following global variables:
|        |                     |
|:------:|:-------------------:|
| geo    | `G_PING_LAB_GEO`    |
| time   | `G_PING_LAB_TIME`   |
| unit   | `G_PING_LAB_UNIT`   |
| ivalue | `G_PING_LAB_VALUE`  |
| iflag  | `G_PING_LAB_IFLAG`  |
| unrel  | `G_PING_LAB_UNREL`  |
| n      | `G_PING_LAB_N`      |
| ntot   | `G_PING_LAB_NTOT`   |
|ntotwgh | `G_PING_LAB_TOTWGH` |

In addition a column:
| nwgh   | `G_PING_LAB_NWGH`   |

can be added when the flag `force_Nwgh` is set to `yes`.
2. Since the type and length of the variables to insert are searched for in configuration dataset
`cds_var_dim` (that stores the correspondance table between EU-SILC variables and Eurobase dimensions), 
either variablse `var` or dimensions `dim` must exist in the configuration file. 

### See also
[%meta_variable_dimension](@ref meta_variable_dimension), [%meta_indicator_contents](@ref meta_indicator_contents),
[%ds_create](@ref sas_ds_create).
