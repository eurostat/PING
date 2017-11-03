/********************************************************************************/


/** Applied over all variables **************************************************
** MODIFIED ACCORDING TO 2015 DATA AVAILABILITY + RULES COMMUNICATED BY THE    **
** COUNTRIES ********************************************************************
**/


/** D variables *****************************************************************
** MODIFIED ACCORDING TO 2015 DATA AVAILABILITY + RULES COMMUNICATED BY THE    **
** COUNTRIES ********************************************************************
**/

%global 
	G_GEO_DB040_RECODING_1
	G_GEO_DB040_MISSING
	G_GEO_DB040_FI_RECODING
	G_GEO_DB100_MISSING
	G_GEO_DB100_GROUPING_1_2
	G_GEO_DB100_GROUPING_2_3
	G_GEO_DB060_DB062_RANDOMISE
	;

/* DB040  													 
	* NUTS 1 recoding: DB040 => LEFT(SUBSTR(DB040,1,3))   - rule DB040_RECODING_1
	* Set to missing (no NUTS) 								 - rule DB040_MISSING 
	* Recoding:  FI20 => FI1B 		  			  - ad-hoc rule DB040_FI_RECODING 
*/
%let G_GEO_DB040_RECODING_1=			AT BE BG CH CY DK EE EL HR HU IE IS IT LT LU LV MT NO PL RO SE SI SK UK;
/* note: no recoding for CZ, ES and FR */
%let G_GEO_DB040_MISSING=				DE PT NL; /* !!! SI ?!!! */
%let G_GEO_DB040_FI_RECODING= 			FI;

/* DB100 (Degree of urbanization)  					   
	* Set to missing 										 - rule DB100_MISSING
	* Grouping (merging): (1,2) => 1 					- rule DB100_GROUPING_1_2
	* Grouping (merging): (2,3) => 2 					- rule DB100_GROUPING_2_3 
*/
%let G_GEO_DB100_MISSING=				NL SI;
%let G_GEO_DB100_GROUPING_1_2=			EE LV;
%let G_GEO_DB100_GROUPING_2_3=			MT

/* DB060/DB062 randomisation  						 - rule DB060_DB062_RANDOMISE 
	* random permutation of observations */
%let G_GEO_DB060_DB062_RANDOMISE= 		_ALL_; /*?*/


/** P variables *****************************************************************
** MODIFIED ACCORDING TO 2015 DATA AVAILABILITY + RULES COMMUNICATED BY THE    **
** COUNTRIES ********************************************************************
**/

%global 
	G_GEO_PDISAGG_MISSING
	G_GEO_PB100_GROUPING_1_2_3_4
	G_GEO_PB130_GROUPING_1_2_3_4
	G_GEO_PB130_MISSING
	G_GEO_PB140_BELOW_80
	G_GEO_PB140_BELOW_81
	G_GEO_PB190_RECODING_3_5
	G_GEO_PX020_TOPCUT_80
	G_GEO_PE020_GROUPING_20
	G_GEO_PE020_GROUPING_30_40
	G_GEO_PE040_GROUPING_200
	G_GEO_PE040_GROUPING_300_400
	G_GEO_PE020_TOPCUT_50
	G_GEO_PE040_TOPCUT_500
	G_GEO_COUNTRY_RECODING
	G_GEO_COUNTRY_RECODING_NOEU
	;

/* PY091G PY092G PY093G PY094G PY101G PY102G PY103G PY104G
*  PY111G PY112G PY113G PY114G PY121G PY122G PY123G PY124G
*  PY131G PY132G PY133G PY134G PY141G PY142G PY143G PY144G
	* Set (all disaggregated variables) to missing 			- rule DISAGG_MISSING 
*/
%let G_GEO_PDISAGG_MISSING=				&noDISAG;

/* PB100 (Month personal interview)  				- rule PB100_GROUPING_1_2_3_4
	* Grouping:	(1,2,3) => 1 
				(4,5,6) => 2
				(7,8,9) => 3 
				(10,11,12) => 4 */ 
