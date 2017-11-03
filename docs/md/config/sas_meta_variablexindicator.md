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
