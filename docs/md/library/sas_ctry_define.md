/** \cond
## OBSOLETE ctry_define OBSOLETE {#sas_ctry_define}
Define the list of countries (_i.e._, the ISO codes) included in a given geographic area 
(_e.g._, EU28).

~~~sas
	%ctry_define(zone, year, _ctrylst_=, _ctryclst_=, cds_ctryxzone=, clib=);
~~~

### Note
*OBSOLETE - use [%zone_to_ctry](@ref sas_zone_to_ctry) instead - OBSOLETE*

### Arguments
* `zone` : code of a geographical zone, _e.g._, EU28, EA19, etc...;
* `year` : (_option_) year to consider; if empty, all the countries that belong, or once 
	belonged, to the given area `zone` are returned (see [%zone_to_ctry](@ref sas_zone_to_ctry)); 
	by default, it is set to the value `&G_PING_LAB_GEO` (_e.g._, `GEO`); 
* `cds_ctryxzone` : (_option_) configuration file storing the description of geographical areas; 
	by default, it is named after the value `&G_PING_COUNTRYxZONE` (_e.g._, `COUNTRYxZONE`); for 
	more details, see also [%ctry_in_zone](@ref sas_ctry_in_zone);
* `clib` : (_option_) name of the library where the configuration file is stored; default to the
	value `&G_PING_LIBCFG`(_e.g._, `LIBCFG`) when not set.
 
### Returns
`_ctryclst_` or `_ctrylst_` : name of the macro variable storing the output list, either a list of 
(comma separated) strings of countries ISO3166-codes in-between quotes when `_ctryclst_` is passed, 
or an unformatted list when `_ctrylst_` is passed; those two options are incompatible.

### Examples
Let us consider a simple example:

~~~sas
	%let ctry_glob=;
	%let zone=EU28;
	%let year=2010;
	%ctry_define(&zone, year=&year, _ctryclst_=ctry_glob);
~~~	
returns the (quoted) list of 28 countries: 
`ctry_glob=("BE","DE","FR","IT","LU","NL","DK","IE","UK","EL","ES","PT","AT","FI","SE","CY","CZ","EE","HU","LT","LV","MT","PL","SI","SK","BG","RO")` 
(since `HR` is missing), while we can change the desired format of the output list (using `_ctrylst_` 
instead of `_ctryclst_`):

~~~sas
	%ctry_define(&zone, &year, _ctrylst_=ctry_glob);
~~~
to return `ctry_glob=BE DE FR IT LU NL DK IE UK EL ES PT AT FI SE CY CZ EE HU LT LV MT PL SI SK BG RO`. 
Let's consider other EU zones in 2015, for instance:

~~~sas
	%let zone=EFTA;
	%let year=2015;
	%ctry_define(&zone, &year, _ctryclst_=ctry_glob);
~~~
returns `ctry_glob=("CH","NO","IS","LI")`, while:

~~~sas
	%let zone=EEA18;
	%ctry_define(&zone, &year, _ctrylst_=ctry_glob);
~~~
returns `ctry_glob=AT BE DE DK EL ES FI FR IE IS IT LU NL NO PT SE UK LI`.

Run macro `%%_example_ctry_define`.

### See also
[%str_isgeo](@ref sas_str_isgeo), [%zone_to_ctry](@ref sas_zone_to_ctry), 
[%ctry_in_zone](@ref sas_ctry_in_zone), [%var_to_clist](@ref sas_var_to_clist).