%let G_GEO_PB100_GROUPING_1_2_3_4= 		_ALL_;

/* PB130  											  
	* Grouping: (1,2,3) => 1 						- rule PB130_GROUPING_1_2_3_4
				(4,5,6) => 2
				(7,8,9) => 3 
				(10,11,12) => 4 
	* Set to missing 										 - rule PB130_MISSING
*/
%let G_GEO_PB130_GROUPING_1_2_3_4= 		_ALL_;
%let G_GEO_PB130_MISSING=				DE IE MT NL SI UK;

/* PB140  													  
	* Recoding below 80: (<=2000+&y-80) => (2000+&y-80)		- rule PB140_BELOW_80
	* Recoding below 81: (<=2000+&y-81) => (2000+&y-81) 	- rule PB140_BELOW_81
*/
%let G_GEO_PB140_BELOW_80=				PT;
%let G_GEO_PB140_BELOW_81=				%list_difference(&G_GEO, &G_GEO_PB140_BELOW_80); /*! _ALL_ except PT !*/

/* PB190  												- rule PB190_RECODING_3_5
	* Recoding of marital status PB190 : (3,5) => 3*/
%let G_GEO_PB190_RECODING_3_5=			MT; 

/* PX020 (AGE)  										   - rule PX020_TOPCUT_80
	* Top-coding to 80 : 	(>80) => 80 */
%let G_GEO_PX020_TOPCUT_80=				_ALL_; 

/* PE020 (ISCED currently attended)  					   
	* Grouping: (00,10,20) => 20 			 			 - rule PE020_GROUPING_20
	* Grouping: (30,34,35) => 30 					  - rule PE020_GROUPING_30_40
				(40,44,45) => 40 
	* Top coding: 			(>50) => 50 				   - rule PE020_TOPCUT_50
*/ 
%let G_GEO_PE020_GROUPING_20=			MT SI; 
%let G_GEO_PE020_GROUPING_30_40=		IT; 
%let G_GEO_PE020_TOPCUT_50=				_ALL_; 

/* PE040 (highest ISCED level attained)				
	* Grouping: (000,100,200) => 200  					- rule PE040_GROUPING_200
	* Grouping: (300,340,342,343,350,352,353,354) => 300  - rule GROUPING_300_400
				(400,440,450) => 400  
	* Top coding: (>500) => 500 						  - rule PE040_TOPCUT_500 
*/
%let G_GEO_PE040_GROUPING_200=			SI; 
%let G_GEO_PE040_GROUPING_300_400=		IT; 
%let G_GEO_PE040_TOPCUT_500=			_ALL_; 

/* PL111 										   - rule PL111_GROUPING_RECODING
	* Grouping and replace PL111 (ungrouped, numeric) with PL1111 (grouped, string) 
*/
%let G_GEO_PL111_GROUPING_RECODING=		_ALL_;

/* PB210/PB220A (country of birth/citizenship) 	- rules COUNTRY_RECODING/COUNTRY_RECODING_NOEU
	* Recoding: born in/citizen of country 		 => 'LOC' 				
	*			born in/citizen of EU 			 => 'EU', unless NO EU ('OTH') requested 
	* 			others (born/citizen outside EU) => 'OTH' 
*/
%let G_GEO_COUNTRY_RECODING=			_ALL_;
%let G_GEO_COUNTRY_RECODING_NOEU=		DE EE LV MT SI;

/** H variables *****************************************************************
** MODIFIED ACCORDING TO 2015 DATA AVAILABILITY + RULES COMMUNICATED BY THE    **
** COUNTRIES ********************************************************************
**/

%global 
	G_GEO_HDISAGG_MISSING
	G_GEO_HH010_5_MISSING
	G_GEO_HH031_BELOW_55
	G_GEO_HH031_BELOW_71
	G_GEO_HB050_GROUPING_1_2_3_4
	G_GEO_HH030_TOPCUT_6
	G_GEO_HX040_TOPCUT_6
	;

