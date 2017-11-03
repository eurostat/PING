## _DSTEST39 {#sas_dstest39}
Test dataset #39.

	%_dstest39;
	%_dstest39(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest35`:
geo | EQ_INC20 | RB050a
----|----------|-------
 BE |    10    |   10 
 BE |    50    |   10
 BE |    60    |   10
 BE |    20    |   20
 BE |    10    |   20
 BE |    30    |   20
 BE |    40    |   20
 IT |    10    |   10
 IT |    50    |   10
 IT |    50    |   10
 IT |    30    |   20
 IT |    30    |   20
 IT |    20    |   20
 IT |    50    |   20

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) set for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest35`.

### Example
To create dataset #39 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest39;
	%ds_print(_dstest39);

### See also
[%_dstestlib](@ref sas_dstestlib).
