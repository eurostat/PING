## dir_check {#sas_dir_check}
Check the existence of a directory.

~~~sas
	%let ans=%dir_check(dir, mkdir=NO);
~~~

### Arguments
* `dir` : a full path directory;
* `mdkir` : (_option_) boolean flag (`yes/no`) set to force the creation of 
	the directory when it does not already exist.

### Returns
`ans` : error code for the test of prior existence  of the input directory
	(hence, independent of the `mkdir` option), _i.e._:
		+ `0` when the directory exists (and can be opened), or
    	+ `1` (error) when the directory does not exist, or
    	+ `-1` (error) when the fileref exists but cannot be opened as a directory.

### Example
Just try on your "root" path, so that:

~~~sas
	%let ans=&dir_check(&G_PING_ROOTPATH);
~~~
will return `ans=0`.

Run macro `%%_example_dir_check` for more examples.

### Note
The response `and` returned by the macro relates to the prior existence of
the directory. Therefore, even when a directory is created thanks to the option
`mkdir=YES`, the answer may be `ans=0`. 

### See also
[%ds_check](@ref sas_ds_check), [%lib_check](@ref sas_lib_check), [%file_check](@ref sas_file_check),
[FEXIST](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000210817.htm),
[FILENAME](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000210819.htm),
[DOPEN](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000209538.htm).
