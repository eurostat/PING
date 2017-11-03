## ds_export {#sas_ds_export}
Export (convert) a dataset to any format accepted by `PROC EXPORT`.

~~~sas
	%ds_export(ds, odir=, ofn=, _ofn_=, delim=, dbms=, fmt=csv, ilib=WORK);
~~~

### Arguments
* `ds` : a dataset (_e.g._, a SAS file);
* `fmt` : (_option_) format for export; it can be any format (_e.g._, `csv`) accepted by
	the `PROC EXPORT`; default: `fmt=csv`;
* `dbms` : (_option_) value of DBMS key when different from `fmt`; default: indeed, when 
	`dbms` is not passed, it is set to `dbms=&fmt`;
* `delim` : (_option_) delimiter; can be any argument accepted by the `DELIMITER` key in 
	`PROC EXPORT`; default: none is used
* `ilib` : (_option_) input library where the dataset is stored; by default, `WORK` is 
	selected as input library.
 
### Returns
* `ofn` : (_option_) basename of the output exported file; by default (when not passed),	
	it is set to `ds`;
* `odir` : (_option_) output directory/library to store the converted dataset; by default,
	it is set to:
			+ the location of your project if you are using SAS EG (see [%egp_path](@ref sas_egp_path)),
			+ the path of `%sysget(SAS_EXECFILEPATH)` if you are running on a Windows 
			server,
			+ the location of the library passed through `ilib` (_i.e._, `%sysfunc(pathname(&ilib))`) 
			otherwise;
* `_ofn_` : name (string) of the macro variable storing the complete pathname of the output 
	file: it will look like a name built as: `&odir./&ofn..&fmt`.

### Example
Run macro `%%_example_ds_export` for examples.

### Notes
1. In short, this macro runs:

~~~sas
	PROC EXPORT DATA=&ilib..&idsn OUTFILE="&odir./&ofn..&fmt" REPLACE
	   DBMS=&dbms
	   DELIMITER=&delim;
   	quit;
	%let _ofn_=&odir./&ofn..&fmt;	
~~~
2. There is no format/existence checking, hence if the output selected type `fmt` is the 
same as the type of the input dataset, or if the output dataset already exists, a new dataset 
will be produced anyway. Please consider using the setting `G_PING_DEBUG=1` for checking 
beforehand actually exporting.
3. In debug mode (_e.g._, `G_PING_DEBUG=1`), the export operation is aborted; still it can 
be checked that the output file will be correctly created, _i.e._ with the correct name and 
location using the option `_ofn_`. Consider using this option for checking before actually 
exporting. 
4. In the case `fmt=dta` (Stata native format), the parameter `dbms` is set to `PCFS`. 
See example 3: _"Export a SAS dataset on UNIX to a Stata file on Microsoft Windows"_ of 
this 
[webpage](https://support.sas.com/documentation/cdl/en/acpcref/63184/HTML/default/viewer.htm#a003103776.htm);
also check this [webpage](http://stats.idre.ucla.edu/other/mult-pkg/faq/how-do-i-use-a-sas-data-file-in-stata/).

### See also
[%ds_check](@ref sas_ds_check), [%file_import](@ref sas_file_import),
[EXPORT](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/a000393174.htm).
