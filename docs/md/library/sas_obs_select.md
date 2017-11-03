## obs_select {#sas_obs_select}
Select a given observation/set of observations in a dataset.

~~~sas
	%obs_select(idsn, odsn, var=, where=, ilib=WORK, olib=WORK);
~~~

### Arguments
* `idsn` : a dataset reference;
* `var` : (_option_) list of fields/variables of `idsn` upon which the extraction is performed; 
	default: `var` is empty and all variables are selected; 
* `where` : (_option_) expression used to refine the selection (`WHERE` option); should be 
	passed with `%%str`; default: empty;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used;
* `olib` : (_option_) name of the output library; by default: empty, _i.e._ `WORK` is also used.

### Returns
* `odsn` : name of the output dataset (in `WORK` library); it will contain the selection 
	operated on the original dataset;

### Examples
Let us first  consider test dataset #34:
geo | year | ivalue
:--:|:----:|------:
EU27|  2006|   1
EU25|  2004|   2
EA13|  2001|   3
EU27|  2007|   4
... |  ... |  ...
then by the condition one or more rows are selected from the dataset, _e.g._ using the 
instructions below:

~~~sas
	%let var=geo;
    %let obs=EA13;
    %obs_select(_dstest34, TMP, where=%str(&var="&obs"));
~~~
so as to store in the output dataset `odsn` the following table:
geo | year | ivalue
:--:|:----:|------:
EA13|  2001|	3

Run `%%_example_obs_select` for more examples.

### See also
[%ds_select](@ref sas_ds_select), [%obs_count](@ref sas_obs_count).
