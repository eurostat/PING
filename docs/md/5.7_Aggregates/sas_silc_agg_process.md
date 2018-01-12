## silc_agg_process {#sas_silc_agg_process}
Legacy _"EUVALS"_-based code that calculates: _(i)_ as many EU aggregates of _(ii)_ as many 
indicator over _(iii)_ as many years, as desired, possibly imputing data for missing countries 
from past years. 

~~~sas
	%silc_agg_process(indicators, aggregates, years, geo2geo=, 
			max_yback=0, thr_min=0.7, thr_cum=0, ilib=WORK, olib=WORK);
~~~

### Arguments
* `indicators` : list of indicators, _i.e._ names of the datasets that store the indicators; 
	aggregates will be estimated over the `aggregates` areas and during the `years` period;
* `aggregates` : list of geographical areas, _e.g._ EU28, EA, ...;
* `years` : list of year(s) of interest;
* `geo2geo` : (_option_) list of correspondance rule that will enable you to copy the observations
	of a given aggregate into another one; it will take the form `((ogeo1=igeo1) (ogeo1=ogeo2) ...)`
	where all observations `igeo1` are copied (while preserved) to `ogeo1` in the output table,
	ibid for `igeo2` and `ogeo2`, _etc_...; note that the outermost parentheses `(...)` are not
	necessary; default: `geo2geo` is empty, _i.e._ no copy is operated; see 
	[%obs_geocopy](@ref sas_obs_geocopy) for more details;
* `max_yback` : (_option_) number of years used for imputation of missing data; it tells how 
	to look backward in time, _i.e._ consider the `max_yback` years prior to the estimated 
	year; see [%silc_agg_compute](@ref sas_silc_agg_compute) for further details; default: 
	`max_yback=0`; 
* `thr_min` : (_option_) value (in range [0,1]) of (lower acceptable) the threshold used to 
	compare currently available population to global population; see 
	[%silc_agg_compute](@ref sas_silc_agg_compute) for further details; default: `thr_min=0.7`; 
* `thr_cum`: (_option_) value (in range [0,1]) of the (lower acceptable) threshold used to 
	compare the cumulated available population over `max_yback` years to global population; 
	see [%silc_agg_compute](@ref sas_silc_agg_compute); default: `thr_cum=0`; 
* `ilib` : (_option_) input dataset library; default (not passed or ' '): `ilib=WORK`;
* `olib` : (_option_) input dataset library; default (not passed or ' '): `olib=WORK`.

### Returns
For each input indicators in `indicators`, update the corresponding table in `ilib` with all 
aggregated values and store it (with the same name) in `olib`. 