/* HY051G HY052G HY053G HY054G 
*	HY061G HY062G HY063G HY064G 
*	HY071G HY072G HY073G HY074G   							  
	* Set (disaggregated variables) to missing 				- rule DISAGG_MISSING
*/
%let G_GEO_HDISAGG_MISSING=				&noDISAG;

/* HH010  												   - rule HH010_MISSING_5
	* Label 5 set to missing: 	5 => . */
%let G_GEO_HH010_5_MISSING=				_ALL_;

/* HH031: year -55    										  
	* Recoding below 55: (<=2000+&y-55) => (2000+&y-55) 	- rule HH031_BELOW_55
	* Recoding below 71: (<=2000+&y-71) => (2000+&y-71) 	- rule HH031_BELOW_71
*/
%let G_GEO_HH031_BELOW_55=				PT;
%let G_GEO_HH031_BELOW_71=				SI;

/* HH030 (number of rooms)  								- rule HH030_TOPCUT_6
	* Top cut to 6:			(>6) => 6*/
%let G_GEO_HH030_TOPCUT_6=				_ALL_;

/* HB050 (Month of HH interview)  					- rule HB050_GROUPING_1_2_3_4
	* Grouping:				(1,2,3) => 1 
							(4,5,6) => 2
							(7,8,9) => 3 
							(10,11,12) => 4 */ 
%let G_GEO_HB050_GROUPING_1_2_3_4=		_ALL_;

/* HX040 (HH size)  										- rule HX040_TOPCUT_6
	* Top cut to 6:			(>6) => 6*/
%let G_GEO_HX040_TOPCUT_6=				MT;

/** R variables *****************************************************************
** MODIFIED ACCORDING TO 2015 DATA AVAILABILITY + RULES COMMUNICATED BY THE    **
** COUNTRIES ********************************************************************
**/

%global 
	G_GEO_RB031_MISSING
	G_GEO_RB070_GROUPING_1_2_3_4
	G_GEO_RB070_MISSING
	G_GEO_RB080_BELOW_80
	G_GEO_RB080_BELOW_81
	G_GEO_RX010_TOPCUT_80
	G_GEO_RX020_TOPCUT_80
	G_GEO_RL050_MISSING
	;

/* RB031   													 - rule RB031_MISSING
	* Set to missing  */
%let G_GEO_RB031_MISSING=				&noRB031;

/* RB070  											
	* Grouping: (1,2,3) => 1 						- rule RB070_GROUPING_1_2_3_4
				(4,5,6) => 2
				(7,8,9) => 3 
				(10,11,12) => 4 
	* Set to missing										 - rule RB070_MISSING
*/
%let G_GEO_RB070_GROUPING_1_2_3_4= 		_ALL_;
%let G_GEO_RB070_MISSING=				DE IE MT NL SI UK;

/* RB080  													  
	* Recoding below 80: (<=2000+&y-80) => (2000+&y-80) 	- rule RB080_BELOW_80
	* Recoding below 81: (<=2000+&y-81) => (2000+&y-81) 	- rule RB080_BELOW_81 
*/
%let G_GEO_RB080_BELOW_80=				PT MT;
%let G_GEO_RB080_BELOW_81=				%list_difference(&_ALL_, &G_GEO_RB080_BELOW_80);

/* RX010 (AGE_IW) 										 
	* Set to missing 									     - rule RX010_MISSING
	* Top cut: 			(>80) => 80 					   - rule RX010_TOPCUT_80
*/
%let G_GEO_RX010_MISSING=				MT;
%let G_GEO_RX010_TOPCUT_80= 			_ALL_;

/* RX020 (AGE)  														
	* Set to missing 										 - rule RX020_MISSING 
	* Top cut: 			(>80) => 80  					   - rule RX020_TOPCUT_80
*/
%let G_GEO_RX020_MISSING=				MT;
%let G_GEO_RX020_TOPCUT_80= 			_ALL_;

/* RL050  													 - rule RL050_MISSING
	* Set to missing when not null */
%let G_GEO_RL050_MISSING=				MT;



/********************************************************************************/
