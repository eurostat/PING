## silc_ref2lib {#sas_silc_ref2lib}
Retrieve the actual (physical) library associated to a EU-SILC reference. 

~~~sas
	%let lib=%silc_ref2lib(ref);
~~~

### Argument
`ref` : input library reference, _e.g._ any string in `RDB`, `RDB2`, `EDB`, `LDB`.

### Returns
`lib` : library associated to the reference `ref`.

### Example
Running for instance:

~~~sas
	%let lib=%silc_ref2lib(RDB);
~~~
will set: `lib=LIBCRDB`.

See `%%_example_silc_ref2library` for more examples.
	
### See also
[%silc_db_locate](@ref sas_silc_db_locate), [%silc_ind_ref](@ref sas_silc_ind_ref).
