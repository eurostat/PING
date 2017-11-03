## pension_gap_coverage_rate {#sas_pension_gap_coverage_rate}
Perform ad-hoc extraction for Data collection by DG JUST for Commission's next annual 
report on gender equality. 

	%pension_gap_coverage_rate(year,dsn_name,weight,geo=, idir=, lib= ,odir=,ext_odsn=);

### Arguments
* `year`: a or more years of interest;
* `dsn_name`: output dataset:  GAP/COVERAGE rate;
* `weight`: weight ;
* `geo` : (_option_) a list of countries or a geographical area; default: `geo=EU28`;
* `idir`: (_option_) name of the output directory where to look for _GAP_ indicators passed 
	instead of `ilib`; incompatible with `ilib`; by default, it is not used; 
* `lib`: (_option_) name of the output library where to look for _GAP_ indicators (see 
	note below);  
* `odir=`:		 Input directory name			 
* `ext_odsn=`:	 Generic output dataset name. 	 
 

### Returns
Two datasets:
* `%%upcase(GAP)` contains the _GAP_ table with genger gap in pension,
* `%%upcase(COVERAGE_RATE)` contains the _COVERAGE_ genger gap coverage rate in pension 
stored in the library passed through `olib`.

and Two csv files:
* `%%upcase(GENDER_&years&ext_odsn` contains the _GAP_ table with genger gap in pension for all countries available for specific years (&years) ,
* `%%upcase(COVERAGE_&years&ext_odsn` contains the _COVERAGE_ genger gap coverage rate in pension all countries available for specific years (&years).
stored in the pathname  passed through `odir`.


### Note
The publication is based on the following  indicators:

### References
1. [2016] http://ec.europa.eu/europe2020/pdf/themes/2016/adequacy_sustainability_pensions_201605.pdf
This indicator is defined in the Pension Adequacy Report 2015.
The definition of the coverage gap is on page 149 and the results displayed in Figure 3.23 (p. 155).
This indicator complements the gender gap in pensions (which excludes the persons with no pension at all). 

### See also
[2015]SPC and DG EMPL:  The 2015 Pension Adequacy Report: current and future income adequacy in old age in EU.Vol 1