### Example
Considering the following `PEPS01` indicator table:
| geo | time | age   | sex | unit | ivalue  | flag | unrel | n     | ntot  | totwgh |
|:---:|-----:|:-----:|:---:|:----:|--------:|:----:|------:|------:|------:|-------:| 
| AT  | 2015 | TOTAL | T   | PC   | 18.3001 |      | 0     | 2221  | 13213 | 8476450.56  |
| BE  | 2015 | TOTAL | T   | PC   | 21.0982 |      | 0     | 3103  | 14209 | 11073760.02 |
| BG  | 2015 | TOTAL | T   | PC   | 41.3311 |      | 0     | 5155  | 12031 | 7214208.95 |
| BG  | 2016 | TOTAL | T   | PC   | 40.3672 | b    | 0     | 7342  | 17788 | 7159945.97 |
| CH  | 2015 | TOTAL | T   | PC   | 18.1994 |      | 0     | 2474  | 17164 | 8107904 |
| CY  | 2015 | TOTAL | T   | PC   | 28.9414 |      | 0     | 3240  | 11966 | 843221 |
| CZ  | 2015 | TOTAL | T   | PC   | 13.9887 |      | 0     | 2184  | 17714 | 10324059.2 |
| DE  | 2015 | TOTAL | T   | PC   | 19.9646 |      | 0     | 4742  | 26379 | 80556397   |
| DK  | 2015 | TOTAL | T   | PC   | 17.7494 |      | 0     | 1197  | 13969 | 5626658.53 |
| EE  | 2015 | TOTAL | T   | PC   | 24.2108 |      | 0     | 3431  | 14558 | 1300279 |
| EL  | 2015 | TOTAL | T   | PC   | 35.7038 |      | 0     | 12145 | 34465 | 10723089 |
| ES  | 2015 | TOTAL | T   | PC   | 28.65 	|      | 0     | 8776  | 32380 | 45986380 |
| ES  | 2016 | TOTAL | T   | PC   | 27.9123 |      | 0     | 9158  | 36380 | 45953168 |
| FI  | 2015 | TOTAL | T   | PC   | 16.7624 |      | 0     | 3196  | 26433 | 5390568.68 |
| FI  | 2016 | TOTAL | T   | PC   | 16.5823 |      | 0     | 3018  | 25983 | 5404487.99  |
| FR  | 2015 | TOTAL | T   | PC   | 17.6896 |      | 0     | 4610  | 26645 | 62453275.37 |
| HR  | 2015 | TOTAL | T   | PC   | 29.0582 |      | 0     | 5538  | 17177 | 4184976 |
| HU  | 2015 | TOTAL | T   | PC   | 28.2079 |      | 0     | 5764  | 18682 | 9695142 |
| IE  | 2015 | TOTAL | T   | PC   | 26.0018 |      | 0     | 3568  | 13793 | 4641897.99 |
| IS  | 2015 | TOTAL | T   | PC   | 12.9913 |      | 0     | 855   | 8604  | 316430 |
| IT  | 2015 | TOTAL | T   | PC   | 28.7108 |      | 0     | 10404 | 42987 | 60843061.04 |
| LT  | 2015 | TOTAL | T   | PC   | 29.3489 |      | 0     | 3077  | 11015 | 2921262      |
| LU  | 2015 | TOTAL | T   | PC   | 18.4715 |      | 0     | 1723  | 8767  | 514254 |
| LV  | 2015 | TOTAL | T   | PC   | 30.8766 |      | 0     | 4676  | 13923 | 1961234 |
| LV  | 2016 | TOTAL | T   | PC   | 28.5005 |      | 0     | 4374  | 13864 | 1942760 |
| MK  | 2015 | TOTAL | T   | PC   | 41.5739 |      | 0     | 5693  | 13458 | 2069751.38 |
| MT  | 2015 | TOTAL | T   | PC   | 22.4401 |      | 0     | 2516  | 11252 | 420007.95 |
| NL  | 2015 | TOTAL | T   | PC   | 16.375  |      | 0     | 2163  | 23338 | 16757719.39 |
| NO  | 2015 | TOTAL | T   | PC   | 14.9751 |      | 0     | 1516  | 15699 | 5142181.91  |
| PL  | 2015 | TOTAL | T   | PC   | 23.4404 |      | 0     | 8691  | 33652 | 37374543 |
| RO  | 2015 | TOTAL | T   | PC   | 37.3783 |      | 0     | 6345  | 17411 | 19890447.12 |
| RS  | 2015 | TOTAL | T   | PC   | 41.2957 |      | 0     | 7797  | 18270 | 7086011 |
| SI  | 2015 | TOTAL | T   | PC   | 19.1585 |      | 0     | 4417  | 26150 | 2006985.22 |
| SK  | 2015 | TOTAL | T   | PC   | 18.3874 |      | 0     | 2882  | 16181 | 5236123.99 |
| PT  | 2015 | TOTAL | T   | PC   | 26.6478 |      | 0     | 6350  | 21965 | 10374822 |
| SE  | 2015 | TOTAL | T   | PC   | 18.6015 | b    | 0     | 1614  | 14249 | 9746194.26 |
| CZ  | 2016 | TOTAL | T   | PC   | 13.3016 |      | 0     | 2193  | 18964 | 10339778.6 |
| DK  | 2016 | TOTAL | T   | PC   | 16.7469 |      | 0     | 1196  | 13846 | 5657944 |
| HU  | 2016 | TOTAL | T   | PC   | 26.2791 |      | 0     | 5362  | 18809 | 9669282 |
| PT  | 2016 | TOTAL | T   | PC   | 25.0922 |      | 0     | 7506  | 26565 | 10341330 |
| SK  | 2016 | TOTAL | T   | PC   | 18.1111 |      | 0     | 3056  | 16507 | 5247463.13 |
| SI  | 2016 | TOTAL | T   | PC   | 18.4238 |      | 0     | 4023  | 25637 | 2015471.69 |
| NO  | 2016 | TOTAL | T   | PC   | 15.2872 |      | 0     | 1739  | 16899 | 5174830.98 |
| TR  | 2015 | TOTAL | T   | PC   | 41.2995 |      | 0     | 36666 | 81048 | 76368972 |
| RS  | 2016 | TOTAL | T   | PC   | 38.7272 |      | 0     | 7068  | 17720 | 7033451 |
| LT  | 2016 | TOTAL | T   | PC   | 30.1481 |      | 0     | 3056  | 10905 | 2888558 |
| EE  | 2016 | TOTAL | T   | PC   | 24.436  |      | 0     | 3578  | 15193 | 1302797 |
| PL  | 2016 | TOTAL | T   | PC   | 21.9182 |      | 0     | 8089  | 32609 | 37508480.69 |
| UK  | 2015 | TOTAL | T   | PC   | 23.4504 |      | 0     | 5259  | 21242 | 63954009 |
| UK  | 2016 | TOTAL | T   | PC   | 22.184  |      | 0     | 5160  | 22205 | 64728438    |
| SE  | 2016 | TOTAL | T   | PC   | 18.2622 |      | 0     | 1697  | 14072 | 9851017 |
| CH  | 2016 | TOTAL | T   | PC   | 17.8124 |      | 0     | 2495  | 17881 | 8195862 |
| FR  | 2016 | TOTAL | T   | PC   | 18.2425 |      | 0     | 4730  | 26647 | 62837901.62 |
| DE  | 2016 | TOTAL | T   | PC   | 19.6926 |      | 0     | 4930  | 26803 | 81427111 |
| NL  | 2016 | TOTAL | T   | PC   | 16.7216 | b    | 0     | 3575  | 29559 | 16724232 |
| HR  | 2016 | TOTAL | T   | PC   | 27.9418 |      | 0     | 5980  | 19661 | 4149254 |
| MT  | 2016 | TOTAL | T   | PC   | 20.0758 |      | 0     | 2225  | 10743 | 424831.04   |
| RO  | 2016 | TOTAL | T   | PC   | 38.8253 |      | 0     | 6238  | 17355 | 19817899.94 |
| CY  | 2016 | TOTAL | T   | PC   | 27.6947 |      | 0     | 3018  | 11236 | 844559 |
| EL  | 2016 | TOTAL | T   | PC   | 35.5734 |      | 0     | 15508 | 44094 | 10651929 |
| BE  | 2016 | TOTAL | T   | PC   | 20.7181 |      | 0     | 2963  | 13773 | 11269855.71 |
| IT  | 2016 | TOTAL | T   | PC   | 29.9778 |      | 0     | 12337 | 48316 | 60500228.84 |
| IE  | 2016 | TOTAL | T   | PC   | 24.2317 |      | 0     | 3261  | 13186 | 4683666.01 |
| LU  | 2016 | TOTAL | T   | PC   | 19.8087 | b    | 0     | 1986  | 10159 | 575993.71  |
| AT  | 2016 | TOTAL | T   | PC   | 17.9541 |      | 0     | 2072  | 13049 | 8590169.38 |
| MK  | 2016 | TOTAL | T   | PC   | 41.1011 |      | 0     | 5970  | 14310 | 2072573.48 |
| DK  | 2017 | TOTAL | T   | PC   | 17.1904 |      | 0     | 1205  | 12727 | 5697896 |
| HU  | 2017 | TOTAL | T   | PC   | 25.578  |      | 0     | 5075  | 18591 | 9637338 |
then calling the macro:	

