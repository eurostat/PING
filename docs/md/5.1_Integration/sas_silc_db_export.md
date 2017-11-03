## silc_db_export {#sas_silc_db_export}
Export EU-SILC bulk datasets from SAS format (`.sas7bdat`) to any format supported by `PROC FORMAT`.

~~~sas
	%silc_db_export(survey, time, geo=, db=, src=, _ds_=, _path_=, 
					cds_transxyear=META_TRANSMISSIONxYEAR, clib=LIBCFG);
~~~

### Arguments
* `survey` : type of the survey; this is represented by any of the character values defined in the 
	global variable `G_PING_SURVEYTYPES`, _i.e._ as:
		+ `X`. `C` or `CROSS` for a cross-sectional survey,
		+ `L` or `LONG` for a longitudinal survey,
		+ `E` or `EARLY` for an early survey,
* `time` : a single selected year of interest; 
* `geo` : string(s) representing the ISO-code(s) of (a) country(ies); note that when `geo`is not 
	passed and `src=raw` (see below), the output parameters `_path_` and `_ds_` cannot be defined: 
	only `_ftyp_` can be returned (see below); in all other cases, `geo` is ignored;
* `db` : (_option_) database(s) to retrieve; it can be any of the character values defined through 
	the global variable `G_PING_BASETYPES`, _i.e._:
		+ `D` for household register/D file,
		+ `H` for household/H file,
		+ `P` for personal register/P file,
		+ `R` for register/R file,
	so as to represent the corresponding bulk databases (files); by default,`db=&G_PING_BASETYPES`; 
* `src` : (_option_) string defining the source location where to look for bulk database; this can 
	be either the full path of the directory where to search in, or any of the following strings:
		+ `bdb`, ibid with the value of `G_PING_BDB`,
		+ `pdb`, ibid with the value of `G_PING_PDB`,
		+ `idb`, ibid with the value of `G_PING_IDB`,
		+ `udb`, ibid with the value of `G_PING_UDB`;
	note that the latter four cases are independent of the parameter chosen for `geo`;	note also
	that `src=bdb` and `src=idb` are incompatible with `survey<>X`; furthermore, when `src=idb`, 
	the parameter `db` is ignored; by default, `src` is set to the value of `G_PING_RAWDB` (_e.g._ 
	`&G_PING_ROOTPATH/main`) so as to look for raw data;
* `cds_transxyear, clib` : (_options_) configuration file storing the the yearly definition of
	microdata transmission files' format, and library where it is actually stored; for further 
	description of the table, see [%meta_transmissionxyear](@ref meta_transmissionxyear) and 
	[%silc_db_locate](@ref sas_silc_db_locate).

### Returns
* `_ofn_` : name (string) of the macro variable storing the output exported file name.
* `odir` : (_option_) output directory/library to store the converted dataset; by default,
	it is set to:
			+ the location of your project if you are using SAS EG (see [%egp_path](@ref sas_egp_path)),
			+ the path of `%sysget(SAS_EXECFILEPATH)` if you are running on a Windows server,
			+ the location of the library passed through `ilib` (_i.e._, `%sysfunc(pathname(&ilib))`) 
			otherwise;

## Example
Let us export some bulk datasets from the so-called BDB into Stata native format (`dta`):

~~~sas
	%let survey=CROSS;
	%let time=2015;
	%let src=BDB;
	%let db=D H R;
	%let fmt=dta;
	%let odir=&G_PING_ROOTPATH;
	%silc_db_export(CROSS, 2015, odir=&odir, _ofn_=ofn, fmt=&fmt, db=&db, src=&src);
~~~

On our current system (see _G_PING_ROOTPATH_ definition), the following output files will be created:
* /ec/prod/server/sas/0eusilc/bdb_c15d.dta
* /ec/prod/server/sas/0eusilc/bdb_c15h.dta
* /ec/prod/server/sas/0eusilc/bdb_c15r.dta
	
### See also
[%silc_ds_extract](@ref sas_silc_ds_extract), [%silc_db_locate](@ref sas_silc_db_locate),
[%ds_export](@ref sas_ds_export), [%meta_transmissionxyear](@ref meta_transmissionxyear).