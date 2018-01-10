## ds_rename {#sas_ds_rename}
Rename one or more datasets in the same `SAS` library.

~~~sas
	%ds_rename(idsn, odsn=, ilib=WORK, olib=WORK);
~~~

### Arguments
* `idsn` : old name(s) of reference dataset(s);
* `ilib` : (_option_) name of the library where the old dataset(s) is (are) 
	stored; default: `ilib=WORK`.
	
### Returns
* `odsn` : new name(s); must be of the same length as `olddsn`;
* `olib` : (_option_) name of the library where the new dataset(s) will be
	stored; default: `olib=WORK`.

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
