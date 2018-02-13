/** 
## ffile_export {#sas_ffile_export}
Generate a flat file from a dataset to be uploaded on Eurobase. 
~~~sas
	%ffile_export(idsn, dimensions, values, domain, table, type, count, idir=, ilib=, ofn=, odir=,
				  digits=, rounding=, flags=, threshold_n = 30);
~~~
### Arguments
* `idsn` : a dataset to be uploaded;
* `dimensions` : a list containing the different dimensions, describing the different 
values taken by each dimension. Please report to Examples for more details;
* `values` : name of the column in the data giving the values to be disseminated;
* `ilib` : (_option_) name of the input library; by default, when not set, `ilib=WORK`;
* `key` : (_option_) name of the key used to indentified the indicator; when not passed, it
	is set to `&idsn`;
* `prefkey` : (_option_) prefix string for the identification of the published dataset; it is
	used before the indicator key of the disseminated dataset; for instance, for an indicator 
	named `<IND>` to be identified in Eurobase tree node as `ILC_<IND>`, `prefkey` should be 
	set to `ILC` so that the field ID keys in the flat file will appear as:
~~~sas
			`FIELDS=ILC_<IND>`
~~~
	note the use of `_EMPTY_` to set `prefkey` to a blank string; by default, it is set to: 
	`prefkey=ILC`;
* `headkeys` : (_option_) head keys (strings) used for the identification of the published 
	dataset; for instance, for an indicator named `<IND>` to be identified in Eurobase tree 
	node as `SAS.ILC.<IND>`, `headkeys` should be set to `SAS ILC` so that the field ID keys 
	in the flat file will appear as: 
~~~sas
			`FIELDS=SAS,ILC,<IND>`
~~~
	by default, it is not set: `headkeys=`;
* `mode` : (_option_) mode of upload; by default, when not set, `mode=RECORDS`.
### Returns
* `ofn` : (_option_) name of the output (text) file (without the txt extension); by default, 
	when not set, `ofn` is built from the input name `&idsn` and the input year(s) `&years`;
* `odir` : (_option_) name of the output directory; by default, `odir=%sysfunc(pathname(&ilib))`.
### Example
Run `%%_example_ffile_export` for examples.
### Note
The indicator is "SILC-formatted" _e.g._ it is structured in such a way that it has/could have
been created using the macro [%silc_ind_create](@ref sas_silc_ind_create).
### See also
[%silc_ind_create](@ref sas_silc_ind_create), [%silc_ind_info](@ref sas_silc_ind_info), 
[%ds_contents](@ref sas_ds_contents), [%obs_count](@ref sas_obs_count), 
[%var_to_list](@ref sas_var_to_list).
*/ /** \cond */

/* credits: pierre-lamarche */

%macro ffile_export(idsn /* name of the input dataset */
					, dimensions
					, values
					, domain, table, type, count, ilib=, ofn=, odir=,
				  	digits=, rounding=, flags=, threshold_n = 30);

%local _mac;
%let _mac=&sysmacroname;
%let _=%macro_put(&_mac);

%if &ofn= %then %let ofn = &table ;

/* check the existence of idsn */
%if %error_handle(ErrorInputParameter,
				  %macro_isblank(idsn), mac=&_mac,
				  txt = !!! The input data needs to be set !!!) %then
				  %goto exit;
%if &ilib= %then %let ilib = WORK ;
%if %error_handle(ErrorInputParameter,
				 %ds_check(&idsn, lib = &ilib) ne 0, mac=&_mac,
				 txt = !!! Then input data cannot be found !!!) %then
				 %goto exit ;

%mend ;