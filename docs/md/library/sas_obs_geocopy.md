## obs_geocopy {#sas_obs_geocopy}
Copy all observations of a given geographical area/country onto another geographical area/country
set of observations.

~~~sas
	obs_geocopy(dsn, igeo, ogeo, time=, replace=NO, lib=WORK); 
~~~

### Arguments
* `dsn` : an input reference dataset;
* `igeo` : a string representing a country ISO-code or a geographical zone;
* `ogeo` : _ibid_, a string representing a country ISO-code or geographical zone;
* `time` : (_option_) selected year for which the copy is operated; default: not set, and all 
	`igeo` observations are copied into `ogeo` observations;
* `replace` : (_option_) boolean flag (`yes/no`) set to actually replace of `igeo` observations
	by `ogeo` observations; default: `replace=NO`, _i.e_ all `igeo` observations are preserved
	in the dataset;
* `lib` : (_option_) name of the library where `dsn` is stored; by default: empty, _i.e._ `WORK`
	is used.

### Returns
It will update the input dataset `dsn` with `ogeo` observations that are copies of the `igeo`
observations at time `time`.

### Example
Given the table `dsn`: 
| geo  | time | ivalue |
|:----:|-----:|-----:|
| EU28 | 2016 | 1 |
| EU28 | 2015 | 1 |
| EU28 | 2014 | 1 |
| EU27 | 2016 | 2 |
| EU27 | 2015 | 2 |
| EU27 | 2014 | 2 |
| EU   | 2016 | 3 |
the following command:

~~~sas
	%obs_geocopy(dsn, EU28, EU, time=2015 2014, lib=WORK);
~~~
will update the table `dsn` as follows:
| geo  | time | ivalue |
|:----:|-----:|-----:|
| EU28 | 2016 | 1 |
| EU28 | 2015 | 1 |
| EU28 | 2014 | 1 |
| EU27 | 2016 | 2 |
| EU27 | 2015 | 2 |
| EU27 | 2014 | 2 |
| EU   | 2016 | 3 |
| EU   | 2015 | 1 |
| EU   | 2014 | 1 |

Run macro `%%_example_geo_copy` for more examples.

### See also
[%silc_agg_process](@ref sas_silc_agg_process),
[%obs_duplicate](@ref sas_obs_duplicate), [%meta_countryxzone](@ref meta_countryxzone).