~~~sas
	%silc_agg_process(PEPS01, EU28 EU27, 2016 2015, 
		geo2geo=((EU=EU28) (EA=EA19)), max_yback=0, ilib=WORK);
~~~
will update that same table with the following estimated aggregate observations:
| geo  | time | age   | sex | unit | ivalue  | flag | unrel | n      | ntot   | totwgh |
|:----:|-----:|:-----:|:---:|:----:|--------:|:----:|------:|-------:|-------:|-------:| 
| EU28 | 2016 | TOTAL | T   | PC   | 23.4893 |      |  0    | 137631 | 593908 | 502508553.3 |
| EU27 | 2016 | TOTAL | T   | PC   | 23.4522 |      |  0    | 131651 | 574247 | 498359299.3 |
| EA19 | 2016 | TOTAL | T   | PC   | 23.0942 |      |  0    | 943744 | 18599  | 333626513.1 |
| EU   | 2016 | TOTAL | T   | PC   | 23.4893 |      |  0    | 137631 | 593908 | 502508553.3 |
| EA   | 2016 | TOTAL | T   | PC   | 23.0942 |      |  0    | 943744 | 18599  | 333626513.1 |
| EU28 | 2015 | TOTAL | T   | PC   | 23.7865 |      |  0    | 128987 | 555746 | 500491026.3 |
| EU27 | 2015 | TOTAL | T   | PC   | 23.7420 |      |  1    | 234495 | 38569  | 496306050.3 |
| EA19 | 2015 | TOTAL | T   | PC   | 23.0593 |      |  0    | 872403 | 89619  | 332480788.2 |
| EU   | 2015 | TOTAL | T   | PC   | 23.7865 |      |  0    | 128987 | 555746 | 500491026.3 |
| EA   | 2015 | TOTAL | T   | PC   | 23.0593 |      |  0    | 872403 | 89619  | 332480788.2 |
since the aggregate `EA19` needs to be estimated to fill in the `EA` value as well.  
 
