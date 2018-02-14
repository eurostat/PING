/** 
## ffile_export {#sas_ffile_export}
Generate a flat file from a dataset to be uploaded on Eurobase. 
~~~sas
	%ffile_export(idsn, dimensions, values, domain, table, type, count, ilib=, ofn=, odir=, replace=FALSE,
				  digits=, rounding=, flags=, threshold_n = 30);
~~~
### Arguments
* `idsn` : a dataset to be uploaded;
* `dimensions` : a list containing the different dimensions, describing the different 
values taken by each dimension. Please report to Examples for more details;
* `values` : name of the column in the data giving the values to be disseminated;
* `domain` : name of the domain, to be included in the header of the file;
* `table` : name of the table, to be included in the header of the file;
* `type` : type of the file to be produced. Either DFT ("DFT") or flat/txt ("FLAT");
* `ofn` : name of the file to be produced. By default, the file takes the name of the table;
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
					, dimensions /* dimensions for the exportation on Eurobase */
					, values /* name of the variable giving the values */
					, domain
					, table
					, type
					, count
					, ilib=
					, ofn=
					, odir=
					, replace=FALSE
				  	, digits=
					, rounding=
					, flags=
					, threshold_n=30
					, mode=);

%local _mac;
%let _mac=&sysmacroname;

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

/* check the existence of dimensions in idsn */
%if %error_handle(ErrorInputParameter,
				  %macro_isblank(dimensions), mac=&_mac,
				  txt = !!! Parameter dimensions needs to be set !!!) %then
				  %goto exit;
%let check_dim = %var_check(dsn = &idsn, var = &dimensions, lib = &ilib) ;
%if %error_handle(ErrorInput,
				  %index(&check_dim, 1) > 0, mac=&_mac,
				  txt = !!! Some dimensions are missing in the input data !!!) %then
				  %goto exit ;

/* check the existence of value */
%if %error_handle(ErrorInputParameter,
				  %macro_isblank(values), mac=&_mac,
				  txt = !!! Parameter values needs to be set !!!) %then
				  %goto exit;
%if %error_handle(ErrorInput,
				  %var_check(dsn = &idsn, var = &values, lib = &ilib) EQ 1, mac = &_mac,
				  txt = !!! Variable &values is missing in the input data !!!) %then 
				  %goto exit ;

/* check the existence of count */
%if %error_handle(ErrorInputParameter,
				  %macro_isblank(count), mac=&_mac,
				  txt = !!! Parameter count needs to be set !!!) %then
				  %goto exit;
%if %error_handle(ErrorInput,
				  %var_check(dsn = &idsn, var = &count, lib = &ilib) EQ 1, mac = &_mac,
				  txt = !!! Variable &count is missing in the input data !!!) %then 
				  %goto exit ;

/* check the existence of flags */
%if %macro_isblank(flags) = 0 %then %do ;
	%if %error_handle(ErrorInput,
					  %var_check(dsn = &idsn, var = &flags, lib = &ilib) EQ 1, mac = &_mac,
					  txt = !!! Variable &flags is missing in the input data !!!) %then 
					  %goto exit ;
%end ;

/* check the value taken by type */
%let type_possible = DFT FLAT ;
%if %error_handle(ErrorInputParameter,
				  %list_find(&type_possible, &type) EQ , mac = &_mac,
				  txt = !!! Wrong type for the output data !!!) %then
				  %goto exit ;

/* assigning a value to mode and checking the validity of the parameter */
%if %macro_isblank(mode) %then %do ;
	%if &type = FLAT %then %let mode = RECORDS ;
	%else %let mode = MERGE ;
%end ;

/* checking the existence of the output folder */
%if %macro_isblank(odir) %then %let odir = %sysfunc(pathname(work)) ;
%if %error_handle(ErrorInputParameter,
				  %dir_check(&odir) EQ 1, mac = &_mac,
				  txt = !!! The output directory does not exist !!!) %then
				  %goto exit ;

/* checking the existence of the output file */
%if &type = DFT %then %let ext = dft ;
%else %let ext = txt ;
%if %file_check(&odir./&ofn..&ext) EQ 0 %then %do ;
	%if &replace = FALSE %then %do ;
		%put %nrstr(!!! The output file already exists; it will not be replaced !!!) ;
		%goto exit ;
	%end ;
	%else %do ;
		%put WARNING: The output file already exists and it will be crashed. ;
	%end ;
%end ;

data _temp_ ;
set &ilib..&idsn ;
keep &dimensions &values &flags &count ;
run ;

data _temp_ ;
set _temp_ ;
%if %macro_isblank(rounding) = 1 %then 
	values = put(round(&values, 10**(-%eval(&digits))), 20.);
%else values = put(round(&values/10**&rouding, 0)*10**rounding, 20.) ;
;
if missing(&flags) = 0 then values = trim(values)!!"~"!!left(&flags) ;
if &count < &threshold_n then values = ":~n" ;
run ;

/* TODO: expand all possible combinations of dimensions */

%if &type = FLAT %then %do ;

data _temp_ ;
set _temp_ end=eof ;
file "&odir./&ofn..txt" LRECL=32000 TERMSTR=crlf ;
if _n_ = 1 then do ;
put "FLAT_FILE=STANDARD" ;
put "ID_KEYS=&domain._&table" ;
put "FIELDS=%list_quote(&dimensions, mark = _EMPTY_)" ;
put "UPDATE_MODE=&mode" ;
end ;
put &dimensions values ;
if eof then do ;
put "END_OF_FLAT_FILE" ;
end ;
run ;

%end ;
%else %do ;

/* todo */

%end ;

%exit:

%mend ;

%let outputdir =  ; /* put here a path to run the examples */

%macro _example_ffile_export ;

options nomprint nosource nonotes ;
%_dstest37 ;
data _dstest37 ;
set _dstest37 ;
vl = ranuni(0)*50 ;
count = ranuni(0)*75 + 25 ;
flag = "e" ;
run ;

%put ********** TEST 1 ;
%ffile_export(idsn = _dstest37, dimensions = geo time eq_inc20 rb050a, values = vl, domain = test, table = sc_01, type = FLAT, count = count,
odir = &outputdir, digits = 0, flags = flag, mode = RECORDS) ;
%put ********** TEST 2 ;
%ffile_export(idsn = _dstest37, dimensions = geo time eq_inc20 rb050a, values = vl, domain = test, table = sc_01, type = FLAT, count = count,
odir = &outputdir, digits = 0, flags = flag, mode = RECORDS) ;
%put ********** TEST 3 ;
%ffile_export(idsn = _dstest37, dimensions = geo time eq_inc20 rb050a, values = vl, domain = test, table = sc_01, type = FLAT, count = count,
odir = &outputdir, digits = 0, flags = flag, mode = RECORDS, replace = TRUE) ;

options source notes ;

%mend ;

%_example_ffile_export ;
