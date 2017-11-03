## var_set {#sas_var_set}
Add variable(s) to a dataset and initialize it/them to some value(s). 

~~~sas
    %var_set(idsn, var=, val=, odsn=, force_set=, ilib=WORK, olib=WORK);
~~~

### Arguments
* `idsn` : input reference dataset, where variables shall be inserted;
* `var` : (_option_) list of variables that should be inserted; 
* `val` : (_option_) list of values that should be used to inizialize the inserted
	variables; the number of arguments passed in `var` and `val` MUST be the same;
* `force_set` : (_option_) boolean flag (`yes/no`) set to force the initialisation
	of the variable passed in `var`:
		+ `yes`: the variable in `var` is/are initialised whether it/they already
		exist/s in the dataset or not,
    	+ `no`: the variable in `var` is/are initialised only when it is added to
		the dataset;

	default: `force_set=no` is used;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is 
	used.

### Returns
* `odsn` : (_option_) name of the output dataset (stored in the `olib` library), that 
	will contain the  data from `idsn`, plus the new variables inserted; default: 
	`odsn=idsn` and the input dataset `idsn` is updated instead;
* `olib` : (_option_) name of the output library; by default: empty, and the value of 
	`ilib` is used.

### Examples
Let us consider test dataset #5 in WORKing directory:
 f | e | d | c | b | a
---|---|---|---|---|---
 . | 1 | 2 | 3 | . | 5

then both calls to the macro below:
~~~sas
    %var_set(_dstest5, var=FFF AA, val= 10 20);
 ~~~	

will return the exact same dataset `out1=out2` (in WORKing directory) below:
 f | e | d | c | b | a | FFF | AA   
---|---|---|---|---|---|-----|---  
 . | 1 | 2 | 3 | . | 5 | 10  | 20

Instead, the following instruction:
~~~sas
	%var_set(_dstest5, var=k a, val= 10 20, force_set=YES);
~~~	

will return the exact same dataset `out1=out2` (in WORKing directory) below:
 f | e | d | c | b | a | k  | 
---|---|---|---|---|---|----| 
 . | 1 | 2 | 3 | . |20 | 10 | 

Run macro `%%_example_var_set` for more examples.

### Note
When `force_set=yes`, the value of existing variable/s may be replaced this way.

### See also
[%list_length](@ref sas_list_length), [%var_check](@ref sas_var_check).
