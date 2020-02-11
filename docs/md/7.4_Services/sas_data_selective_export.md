## data_selective_export {#sas_data_selective_export}
Perform selective export of a dataset to any format accepted by `PROC EXPORT`.

~~~sas
	%data_selective_export(idsn, time=, geo=, idir=, ilib=, odir=, _ofn_=, fmt=csv);
~~~

### Arguments
* `idsn` : input dataset(s) to export;
* `geo` : (_option_) a list of countries or a geographical area; default: `geo=`, or 
	`geo=_ALL_VALUES_`, so that the whole dataset will be exported; in practice, a `where` 
	clause is created using this list; 
* `time` : (_option_) year(s) of interest; default: `time=`, or `time=_ALL_VALUES_`, so that 
	the whole dataset will be exported; ibid `geo`;
* `idir` : (_option_) name of the input directory where to look for input datasets, passed 
	instead of `ilib`; incompatible with `ilib`; by default, `ilib` will be set to the current 
	directory; 
* `ilib` : (_option_) name of the input library where to look for input datasets; incompatible 
	with `idir`; by default, it is not used.

### Returns
* `_ofn_` : (_option_) name (string) of the macro variable storing the output exported file 
	name(s);
* `odir` : (_option_) output directory/library to store the converted dataset; by default,
	it is set to:
			+ the location of your project if you are using SAS EG (see [%egp_path](@ref sas_egp_path)),
			+ the path of `%sysget(SAS_EXECFILEPATH)` if you are running on a Windows server,
			+ the location of the library passed through `ilib` (_i.e._, `%sysfunc(pathname(&ilib))`) 
			otherwise.

<img src="img/data_selective_export.png" border="1" width="60%" alt="interface of the data selective export service">

### See also
[%ds_export](@ref sas_ds_export), [%ds_select](@ref sas_ds_select).
