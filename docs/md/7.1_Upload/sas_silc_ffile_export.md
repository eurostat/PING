## silc_ffile_export {#sas_silc_ffile_export}
Generate a flat file from a SILC indicator dataset to be uploaded on Eurobase. 

~~~sas
	%silc_ffile_export(idsn, geo, years, idir=, ilib=, ofn=, odir=, 
						key=, headkeys=, prefkey=ILC, mode=RECORDS);
~~~

### Arguments
* `idsn` : a SILC dataset;
* `geo` : a list of countries or a geographical area; default: `geo=EU28`; 
* `years` : a list of year(s) of interest;
* `ilib` : (_option_) name of the input library; by default, when not set, `ilib=WORK`;
* `idir` : (_option_) name of the input directory; incompatible with `ilib`;
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
Run `%%_example_silc_ffile_export` for examples.

### Note
The indicator is "SILC-formatted" _e.g._ it is structured in such a way that it has/could have
been created using the macro [%silc_ind_create](@ref sas_silc_ind_create).

### See also
[%silc_ind_create](@ref sas_silc_ind_create), [%silc_ind_info](@ref sas_silc_ind_info), 
[%ds_contents](@ref sas_ds_contents), [%obs_count](@ref sas_obs_count), 
[%var_to_list](@ref sas_var_to_list).