Instead, it is also possible to run:
~~~sas
	%silc_agg_process(PEPS01, EU28 EU27, 2017, thr_min=0, max_yback=1, ilib=WORK);
~~~

in order to estimate 2017 aggregates while most values are missing, so as to update the table 
with the following estimated aggregate observations:
| geo  | time | age   | sex | unit | ivalue  | flag | unrel | n      | ntot   | totwgh |
|:----:|-----:|:-----:|:---:|:----:|--------:|:----:|------:|-------:|-------:|-------:| 
| EU28 | 2017 | TOTAL | T   | PC   | 23.4802 | e    | 0     | 137353 | 592571 | 502516561.3 |
| EU27 | 2017 | TOTAL | T   | PC   | 23.443	 | e    | 0     | 131373 | 572910 | 498367307.3 |

Run macro `%%_example_silc_agg_process` for more examples. 
 
### Note 
See [%silc_agg_compute](@ref sas_silc_agg_compute) and  [%silc_EUvals](@ref sas_silc_euvals)
for further details on effective computation. 
 
### References
1. World Bank [aggregation rules](http://data.worldbank.org/about/data-overview/methodologies).
2. Eurostat [geography glossary](http://ec.europa.eu/eurostat/statistics-explained/index.php/Category:Geography_glossary).

### See also
[%silc_agg_compute](@ref sas_silc_agg_compute), [%silc_EUvals](@ref sas_silc_euvals), 
[%silc_agg_list](@ref sas_silc_agg_list), [%obs_geocopy](@ref sas_obs_geocopy), 
[%ctry_select](@ref sas_ctry_select), [%zone_to_ctry](@ref sas_zone_to_ctry), 
[%var_to_list](@ref sas_var_to_list).
