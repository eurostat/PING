/** 
## META_VARIABLExVARIABLE {#meta_variablexvariable}
Provide the correspondance table between derived variables and EU-SILC variables.

### Contents
A table named after the value `&G_PING_VARIABLExVARIABLE` (_e.g._, `META_VARIABLExVARIABLE`) 
shall be defined in the library named after the value `&G_PING_LIBCFG` (_e.g._, `LIBCFG`) 
so as to contain the correspondance table between `IDB/PDB/UDB`) so-called derived variables
and EU-SILC input variables (collected and transmitted by countries as used in the various 
databases. 

In practice,                  
 variable  |  lib  | DB010 | DB020 | RB010  | ... |    |      src         
:---------:|:-----:|:-----:|:-----:|:------:|:---------|:---------------:
   AGE     | C_Var |    1  |       |   1    |  .. |    |  idb_calculation        
   AGE     | E_Var |    1  |       |   1    |  .. |    |  idb_calculation 
   ...     |  ...  |  ...  |  ...  |  ...   | ... | ...|  ...             

In addition to information regargin library location and source/program name, the table contains
for each derived variable (single row of the first column) the list of variables (derived or not, 
in the columns) involved in its calculation. 

The syntax used to encode the usage of column variables in the calculation of row/derived
variables is the one used for creating format, _i.e._: 
* `y`, if the variable is used in the calculation of the derived variable in year `y` only, or
* `ys<`, if it used from year `ys+1` on (year `ys` excluded), or 
* `ys<-`, if it used from year `ys` on, or 
* `<ye`, if it used till year `ye-1` (year `ye` excluded), or
* `-<ye`, if it used till year `ye`.

In addition, periods/ranges of year are encoded in the following manner:
* `ys-ye`, if it used from year `ys` to year `ye` (both years included), or
* `ys<-ye`, if it used from year `ys+1` to year `ye` (year `ys` excluded), or 
* `ys-<ye`, if it used from year `ys` to year `ye-1` (year `ye` excluded), or
* `ys<-<ye`, if it used from year `ys+1` to year `ye-1` (both years excluded).

Another special label is created:
* `1` if the column variable is (has been) always used in the calculation of the row variable.

Otherwise, the following encoding is available: 
* `.` or empty, if the column variable is never used in the calculation of the row variable.

Moreover, it is possible to join different such rules together since a variable may be used over
different periods. For that purpose, the comma is used to separate the rules, _e.g._:
* `y1, y2-<y3`, if the variable has been used in the calculation of the derived variable in year `y1`
and from year `y2` to `y3-1` (`y3` excluded).

### Creation and update
Consider an input CSV table called `A.csv`, with same structure as above, and stored in a directory 
named `B`. In order to create/update the SAS table `A` in library `C`, as described above, it is 
then enough to run:

~~~sas
	%meta_variablexvariable(cds_varxvar=A, cfg=B, clib=C);
~~~
Note that, by default, the command `%%meta_variablexvariable;` runs:

~~~sas
	%meta_variablexvariable(cds_varxind=&G_PING_VARIABLExVARIABLE, 
						cfg=&G_PING_EXTRACTION/config, 
						clib=&G_PING_LIBCFG);
~~~

### Example
Generate the table `META_VARIABLExVARIABLE` in the `WORK` directory:

~~~sas
	%meta_variablexvariable(clib=WORK);
~~~

### References
1. Eurobase [online dictionary](http://ec.europa.eu/eurostat/estat-navtree-portlet-prod/BulkDownloadListing?sort=1&dir=dic%2Fen).
2. Mack, A. (2016): ["Data Handling in EU-SILC"](http://www.gesis.org/fileadmin/upload/forschung/publikationen/gesis_reihen/gesis_papers/2016/GESIS-Papers_2016-10.pdf).

### See also
[%silc_ind_info](@ref sas_silc_ind_info), [%meta_variablexindicator](@ref meta_variablexindicator),
[%meta_indicator_contents](@ref meta_indicator_contents).
*/ /** \cond */

/* credits: grazzja, grillma */

%macro meta_variablexvariable(cds_varxvar=, cfg=, clib=);
	%put G_PING_VARIABLExVARIABLE=&G_PING_VARIABLExVARIABLE;

	%if %macro_isblank(cds_varxvar) %then %do;
		%if %symexist(G_PING_VARIABLExVARIABLE) %then 	%let cds_varxvar=&G_PING_VARIABLExVARIABLE;
		%else											%let cds_varxvar=META_VARIABLExVARIABLE;
	%end;
	
	%if %macro_isblank(clib) %then %do;
		%if %symexist(G_PING_LIBCFG) %then 			%let clib=&G_PING_LIBCFG;
		%else										%let clib=LIBCFG/*SILCFMT*/;
	%end;

	%if %macro_isblank(cfg) %then %do;
		%if %symexist(G_PING_EXTRACTION) %then 		%let cfg=&G_PING_EXTRACTION/meta;
		%else										%let cfg=&G_PING_ROOTPATH/5.5_Extration/meta;
	%end;

	%local FMT_CODE;
	%if %symexist(G_PING_FMT_CODE) %then       		%let FMT_CODE=&G_PING_FMT_CODE;
	%else									    	%let FMT_CODE=csv;
 
	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%file_import(&cds_varxvar, fmt=&FMT_CODE, _ods_=&cds_varxvar, 
				idir=&cfg, olib=&clib, getnames=yes, guessingrows=_MAX_);

%mend meta_variablexvariable;


%macro _example_meta_variablexvariable;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%put;
	%put (i) Create the table &G_PING_VARIABLExVARIABLE with variable<=>indicator correspondances in WORK library; 
	%meta_variablexvariable(clib=WORK);
	%ds_print(&G_PING_VARIABLExVARIABLE);

	%put;
%mend _example_meta_variablexvariable;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_meta_variablexvariable;
*/

/** \endcond */
