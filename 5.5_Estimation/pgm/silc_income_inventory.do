/**## silc_income_inventory{#stata_silc_income_inventory} 
Create an excel file containing the inventory of income benefit variables corresponding to given
database (h or p), survey (cross-sectional, longitudinal or early) and period (year).
	
~~~stata
    . silc_income_inventory time db [src]
~~~
	
### Arguments 
* `time` : a single selected year of interest;
* `db` : database to retrieve; it can be any of the following character values:
	 	- D for household register/D file,
	 	- H for household/H file,
	 	- P for personal register/P file,
	 	- R for register/R file, 
so as to represent the corresponding bulk databases;
* `src` : string defining the source location where to look for bulk database; 
	this can be any of the following strings:
		- raw so that the path of the search directory is set to the RAW data,
	 	- bdb, ibid with the value of BDB location,
	 	- pdb, ibid with the value of PDB location,
	 	- udb, ibid with the value of UDB location.
	
### Example
~~~stata
    . silc_income_inventory 2014 p
~~~
	
will create an Excel file: `odirname\obasename.oformat`.
*/	

/* credits: nicaver */

global H_DISAGGREGATED_INCOME_INDEX 05 06 07
global P_DISAGGREGATED_INCOME_INDEX 09 10 11 12 13 14 
global SRC BDB

/* subfunctions */

capture program drop inc_discrepancy
program inc_discrepancy
	args inc_vars
	* Discrepancies between lump sum (sum of the income benefit components) and the income aggregate
	local i = 1
	while "``i''" != "" {
	* foreach var in `inc_vars' {
						   
		egen n_``i''0g = rowtotal(``i''1g ``i''2g ``i''3g ``i''4g), m
		compare ``i''0g n_``i''0g

		gen diff_``i''0g = ``i''0g - n_``i''0g
		count if (diff_``i''0g > 0.01 | diff_``i''0g < -0.01) & diff_``i''0g != .
		count if (diff_``i''0g > 1 | diff_``i''0g < -1) & diff_``i''0g != .
		gen diff_``i''0_0_01 = ((diff_``i''0g > 0.01 | diff_``i''0g < -0.01) & diff_``i''0g != .)
		gen diff_``i''0_1 = ((diff_``i''0g > 1 | diff_``i''0g < -1) & diff_``i''0g != .)
		local ++i
	}
end

/* in case it is lost... 
capture program drop silc_db_locate
global g_path="Y:\2.Personal_folders\nicavero\data"
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
*/

/* Main program */

capture program drop silc_income_inventory
program silc_income_inventory
	args year db src
	
	/* retrieve the "path" to the data */
	silc_db_locate `year' ${SRC} `db' ${idir}
	use "`r(db)'", clear

	/* define the indices of income variables with disaggregated components */
	if "`db'"=="h" {
		local disagg ${H_DISAGGREGATED_INCOME_INDEX}
	}
	else {
		local disagg ${P_DISAGGREGATED_INCOME_INDEX}
	}

	/* let us build the following list inc_var_list:
	* 	* "hy05 hy06 hy07" when db=h
	*	* "py09 py10 py11 py12 py13 py14" when db=p */
	local inc_var_list=""
	local inc_dis_list=""
	foreach num of local disagg {
		local inc_dis_list = "`inc_dis_list' `db'y`num'"
		forv i=0/4 {
			local inc_var_list = "`inc_var_list' `db'y`num'`i'g"
		}
	}
	display "`inc_var_list'"
	display "`inc_dis_list'"
	/*foreach var in `inc_var_list' {	
		display "`var'"
	}*/


	***********************************************
	* * *  HOUSEHOLD/PERSONAL INCOME BENEFITS * * *
	***********************************************

	format `db'b010 %4.0f

	* Total number of observations per country
	bys `db'b020: gen N = _N

	* HY05*G - HY07*G
	foreach var of varlist `inc_var_list' {
		bys `db'b020: egen `var'_nonmiss = count(`var')
		bys `db'b020: gen `var'_invent = (`var'_nonmiss == N)
		bys `db'b020: replace `var'_invent = 2 if (`var'_nonmiss != N & `var'_nonmiss !=. & `var'_nonmiss !=0)
	}

	* Note: 0 - Country does not send data on any of the observations in the sample (missing data)
	*	    1 - Country send the data for all the observations in the sample (no missing)
	*	    2 - Country send some data, but not for all the observations in the sample

	* Number of the components for which the country send data
	foreach inc_var in `inc_dis_list' {
	gen `inc_var'0g_nr_comp = 0

		foreach inc_comp in `inc_var'1g_invent `inc_var'2g_invent `inc_var'3g_invent `inc_var'4g_invent {
		replace `inc_var'0g_nr_comp = `inc_var'0g_nr_comp + 1 if `inc_comp' != 0
		}
	}

	inc_discrepancy `inc_dis_list'

	*********************************************************************************** 
	* Output ---> the code below creates an Excel file with the Stata Output - 
	***********************************************************************************

	local ofile="${odirname}\${obasename}_`year'`db'.${oformat}"
	
	foreach var in `inc_dis_list' {

		putexcel set `ofile', sheet(`var'0g) modify
		putexcel A1 = "Table. Inventory of the countries that send data (complete, partial, or no data) on `var'0G income components"
		
	* Insert stats
		preserve
			collapse `var'0g_invent `var'1g_invent `var'2g_invent `var'3g_invent `var'4g_invent `var'0g_nr_comp, by(`db'b020)
			export excel using `ofile', sheet("`var'0g", modify) cell(A4) //sheetmodify
		restore
		 
		foreach col in B C D E F G {
			putexcel `col'38 = formula(COUNTIF(`col'4:`col'37,"<>0")), nformat(number) 
			}

		preserve
			collapse (sum) diff_`var'0_0_01 diff_`var'0_1, by(`db'b020)
			export excel diff_`var'0_0_01 diff_`var'0_1 using `ofile', sheet("`var'0g", modify) cell(H4) //sheetmodify
		restore
			
		foreach col in H I {
			putexcel `col'38 = formula(SUM(`col'4:`col'37)), nformat(number)
		}
		
		putexcel A38 = "Total"

	* Name the columns
		putexcel A2 = "Country" ///
				 B2 = "`var'0" ///
				 C2 = "`var'1" ///
				 D2 = "`var'2" ///
				 E2 = "`var'3" ///
				 F2 = "`var'4" ///
				 G2 = "Nr. of the components for which the country send data" ///
				 H2 = "Nr. of discrepancies between lump sum and the income aggregate" ///
				 H3 = ">|0.01|" ///
				 I3 = ">|1|", txtwrap
				 
				 
	* Format cells
		putexcel A2:I3, vcenter hcenter bold border(all, thin, black)
		putexcel A38:I38, bold border(bottom, thin, black)
		putexcel A2:A3 B2:B3 C2:C3 D2:D3 E2:E3 F2:F3 G2:G3 H2:I2, merge
		
	* Insert Note and Source
		putexcel A39 = "Source:" ///
				 A40 = "Note:", bold
		putexcel B39 = "${SRC} (`year')"   ///
				 B40 = "0 - Country does not send data on any of the observations in the sample (missing data)" ///
				 B41 = "1 - Country send the data for all the observations in the sample (no missing)" ///
				 B42 = "2 - Country send some data, but not for all the observations in the sample"
				 
	}


end
