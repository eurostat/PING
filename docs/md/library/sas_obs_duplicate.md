## obs_duplicate {#sas_obs_duplicate}
Extract duplicated/unique observations from a given dataset.

~~~sas
	%obs_duplicate(idsn, dim=, dupdsn=, unidsn=, select=, ilib=WORK, olib=WORK);
~~~

### Arguments
* `idsn` : a dataset reference;
* `dim` : (_option_) list of fields/variables of `idsn` ; 
* `select` : (_option_) expression used to refine the selection (`WHERE` option); should be 
	passed with `%%str`; default: empty;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used;
* `olib` : (_option_) name of the output library; by default: empty, _i.e._ `WORK` is also used.

### Returns
* `dupdsn` : name of the output dataset with duplicated observations; it will contain the selection 
	operated on the original dataset;
* `unidsn` : name of the output dataset with unique observations.

### Examples

* ### References
1. Note on ["FIRST. and LAST. variables"](http://www.albany.edu/~msz03/epi514/notes/first_last.pdf).
2. Note on ["Working with grouped observations"](http://www.cpc.unc.edu/research/tools/data_analysis/sastopics/bygroups).
3. ["How the DATA step identifies BY groups"](http://support.sas.com/documentation/cdl/en/lrcon/62955/HTML/default/viewer.htm#a000761931.htm).
4. Cai, E. (2015): ["Getting all Duplicates of a SAS data set"](https://chemicalstatistician.wordpress.com/2015/01/05/getting-all-duplicates-of-a-sas-data-set/).
5. Cai, E. (2015): ["Separating unique and duplicate observations using PROC SORT in SAS 9.3 and newer versions"](https://chemicalstatistician.wordpress.com/2015/04/10/separating-unique-and-duplicate-variables-using-proc-sort-in-sas-9-3-and-newer-versions/).

### See also
[%obs_select](@ref sas_obs_select), [%ds_isempty](@ref sas_ds_isempty), [%ds_check](@ref sas_ds_check),
[%sql_clause_by](@ref sas_sql_clause_by), [%sql_clause_as](@ref sas_sql_clause_as), [%ds_select](@ref sas_ds_ select), 
[SELECT ](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a002473678.htm).
