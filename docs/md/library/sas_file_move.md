## file_move {#sas_file_move}
Rename/move a file (or a directory) to another location.

~~~sas
	%file_move(ifn, ofn=, idir=, odir=);
~~~

### Arguments
* `ifn` : name or full path of an input file;
* `idir` : (_option_) input directory where the input file is located; if not passed, the 
	location is derived from `ifn`.

### Returns
* `ofn` : (_option_) new location/name of the file; if empty, the renaming of the file
	uses the timestamp;
* `odir` : (_option_) output directory where the file will be moved; if empty, `odir` is
	set to `idir`.

### Examples

Run macro `%%_example_file_move` for examples.

### See also
[%file_check](@ref sas_file_check), [%file_name](@ref sas_file_name).
