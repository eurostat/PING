/**## Stata silc_db_locate {#stata_silc_db_locate} 

~~~stata
    . silc_db_locate time src db [idir]
~~~
	
### Arguments 
* `time` : a single selected year of interest;
* `src` : string defining the source location where to look for bulk database; 
	this can be any of the following strings:
		- raw so that the path of the search directory is set to the RAW data,
	 	- bdb, ibid with the value of BDB location,
	 	- pdb, ibid with the value of PDB location,
	 	- udb, ibid with the value of UDB location; 
* `db` : database to retrieve; it can be any of the following character values:
	 	- D for household register/D file,
	 	- H for household/H file,
	 	- P for personal register/P file,
	 	- R for register/R file, 
so as to represent the corresponding bulk databases;
* `idir` : (_option_) location of input directory.
	
### Return
In `rclass` object `db`, _i.e._ <code>"`r(db)'"</code> the path to the bulk dataset. 

### Example
Running for instance:
~~~stata
    . silc_db_locate 2016 bdb p test
	. use "`r(db)'", clear
~~~
	
will load: `test\bdb_c16p.dta`.
	
### See also
[SAS implementation](@ref sas_silc_db_locate).
*/	


/* credits: nicaver */

/* Locate the bulk database (pathname) corresponding to given survey (cross-sectional, longitudinal or
early) and period (year) */

capture program drop silc_db_locate
global g_path="" /* set to your own */
global g_ext="dta"

program silc_db_locate, rclass
	local time = mod(`1', 100)
	local src  = "`2'_c"
	local db   = strlower("`3'")
	if "`4'" == "" {
		local idir = "${g_path}"
	} 
	else {
		local idir = "`4'"
	}
	
	return local db "`idir'\\`src'`time'`db'.${g_ext}" 
end

