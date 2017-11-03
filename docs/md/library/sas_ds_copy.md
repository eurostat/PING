## ds_copy {#sas_ds_copy}
Create a working copy of a given dataset.

~~~sas
	%ds_copy(idsn, odsn, where=, groupby=, having=, mirror=COPY, ilib=WORK, olib=WORK);
~~~

### Arguments
* `idsn` : a dataset reference;
* `groupby, where, having` : (_option_) expressions used to refine the selection when `mirror=COPY`,
	like in a `SELECT` statement of `PROC SQL` (`GROUP BY, WHERE, HAVING` clauses); these options are
	therefore incompatible with `mirror=LIKE`; note that `where` and `having` should be passed with 
	`%%quote`; see also [%ds_select](@ref sas_ds_select); default: empty;
* `mirror` : (_option_) type of `copy` operation used for creating the working dataset, _i.e._ either
	an actual copy of the table (`mirror=COPY`) or simply a copy of its structure (_i.e._, the output 
	table is shaped like the input ones, with same variables: `mirror=LIKE`); default: `mirror=COPY`; 
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.
  
### Returns
* `odsn` : name of the output dataset (in `WORK` library) where a copy of the original dataset or its
	structure is stored;
* `olib` : (_option_) name of the output library; by default: empty, _i.e._ `WORK` is used.

### Example
For instance, we can run:

~~~sas
	%ds_copy(idsn, odsn, mirror=COPY, where=%quote(var=1000));
~~~
so as to retrieve:

~~~sas
	DATA WORK.&odsn;
		SET &ilib..&idsn;
		WHERE &var=1000; 
	run; 
~~~

See `%%_example_ds_copy` for more examples.

### Note
The command `%ds_copy(idsn, odsn, mirror=COPY, ilib=ilib, olib=olib)` consists in running:

~~~sas
	DATA &olib..&odsn;
		SET &ilib..&idsn;
	run; 
~~~
while the command `%ds_copy(idsn, odsn, mirror=LIKE, ilib=ilib, olib=olib)` is equivalent to:

~~~sas
	PROC SQL noprint;
		CREATE TABLE &olib..&odsn like &ilib..&idsn; 
	quit; 
~~~

### See also
[%ds_select](@ref sas_ds_select).
