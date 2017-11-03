## list_apply {#sas_list_apply}
Calculate the transform of a list given by a mapping table (similarly to a LookUp Transform, LUT).

~~~sas
	%list_apply(map, list, _applst_=, var=, casense=no, sep=%quote( ), lib=WORK);
~~~

### Arguments
* `list` : list of unformatted strings;
* `sep` : (_option_) character/string used as a separator in the input lists; default: `sep=%%quote( )`, 
	_i.e._ the input `list1` and `list2` are both blank-separated lists of items.
 
### Returns
`_applst_` : name of the variable storing the output list built as the list of items obtained through
	the transform defined by the variables `var` of the table `map`, namely: assuming all elements
	in `list` can be found in the (unique) observations of the origin variable, the element in the `i`-th 
	position of the output list is the `j`-th element of the destination variable when `j` is the position
	of the `i`-th element of `list` in the origin variable. 

### Example

~~~sas
	%let list=FR LU BG;
	%let maplst=
	%list_apply(_dstest32, &list, _applst_=maplst, var=1 2);
~~~
returns: `maplst=0.4 0.3 0.2`.	

Run macro `%%_example_list_apply` for more examples.

### Note
It is not checked that the values in the origin variable are unique. 

### See also
[%var_to_list](@ref sas_var_to_list), [%list_find](@ref sas_list_find), [%list_index](@ref sas_list_index),
[%ds_select](@ref sas_ds_select).
