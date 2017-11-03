/** 
## META_VARIABLExINDICATOR {#meta_variablexindicator}
Provide the correspondance table between EU-SILC variables and Eurobase indicators.

### Contents
A table named after the value `&G_PING_VARIABLExINDICATOR` (_e.g._, `META_VARIABLExINDICATOR`) 
shall be defined in the library named after the value `&G_PING_LIBCFG` (_e.g._, `LIBCFG`) 
so as to contain the correspondance table between EU-SILC variables (as used in the various 
databases: `IDB/PDB/UDB`) and indicators. 

In practice, the table looks like this:
 indicator |  survey   | lib | AGE | RB090 | ARPTXX | EQ_INC20 | ... | weight | description
:---------:|:---------:|:---:|----:|------:|:------:|:--------:|:---:|:------:|:---------------------------------------------------------
   DI01    | ECHP-SILC | RDB |     |       |        |     1    | ... | RB050a | Distribution of income by quantiles      
   DI02    | ECHP-SILC | RDB |     |       |    1   |		   | ... | RB050a | Distribution of income by different income groups             
   DI03    | ECHP-SILC | RDB |  1  |   1   |        |	  1    | ... | RB050a | Mean and median income by age and gender       
   DI04    | ECHP-SILC | RDB |  1  |   1   |        |	  1    | ... | RB050a | Mean and median income by household type        
   DI05    | ECHP-SILC | RDB |  1  |   1   |        |	  1    | ... | PB040  | Mean and median income by most frequent activity status   
   ...     |    ...    | ... | ... |  ...  |   ...  |    ...   | ... |  ...   | ...
In particular, it contains for each indicator present in the table (besides information about 
survey, storage library and description) the format identifiers (represented as numbers) used 
by the variables it depends upon, as well as the weight it uses . The definition of the formats 
associated to a given variable `XX` can be found in the configuration tables `META_LABELVALUExFORMAT_XX` 
of the `&G_PING_LIBCFG` library. 
  
### Creation and update
Consider an input CSV table called `A.csv`, with same structure as above, and stored in a directory 
named `B`. In order to create/update the SAS table `A` in library `C`, as described above, it is 
then enough to run:

	%meta_variablexindicator(cds_varxind=A, cfg=B, clib=C);

Note that, by default, the command `%%meta_variablexindicator;` runs:

	%meta_variablexindicator(cds_varxind=&G_PING_VARIABLExINDICATOR, 
						cfg=&G_PING_ESTIMATION/meta, 
						clib=&G_PING_LIBCFG);

### Example
Generate the table `META_VARIABLExINDICATOR` in the `WORK` directory:

	%meta_variablexindicator(clib=WORK);

### References
1. Eurobase [online dictionary](http://ec.europa.eu/eurostat/estat-navtree-portlet-prod/BulkDownloadListing?sort=1&dir=dic%2Fen).
2. Mack, A. (2016): ["Data Handling in EU-SILC"](http://www.gesis.org/fileadmin/upload/forschung/publikationen/gesis_reihen/gesis_papers/2016/GESIS-Papers_2016-10.pdf).

### See also
[%silc_ind_info](@ref sas_silc_ind_info), [%meta_indicator_contents](@ref meta_indicator_contents).
*/ /** \cond */

/* credits: grazzja, grillma */

%macro meta_variablexindicator(cds_varxind=, cfg=, clib=);

	%if %macro_isblank(cds_varxind) %then %do;
		%if %symexist(G_PING_VARIABLExINDICATOR) %then 	%let cds_varxind=&G_PING_VARIABLExINDICATOR;
		%else											%let cds_varxind=META_VARIABLExINDICATOR;
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
	%if %symexist(G_PING_FMT_CODE) %then       		%let FMT_CODE=&G_PING_FMT_CODE;
	%else									    	%let FMT_CODE=csv;
    
	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%file_import(&cds_varxind, fmt=&FMT_CODE, idir=&cfg, olib=&clib, 
		getnames=yes, guessingrows=_MAX_);

%mend meta_variablexindicator;


%macro _example_meta_variablexindicator;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc/PING; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%put;
	%put (i) Create the table &G_PING_VARIABLExINDICATOR with variable<=>indicator correspondances in WORK library; 
	%meta_variablexindicator(clib=WORK);
	*%ds_print(&G_PING_VARIABLExINDICATOR);

	%put;
%mend _example_meta_variablexindicator;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_meta_variablexindicator;
*/


/** \endcond */
