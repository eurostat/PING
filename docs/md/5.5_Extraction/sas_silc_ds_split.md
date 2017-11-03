## silc_ds_split {#sas_silc_ds_split}
Split a EU-SILC dataset into subsets that contain data for a given country and a given
year.

~~~sas
	%silc_ds_split(geo, time, idsn, odsn=, _ctrylst_=, _yearlst_=, _db_=, ilib=WORK, olib=WORK);
~~~

### Arguments
* `geo` : list of desired countries ISO-codes		
* `time` : list of desired years 					
* `idsn` : input dataset 							
* `ilib` : input library name 

### Returns
* `odsn` : generic output file name 				
* `_ctrylst_` : output list of countries actually extracted 
* `_yearlst_` : output list of years actually extracted 	
* `_db_` : output level 	
* `olib` : output library name.

### See also
[%ds_select](@ref sas_ds_select), [%ds_contents](@ref sas_ds_contents), 
[%dir_check](@ref sas_dir_check), [%ds_check](@ref sas_ds_check), 
[%str_isgeo](@ref sas_str_isgeo), [%zone_replace](@ref sas_zone_replace),
[%var_to_list](@ref sas_var_to_list).
