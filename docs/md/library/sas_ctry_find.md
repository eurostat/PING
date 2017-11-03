## ctry_find {#sas_ctry_find}
Return the list of countries available in a given dataset and for a given year, or a 
subsample of it, and store it in an output table. 

~~~sas
	%ctry_find(idsn, year, odsn, ctrylst=, 
				sampsize=0, force_overwrite=no, ilib=, olib=);
~~~

### Arguments
* `idsn` : input reference dataset;
* `year` : year to consider for the selection of country;
* `ctrylst` : (_option_) list of (blank-separated) strings representing the set of countries
	ISO-codes (_.e.g._, produced as the output of `%zone_to_ctry` with the option `_ctrylst_`), 
	to look for; default: `ctrylst` is not set and all available countries (_i.e._ actually
	present) are returned in the output table;
* `sampsize` : (_option_) when >0, only a (randomly chosen) subsample of the countries 
	available in `idsn` is stored in the output table `odsn` (see below); default: 0, 
	_i.e._ no sampling is performed; see also the macro [%ds_sample](@ref sas_ds_sample);
* `force_overwrite` : (_option_) boolean argument set to yes when the table `odsn` is
	to be overwritten; default to `no`, _i.e._ the new selection is appended to the table
	if it already exists;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.
 
### Returns
* `odsn` : name of the output table where the list of countries is stored; the countries listed
	in this table are a subset of `ctrylst` when this latter variable is passed;
* `olib` : (_option_) name of the output library; by default: empty, and the value of `ilib` 
	is used.

### Example
Say that you are at the beginning of year=2020, EU-SILC still exists, UK has left EU28 which
is now EU27, we launch:

~~~sas
	%local countries;
	%let year=2020
	%zone_to_ctry(EU27, time=&year, _ctrylst_=countries);
~~~
so that `countries` contain the list of all countries member of EU27 at this time. Suppose now
that only AT, FI, HU and LV have transmitted data, then the command to retrieve this information
for indicator LI01 is:

~~~sas
	%ctry_find(LI01, &year, out, ctrylst=&countries, ilib=rdb, olib=WORK);
~~~
which will create the following table `out` in `WORK`ing library:
| time | geo |
|-----:|:---:|
| 2016 |  AT |
| 2016 |  FI |
| 2016 |  HU |
| 2016 |  LV |

Run macro `%%_example_ctry_find` for examples.

### See also
[%ds_sample](@ref sas_ds_sample), [%ctry_select](@ref sas_ctry_select).
