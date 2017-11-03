/** 
## META_VARIABLE_DIMENSION {#meta_variable_dimension}
Provide the correspondance table between EU-SILC variables and Eurobase equivalent dimensions.

### Contents
A table named after the value `&G_PING_VARIABLE_DIMENSION` (_e.g._, `META_VARIABLE_DIMENSION`) shall 
be defined in the library named after the value `&G_PING_LIBCFG` (_e.g._, `LIBCFG`) so as to contain 
the correspondance table between EU-SILC variables (as used in the various databases: `IDB/PDB/UDB`) 
and Eurobase equivalent dimensions (as defined in the dictionary of dimensions), as well as their 
respective formats (type, length). 

In practice, the table looks like this:
 variable |	dimension |	  type	 |  length
:--------:|:---------:|:--------:|:--------:
  DB020   |    GEO	  |   char   |	  5
  DB030   |   TIME	  |  numeric |	  4
  AGE     |    AGE	  |   char   |	  15
  RB090   |    SEX	  |   char   |	  15
  HT1     |  HHTYP	  |   char   |	  15
  ...     |    ...    |    ...   |   ...  
     
### Creation and update
Consider an input CSV table called `A.csv`, with same structure as above, and stored in a directory 
named `B`. In order to create/update the SAS table `A` in library `C`, as described above, it is 
then enough to run:

	%meta_variable_dimension(cds_var_dim=A, cfg=B, clib=C);

Note that, by default, the command `%%meta_variable_dimension;` runs:

	%meta_variable_dimension(cds_var_dim=&G_PING_VARIABLE_DIMENSION, 
					cfg=&G_PING_ESTIMATION/meta, 
					clib=&G_PING_LIBCFG);

### Example
Generate the table `META_VARIABLE_DIMENSION` in the `WORK` directory:

	%meta_variable_dimension(clib=WORK);

### References
1. Eurobase [online dictionary](http://ec.europa.eu/eurostat/estat-navtree-portlet-prod/BulkDownloadListing?sort=1&dir=dic%2Fen).
2. Mack, A. (2016): ["Data Handling in EU-SILC"](http://www.gesis.org/fileadmin/upload/forschung/publikationen/gesis_reihen/gesis_papers/2016/GESIS-Papers_2016-10.pdf).

### See also
[%meta_variablexindicator](@ref meta_variablexindicator), [%meta_indicator_contents](@ref meta_indicator_contents).
*/ /** \cond */

/* credits: grazzja, grillma */

%macro meta_variable_dimension(cds_var_dim=, cfg=, clib=);

	%if %macro_isblank(cds_var_dim) %then %do;
		%if %symexist(G_PING_VARIABLE_DIMENSION) %then 	%let cds_var_dim=&G_PING_VARIABLE_DIMENSION;
		%else											%let cds_var_dim=META_VARIABLE_DIMENSION;
	%end;
	
	%if %macro_isblank(clib) %then %do;
		%if %symexist(G_PING_LIBCFG) %then 			%let clib=&G_PING_LIBCFG;
		%else										%let clib=LIBCFG/*SILCFMT*/;
	%end;

	%if %macro_isblank(cfg) %then %do;
		%if %symexist(G_PING_ESTIMATION) %then 		%let cfg=&G_PING_ESTIMATION/meta;
		%else										%let cfg=&G_PING_ROOTPATH/5.5_Estimation/meta;
	%end;

	%local FMT_CODE;
	%if %symexist(G_PING_FMT_CODE) %then 		%let FMT_CODE=&G_PING_FMT_CODE;
	%else										%let FMT_CODE=csv;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%file_import(&cds_var_dim, fmt=&FMT_CODE, idir=&cfg, olib=&clib, 
		getnames=yes, guessingrows=_MAX_);

%mend meta_variable_dimension;


%macro _example_meta_variable_dimension;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc/PING; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%put;
	%put (i) Create the table &G_PING_VARIABLE_DIMENSION with variable<=>dimension correspondances in WORK library; 
	%meta_variable_dimension(clib=WORK);
	%ds_print(&G_PING_VARIABLE_DIMENSION);

	%put;
%mend _example_meta_variable_dimension;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_meta_variable_dimension;
*/

/** \endcond */
