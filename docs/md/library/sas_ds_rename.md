## ds_rename {#sas_ds_rename}
Rename one or more datasets in the same SAS library.

~~~sas
	%ds_rename(olddsn, newdsn, lib=WORK);
~~~

### Arguments
* `olddsn` : (list of) old name(s) of reference dataset(s);
* `newdsn` : (list of) new name(s); must be of the same length as `olddsn`;
* `lib` : (_option_) name of the library where the dataset(s) is (are) stored; default: `lib=WORK`.
	
### Note
In short, this macro runs:
~~~sas
	DATA &olib..&odsn;
		SET &ilib..&idsn;
	run;

	PROC DATASETS library=&ilib;
		DELETE &idsn;
	run;
~~~

### See also
[%ds_change](@ref sas_ds_change).
