## silc_income_inventory {#stata_silc_income_inventory} 
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
