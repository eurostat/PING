## ds_nvars {#sas_ds_nvars}
Retrieve the number of variables of a given dataset.

~~~sas
	%let nvars = %ds_nvars(dsn, lib=WORK);
~~~

### Arguments
* `dsn` : a dataset reference;
* `lib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.
  
### Returns
`nvars` : number of variables in dataset `dsn`.

### Example
Let us consider test dataset #5:
 f | e | d | c | b | a
---|---|---|---|---|---
 . | 1 | 2 | 3 | . | 5
then:

~~~sas
	%_dstest5;
	%let nvars=%ds_nvars(_dstest5);
~~~
returns `nvars=5` as expected.

Run `%%_example_ds_nvars` for more examples.

### See also
[%ds_count](@ref sas_ds_count).
