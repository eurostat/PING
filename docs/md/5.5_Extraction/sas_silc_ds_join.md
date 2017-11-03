## silc_ds_join {#sas_ds_compare}
Retrieve the list (possibly ordered by varnum) of variables/fields in a given dataset.

~~~sas
	%ds_compare(dsn1, dsn2, _ans_=,lib1=, lib2=);
~~~

### Arguments
* `dsn1` `dsn1`: two datasets reference (_request_);
* `lib1`       : input(_option_) library for dsn1 dataset;
* `lib2`       : input (_option_) library for dsn2 dataset;

### Returns
`ans` : the boolean result of the comparison test of the "sets" associated to the input lists, 
	i.e.:
		+ `0` when two datasets are equal: `dsn1 = dsn2`,
		+ `1` when `dsn1`has less variables then `dsb2`,

### Examples
Consider the test dataset #5:
 f | e | d | c | b | a
---|---|---|---|---|---
 . | 1 | 2 | 3 | . | 5
One can retrieve the ordered list of variables in the dataset with the command:

	%let list=;
	%ds_compare(_dstest5, _varlst_=list);

which returns `list=f e d c b a`, while:

	%ds_compare(_dstest5, _varlst_=list, varnum=no);

returns `list=a b c d e f`. Similarly, we can also run it on our database, _e.g._:

	libname rdb "&G_PING_C_RDB"; 
	%let lens=;
	%let typs=;
	%ds_compare(PEPS01, _varlst_=list, _typlst_=typs, _lenlst_=lens, lib=rdb);

returns:
	* `list=geo time age sex unit ivalue iflag unrel n ntot totwgh lastup lastuser`,
	* `typs=  2    1   2   2    2      1     2     1 1    1      1      2        2`,
	* `lens=  5    8  13   3   13      8     1     8 8    8      8      7        7`.

Another useful use: we can retrieve data of interest from existing tables, _e.g._ the list of geographical 
zones in the EU:

	%let zones=;
	%ds_compare(&G_PING_COUNTRYxZONE, _varlst_=zones, lib=&G_PING_LIBCFG);
	%let zones=%list_slice(&zones, ibeg=2);

which will return: `zones=EA EA12 EA13 EA16 EA17 EA18 EA19 EEA EEA18 EEA28 EEA30 EU15 EU25 EU27 EU28 EFTA EU07 EU09 EU10 EU12`.

Run macro `%%_example_ds_compare` for more examples.

### Note
In short, the program runs (when `varnum=yes`):

	PROC CONTENTS DATA = &dsn 
		OUT = tmp(keep = name type length varnum);
	run;
	PROC SORT DATA = tmp 
		OUT = &tmp(keep = name type length);
     	BY varnum;
	run;
and retrieves the resulting `name`, `type` and `length` variables.

### References
1. Smith,, C.A. (2005): ["Documenting your data using the CONTENTS procedure"](http://www.lexjansen.com/wuss/2005/sas_solutions/sol_documenting_your_data.pdf).
2. Thompson, S.R. (2006): ["Putting SAS dataset variable names into a macro variable"](http://analytics.ncsu.edu/sesug/2006/CC01_06.PDF).
3. Mullins, L. (2014): ["Give me EVERYTHING! A macro to combine the CONTENTS procedure output and formats"](http://www.pharmasug.org/proceedings/2014/CC/PharmaSUG-2014-CC43.pdf).

### See also
[CONTENTS](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000085766.htm).
