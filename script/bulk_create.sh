#!/bin/bash
# @name: 	bulk_create
# @brief:   Create bulk CSV files (per survey type/per year/per data type R, D, H, P) from a 
#			hierarchical directory archive of CSV files organised per country/per year.
#
# @notes:
# 1. The command shall be launched inline from a shell terminal running bash (commonly installed
# on all Unix/Linux servers/machines). 
# 2. On Windows, consider using shells provided by Cygwin (https://www.cygwin.com/) or Putty 
# (http://www.putty.org/).
# 3. To launch the command, run on the shell command line:
#			bash bulk_create.sh <arguments>
# with your own arguments/instructions.
# 4. On a Unix server, you may have some DOS-related issue when running this program: in order 
# to deal with embedded control-M's in the file (source of the issue), it may be necessary to 
# run dos2unix, e.g. execute the following:
#			dos2unix bulk_create.sh 
#
# @date:     13/10/2017
# @author: grazzja <jacopo.grazzini@ec.europa.eu>

DEFPREF=UDB_
DEFYEAR=("2003" "2004" "2005" "2006" "2007" "2008" "2009" "2010" \
		"2011" "2012" "2013" "2014" "2015" "2016") 
DEFDATA=("l" "c")
DEFTYPE=("R" "P" "H" "D")

BASHVERS=${BASH_VERSION%.*}

# requirements

hash cat 2>/dev/null ||  { echo >&2 " !!! Command CAT required but not installed - Aborting !!! "; exit 1; }
hash find 2>/dev/null || { echo >&2 " !!! Command FIND required but not installed - Aborting !!! "; exit 1; }
hash read 2>/dev/null || { echo >&2 " !!! Command READ required but not installed - Aborting !!! "; exit 1; }

# useful functions declarations

function  greaterorequal (){
	# arguments: 	1:numeric 2:numeric
	# returns:	 	0 when argument $1 >= $2
	#				1 otherwise
	# note: 0 is the normal bash "success" return value (to be used in a "if...then" test)
	hash awk 2>/dev/null && return `awk -vv1="$1" -vv2="$2" 'BEGIN { print (v1 >= v2) ? 0 : 1 }'`
	hash bc 2>/dev/null && 	return $(bc <<< "$1 < $2") # we test the opposite, see the note above
	# echo "!!! Commands BC or AWK required but not installed - Aborting !!!"
	# exit 1
	# we still have the "pure" bash option based on string comparison...
	if [ ${1%.*} -eq ${2%.*} ] && [ ${1#*.} \> ${2#*.} ] || [ ${1%.*} -gt ${2%.*} ]; then
		return 0
	else
		return 1
	fi
}

function uppercase () {
	# argument: 	1:string
	# returns: 		a uppercase version of $1
	if `greaterorequal ${BASHVERS} 4`; then
		echo ${1^^} # does not work on bash version < 4
	else
		echo  $( tr '[:lower:]' '[:upper:]' <<< $1)
	fi
}

function lowercase () {
	# argument: 	1:string
	# returns: 		a lowercase version of $1
	if `greaterorequal ${BASHVERS} 4`; then
		echo ${1,,} # does not work on bash version < 4
	else
		echo  $( tr '[:upper:]' '[:lower:]' <<< $1)
	fi
}

function contains () {
	# argument: 	1:value 2:list
	# returns: 		0 when the value $1 appears (i.e., is contained) in the list $2
	#				1 otherwise
	# note: 0 is the normal bash "success" return value
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

function trim() {
	# arguments:	1:string
	# returns:		trimmed version of $1
	local var="$*"
	var="${var#"${var%%[![:space:]]*}"}" # remove leading whitespace characters
	var="${var%"${var##*[![:space:]]}"}"  # remove trailing whitespace characters
	echo -n "$var"
}

PROGRAM=`basename $0`
TODAY=`date +'%y%m%d'` # `date +%Y-%m-%d`

case "$(uname -s)" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    CYGWIN*)    MACHINE=Cygwin;;
    MSYS*)      MACHINE=Msys;;
    MINGW*)     MACHINE=MinGw;;
    Windows*)   MACHINE=Windows;;
    SunOS*)     MACHINE=SunOS;;
    *)          MACHINE="UNKNOWN:${OSTYPE}"
esac

function usage() { 
	! [ -z "$1" ] && echo "$1";
	echo "";
    echo "=================================================================================";
    echo "${PROGRAM} : Create bulk CSV files (per survey type/per year/per data type R,";
    echo "D, H, P) from a hierarchical directory archive of CSV files organised per country";
    echo "and per year.";
	echo "";
    echo "Run: ${PROGRAM} -h for further help. Exiting program...";
    echo "=================================================================================";
    echo "";
	exit 1; 
}

function help() {
	! [ -z "$1" ] && echo "$1";
	echo "";
    echo "=================================================================================";
    echo "${PROGRAM} : Create bulk CSV files (per survey type/per year/per data type R, D,";
    echo "H, P) from a hierarchical directory archive of CSV files organised per country/";
    echo "per year.";
    echo "=================================================================================";
    echo "";
    echo "Syntax";
 	echo "------";
    echo "    ${PROGRAM} [-o <odir>] [-f <survey>] [-y <year>] [-d <type>] [-p <pref>]";
    echo "                  [-h] [-v] [-t] <idir>";
    echo "";
    echo "Parameters";
  	echo "----------";
    echo " <idir>    : input directory storing the UDB release of anonymised datasets as";
    echo "             prepared and transmitted by Eurostat; this is expected to be composed of";
	echo "             two subfolders Cross/ and/or Long that contain the datasets organised per";
	echo "             country, e.g. its structure will look like:"; 
	echo "                    |-- Cross";
	echo "                    |   |-- AT";
	echo "                    |   |   |-- 2016";
	echo "                    |   |   |   |-- UDB_cAT16D.csv";
	echo "                    |   |   |   |-- UDB_cAT16P.csv";
	echo "                    |   |   |   |-- UDB_cAT16H.csv";
	echo "                    |   |   |   |-- UDB_cAT16R.csv";
	echo "                    |   |   |-- 2015";
	echo "                    |   |   |   |-- UDB_cAT15D.csv";
	echo "                    |   |   |   |-- UDB_cAT15P.csv";
	echo "                    |   |   |   |-- UDB_cAT15H.csv";
	echo "                    |   |   |   |-- UDB_cAT15R.csv";
	echo "                    |   |   |-- 2014";
	echo "                    |   |   |   |-- ...";
	echo "                    |   |   |-- ...";
	echo "                    |   |-- BE";
	echo "                    |   |   |-- 2016";
	echo "                    |   |   |-- ...";
	echo "                    |   |-- ...";
	echo "                    |-- Long";
	echo "                    |-- ...";
    echo " -o <odir> : (option) output directory where the bulk UDB datasets will be stored,";
	echo "             one for every survey year, every data type and all countries, e.g. its";
	echo "             structure will look like:";
	echo "                    |-- Cross";
	echo "                    |   |-- 2016";
	echo "                    |   |   |-- UDB_c16D.csv";
	echo "                    |   |   |-- UDB_c16H.csv";
	echo "                    |   |   |-- UDB_c16R.csv";
	echo "                    |   |   |-- UDB_c16P.csv";
	echo "                    |   |-- 2015";
	echo "                    |   |   |-- UDB_c15D.csv";
	echo "                    |   |   |-- UDB_c15H.csv";
	echo "                    |   |   |-- UDB_c15R.csv";
	echo "                    |   |   |-- UDB_c15P.csv";
	echo "                    |   |-- ...";
	echo "                    |-- Long";
	echo "                    |   |-- 2016";
	echo "                    |   |   |-- UDB_l16D.csv";
	echo "                    |   |   |-- UDB_c16H.csv";
	echo "                    |   |   |-- UDB_c16R.csv";
	echo "                    |   |   |-- UDB_c16P.csv";
	echo "                    |   |-- 2015";
	echo "                    |   |   |-- UDB_l15D.csv";
	echo "                    |   |   |-- UDB_l15H.csv";
	echo "                    |   |   |-- UDB_l15R.csv";
	echo "                    |   |   |-- UDB_l15P.csv";
	echo "                    |-- ...";
	echo "             when not set (default), the input folder is used as output directory;";
	echo "             named <pref>_c11R.csv; default prefix: UDB_";
	echo " -f <survey> : (option) specify the survey to explore, either cross-sectional (C or Cross)";
	echo "             or longitudinal (L or Long); when empty, both databases are explored;note that";
	echo "             ALL is also accepted and is equivalent to an empty argument; default: ALL;"
	echo " -y <year> : (option) year to merge; for every single year, 1 to 4 bulk (see option '-d'"; 
	echo "             below) will be generated; when empty, all available years are taken; ibid, ALL" 
	echo "             is equivalent to an empty argument; default: ALL (from 2003 onwards);"
    echo " -d <type> : (option) datatype, i.e. any character among R, P, H, D; when empty, all data"; 
	echo "             are processed so as to produce 4 different bulk files; ibid, ALL is"; 
	echo "             equivalent to an empty argument; default: ALL;"
	# echo " -b <by> :   (option) flag defining the hierarchical structure in both the input and";
	# echo "             output directories; it can be either 'GEO' (default) or 'TIME'; in the";
	# echo "             first case (GEO) the output directory will be organised as (like example";
	# echo "             above):";
	# echo "                    |-- Cross";
	# echo "                    |   |-- AT";
	# echo "                    |   |   |-- 2014";
	# echo "                    |   |   |   |-- UDB_cAT14D.csv";
	# echo "                    |   |   |   |-- UDB_cAT14P.csv";
	# echo "                    |   |   |   |-- UDB_cAT14H.csv";
	# echo "                    |   |   |   |-- UDB_cAT14R.csv";
	# echo "                    |   |   |-- 2013";
	# echo "                    |   |   |   |-- UDB_cAT13D.csv";
	# echo "                    |   |   |   |-- UDB_cAT13P.csv";
	# echo "                    |   |   |   |-- UDB_cAT13H.csv";
	# echo "                    |   |   |   |-- UDB_cAT13R.csv";
	# echo "                    |   |   |-- ...";
	# echo "                    |   |-- BE";
	# echo "                    |   |   |-- 2014";
	# echo "                    |   |   |   |-- UDB_cBE14D.csv";
	# echo "                    |   |   |   |-- UDB_cBE14P.csv";
	# echo "                    |   |   |   |-- UDB_cBE14H.csv";
	# echo "                    |   |   |   |-- UDB_cBE14R.csv";
	# echo "                    |   |   |-- 2013";
	# echo "                    |   |   |   |-- UDB_cBE13D.csv";
	# echo "                    |   |   |   |-- UDB_cBE13P.csv";
	# echo "                    |   |   |   |-- UDB_cBE13H.csv";
	# echo "                    |   |   |   |-- UDB_cBE13R.csv";
	# echo "                    |   |   |-- ...";
	# echo "                    |   |-- ...";
	# echo "                    |-- Long";
	# echo "                    |-- ...";
	# echo "              and so forth, while in the second case (TIME), it will look like:"
	# echo "                    |-- Cross";
	# echo "                    |   |-- 2014";
	# echo "                    |   |   |-- AT";
	# echo "                    |   |   |   |-- UDB_cAT14D.csv";
	# echo "                    |   |   |   |-- UDB_cAT14P.csv";
	# echo "                    |   |   |   |-- UDB_cAT14H.csv";
	# echo "                    |   |   |   |-- UDB_cAT14R.csv";
	# echo "                    |   |   |-- BE";
	# echo "                    |   |   |   |-- UDB_cBE14D.csv";
	# echo "                    |   |   |   |-- UDB_cBE14P.csv";
	# echo "                    |   |   |   |-- UDB_cBE14H.csv";
	# echo "                    |   |   |   |-- UDB_cBE14R.csv";
	# echo "                    |   |-- 2013";
	# echo "                    |   |   |-- AT";
	# echo "                    |   |   |   |-- UDB_cAT13D.csv";
	# echo "                    |   |   |   |-- UDB_cAT13P.csv";
	# echo "                    |   |   |   |-- UDB_cAT13H.csv";
	# echo "                    |   |   |   |-- UDB_cAT13R.csv";
	# echo "                    |   |   |-- BE";
	# echo "                    |   |   |   |-- UDB_cBE13D.csv";
	# echo "                    |   |   |   |-- UDB_cBE13P.csv";
	# echo "                    |   |   |   |-- UDB_cBE13H.csv";
	# echo "                    |   |   |   |-- UDB_cBE13R.csv";
	# echo "                    |   |-- ...";
	# echo "                    |-- Long";
	# echo "                    |-- ...";
	# echo "             and so forth; note that the case FLAT, where all files are stored under"; 
	# echo "             <odir>, has NOT been implemented yet";
	# echo " -e <ext> :  (option) string defining the input/output format; default: 'csv';";
    echo " -p <pref> : (option) generic prefix name used to name the input split files; it will";
	echo "             also be used to name thee output bulk files merged from all; e.g., the";
	echo "             file merged from 2010 available cross-sectional register data will be";
    # echo " -s <suff> : (option) ibid for generic suffix used to name all input files; default"; 
	# echo "             is '', i.e. no suffix is considered;";
    echo " -h        : (option) display this help;";
    echo " -v        : (option) verbose mode (all kind of useless comments...);";
	echo " -t        : (option) test the process; launch with your arguments to see the list of";
	echo "              operations that will actually be run; recommended."
	echo "";
    echo "Examples";
	echo "--------";
    echo " Say that the input directory (with Cross/ and Long/ subfolders) where the split";
	echo " CSV files are stored is named 17-09_release/ in your domain. You can already create";
	echo " an output folder, say 17-09_release_bulk/, so as to store the bulk files. Run for";
	echo " instance:";
	echo "   >    bash bulk_create.sh -p UDB_ -f C -y 2010 -d R";
	echo "                            -o 17-09_release_bulk/ 17-09_release/";
    echo " to create a single bulk file UDB_c10R.csv merging all available R data from all";
	echo " countries in the output folder 17-09_release_bulk/Cross/2010/.";
	echo "   >    bash bulk_create.sh -p UDB_ -f L -y 2010 -y 2011 -d R -d H";
	echo "                            -o 17-09_release_bulk/ 17-09_release/";
    echo " to create 4 bulk files, i.e. UDB_l10R.csv, UDB_l10H.csv, UDB_l11R.csv, and UDB_l11H.csv";
	echo " the first two being stored in 17-09_release_bulk/Long/2010/, while the last two are";
	echo " saved in 17-09_release_bulk/Long/2011/".;
	echo "   >    bash bulk_create.sh -p UDB_ -y 2010";
	echo "                            -o 17-09_release_bulk/ 17-09_release/";
    echo " to create all bulk files normally available in 2010, i.e.: UDB_c10R.csv, UDB_c10H.csv,";
	echo " UDB_c10D.csv, and UDB_l0P.csv, as well as  UDB_l10R.csv, UDB_l10H.csv, UDB_l10D.csv and";
	echo " UDB_l10P.csv (in folder 17-09_release_bulk/Cross/2010/ for the cross-sectional data, and";
	echo " in folder 17-09_release_bulk/Long/2010/ for the longitudinal ones).";
	echo "";
    echo "Notes";
	echo "----";
	echo " 1. If like in the example above, you want to create the bulk files all at once, simply";
	echo "   run (in verbose mode):";
	echo "   >    bash bulk_create.sh -v -p UDB_ -f ALL -y ALL -d ALL";
	echo "                            -o 17-09_release_bulk/ 17-09_release/";
	echo "   This is also equivalent too:"
	echo "   >    bash bulk_create.sh -v -p UDB_ -o 17-09_release_bulk/ 17-09_release/";
	echo "   This may take a while...";
	echo " 2. It is strongly recommended to run a test before, e.g. prior to run the command above";
	echo "   test it with:"
	echo "   >    bash bulk_create.sh -t -v -p UDB_ -f ALL -y ALL -d ALL";
	echo "                            -o 17-09_release_bulk/ 17-09_release/";
	echo " 3. The output directory <odir> needs to be created prior to running the program. Its";
	echo "   subfolders however will be created whenever needed."
	echo " 4. The output bulk files, if they exist prior to running the program, will be;"
	echo "   systematically replaced."
	echo " 5. Pass the input and output directories arguments with the full paths.";
	echo " 6. The options '-f', '-y', and '-d' can be used multiple times into a single";
	echo "   command so as to pass multiple arguments."
	echo "";
    echo "     European Commission   -   DG ESTAT   -   The EU-SILC team    -   2017       ";
    echo "=================================================================================";
    echo "";
    exit 1;
}

## basic checks: command error or help
[ $# -eq 0 ] && usage
# [ $# -eq 1 ] && [ $1 = "--help" ] && help

## Some useful internal paramaters

ALPHAREG='.*/[[:alpha:]]{2}'   	# or './[a-Z]{2}': ISO-codes of countries 
DIGITREG='.*/[[:digit:]]{4}' 	# or './2[0-9]{3}': survey year 

# machine dependent (or not) options for FIND command
if [ "${MACHINE}" == "Mac" ]; then 
	OPTFIND=-E #BSD predicate
	OPTREGEX=
else
	OPTFIND=
	OPTREGEX=("-regextype" "posix-extended") #"-regextype posix-awk"  #
fi
OPTDEPTH=("-mindepth" "1" "-maxdepth" "1") # declared as an array: see http://mywiki.wooledge.org/BashFAQ/050
	
## Define (set/pass) the script paramaters

# set the default values
IDIR=
ODIR=
DATA=()
YEAR=()
TYPE=()
PREF=
VERB=0
TESTECHO=

# fixed...
EXT=CSV
DIRBY=GEO
SUFF=
DUMMYSTRING=___DUMMY

# we use getopts to pass the arguments
# options are: [-o <odir>] [-b <dirby>] [-s <suff>] [-p <pref>] [-z <arch>] [-a <op>]

while getopts :o:y:f:p:d:htv OPTION; do
	# extract options and their arguments into variables.
	case $OPTION in
	o) ODIR=$OPTARG
		# check the existence of the directory
		[ -d "$ODIR" ] || usage "!!! Output directory ODIR=$ODIR not found - Exiting !!!"
		;;
    y) YEAR+=("$OPTARG")
		;;
    f) arg=`lowercase $OPTARG`
		[ "$arg" == "l" ] || [ "$arg" == "long" ] || [ "$arg" == "c" ] || [ "$arg" == "cross" ] \
			|| usage "!!! Argument DATA=$OPTARG not recognised - Exiting !!! "	
		DATA+=("$arg")
		;;
    p) PREF=$OPTARG
		;;
    #s) SUFF=$OPTARG
	#	;;
    #e) EXT=$OPTARG
	#	;;
    d) arg=`uppercase $OPTARG`
		[ "$arg" == "R" ] || [ "$arg" == "D" ] || [ "$arg" == "P" ] || [ "$arg" == "H" ] \
			|| [ "$arg" == "ALL" ] || usage "!!! Argument TYPE=$OPTARG not recognised - Exiting !!! "
		TYPE+=("$arg")
		;;
	#b) DIRBY=$OPTARG
	#	[ "$DIRBY" == "GEO" ] || [ "$DIRBY" == "TIME" ] || usage "!!! Argument DIRBY=$DIRBY not recognised - Exiting !!! "
	#	;;
    #e) EXT=$OPTARG
	#	;;
    h) help #show help
		;;
	t) TESTECHO=("echo" "  ... run:")
		;;
    v) VERB=1
		;;
    \?) #unrecognized option - show help
      usage "!!! option $OPTARG not allowed - Exiting !!!"
		;;
	esac
done

shift $((OPTIND-1))  

# further checks (possible after the shifts above)
[ $# -lt 1 ] && usage "!!! Missing input IDIR argument - Exiting !!!"
[ $# -gt 1 ] && usage "!!! Only one argument can be passed - Exiting !!!"

# retrieve the input directory
IDIR=$1
[ -d "${IDIR}" ] || usage "!!! Input directory IDIR=${IDIR} not found - Exiting !!!"

# set the default output directory
if [ -z "${ODIR}" ]; then
	ODIR=${IDIR}
fi

# test the organisation/structure of the input directory
! [ -d "${IDIR}/Cross" ] && ! [ -d "${IDIR}/Long" ] \
	&& usage "!!! Cross/ and Long/ subfolders are missing in ${IDIR} - Exiting !!!"
	
# set the default survey format
if [ ${#DATA[@]} -eq 0 ] || ([ ${#DATA[@]} -eq 1 ] && [ "${DATA[@]}" = "ALL" ]); then
	DATA=("${DEFDATA[@]}")
fi
	
# set the default data types
if [ ${#TYPE[@]} -eq 0 ] || ([ ${#TYPE[@]} -eq 1 ] && [ "${TYPE[@]}" = "ALL" ]); then
	TYPE=("${DEFTYPE[@]}")
fi
	
# set the default data types
if [ ${#YEAR[@]} -eq 0 ] || ([ ${#YEAR[@]} -eq 1 ] && [ "${YEAR[@]}" = "ALL" ]); then
	YEAR=("${DEFYEAR[@]}")
fi
	
# check other parameters 
if [ -z ${PREF} ]; then
	PREF=${DEFPREF}
fi

# verbose announcements	
[ ${VERB} -eq 1 ] 	&& ( echo "";					   				\
			    echo "# Operation parameters..."; 		   			\
			    echo "  - input directory:         ${IDIR}";	   	\
			    echo "  - output directory:        ${ODIR}";		\
			    echo "  - survey format(s) merged: ${DATA[@]}";		\
			    echo "  - data type(s) merged:     ${TYPE[@]}";		\
			    echo "  - year(s) converted:       ${YEAR[@]}";		\
				echo "  - generic output prefix:   ${PREF}" );	  
				
# function for mulitplt similar file merging
function udb_file_merge() {
	# arguments: 	1:input 2:odir 3:data 4:type 5:year 6:pref 7:ext 8:verbose 
	# returns: 		merge different split CSV file from same year, same survey type 
	#			 	and same datatype into a single bulk file

	if [ "${MACHINE}" == "Mac" ]; then 
		predicate=-E #BSD predicate
	else
		predicate= #"-regextype posix-awk"
	fi
		
	pref=$6
	data=`lowercase ${3:0:1}` # first char in lower case
	type=`uppercase ${4:0:1}` # ibid in upper case
	year=$5 
	yy=${year:2:3} # the last two digits
	ext=`lowercase $7`

	# build the output filename
	bulk=${pref}${data}${yy}${type}.${ext}
	[ -f ${2}/${bulk} ] && echo "! Output file ${2}/${bulk} already exists - It will be deleted !" && ${TESTECHO[@]} rm -f ${2}/${bulk};
	
	# build the	string used as a search basename for the input files
	search="${pref}*${data}*${yy}${type}*"
	# search is of the form <pref>*<year><type>.csv, e.g. to retrieve 2013 register cross-sectional
	# data from Austria, we look for the file: UDB_cAT13R.csv or UDB_cAT13R.CSV

	# if [ $6 == "FLAT" ]; then
	# 	[ ${VERB} -eq 1 ] && echo "  - copy all files from $1 to $2"
	# 	echo 
	# elif ! ([ $6 == "GEO" ] || [ $6 == "TIME" ]); then
	# 	echo "!!! Internal error !!!" ; exit 1;
	# fi
	# if [ $6 == "GEO" ]; then
	regdir1=${ALPHAREG}
	dir2=$5
	# elif [ $6 == "TIME" ]; then
	# 	dir1=$5
	# 	regdir2=${ALPHAREG}
	# fi

	# store the original IFS
	oIFS=${IFS}
	# see also: https://unix.stackexchange.com/questions/9496/looping-through-files-with-spaces-in-the-names
	# the following IFS setting prevents the word-splitting of filenames with blanks 
	IFS=$'\n'
	
	# a flag of existence... essentially created for test case
	bulkexist=0
	
	[ ${VERB} -eq 1 ] && echo "  => Listing contents of output bulk file ${bulk}"
	# explore the hierarchy (by alphabetical order)
	for path1 in `find ${OPTFIND} $1 ${OPTDEPTH[@]} ${OPTREGEX[@]} -type d -regex ${regdir1} | sort`; do
		dir1=${path1##*/}
		# check whether a directory with the required name exists
		if  ! [ -d $1/${dir1}/${dir2} ]; then
			[ ${VERB} -eq 1 ] && echo "  - nothing added for ${dir1} in ${year} (no data available)"
			continue
		fi 
		[ ${VERB} -eq 1 ] && [ -z `find ${path1}/${dir2} ${OPTDEPTH[@]} -type f -name "*${search}"` ] \
			&&  echo "  - nothing added for ${dir1} in ${year} (no filename matching)"
		# the process substitution below ensures that the flag bulkexist "survives" the pipeline
		# see http://mywiki.wooledge.org/BashFAQ/024 and http://mywiki.wooledge.org/ProcessSubstitution
		while IFS= read -r -d '' file; do
			if [ "`lowercase ${file##*.}`" != "${ext}" ]; then
				[ ${VERB} -eq 1 ] && echo "  - nothing added for ${dir1} in ${year} (wrong extension)"
				continue
			fi
			# tail reminder: -n +K to output starting with the Kth
			[ ${VERB} -eq 1 ] && echo "  - adding ${year} ${type} data from ${dir1}"
			if [ ${bulkexist} -eq 0 ] && ! [ -f ${2}/${bulk} ]; then 	# create the file
				# create the folder in the case it does not already exist in the output directory
				[ -z "${TESTECHO}" ] && mkdir -p $2/${dir2}/ 
				([ ${VERB} -eq 1 ] || ! [ -z "${TESTECHO}" ]) && echo "  ... run: cat ${file} > $2/${dir2}/${bulk}"
				[ -z "${TESTECHO}" ] && cat ${file} > $2/${dir2}/${bulk}
				bulkexist=1
			else 						# add to the existing file, without the header however
				([ ${VERB} -eq 1 ] || ! [ -z "${TESTECHO}" ]) && echo "  ... run: tail -n +2 ${file} | cat >> $2/${dir2}/${bulk}"
				[ -z "${TESTECHO}" ] && tail -n +2 ${file} | cat >> $2/${dir2}/${bulk}				
			fi
		done < <(find ${path1}/${dir2} ${OPTDEPTH[@]} -type f -name "*${search}" -print0 | sort)
	done

	# reset the original IFS
	IFS=${oIFS}	
}

if `contains "l" "${DATA[@]}"`; then
	if ! [ -d "${IDIR}/Long" ]; then
		[ ${VERB} -eq 1 ] && echo "" && echo "# No Long folder found - Skip ... " 
	else
		[ ${VERB} -eq 1 ] && echo "# Exploring longitudinal data ... "
		for y in "${YEAR[@]}"; do
			for t in "${TYPE[@]}"; do
				([ ${VERB} -eq 1 ] || ! [ -z "${TESTECHO}" ]) && echo "" && echo " * Preparing bulk file for survey: L, year: ${y}, and type: ${t}" 
				# run the script for all parameters provided
				udb_file_merge ${IDIR}/Long ${ODIR}/Long L ${t} ${y} ${PREF} ${EXT} ${VERB} 
			done
		done
	fi
fi

[ ${VERB} -eq 1 ] && echo ""
 
if `contains "c" "${DATA[@]}"`; then
	if ! [ -d "${IDIR}/Cross" ]; then
		[ ${VERB} -eq 1 ] && echo "" && echo "# No Cross folder found - Skip ... " 
	else
		[ ${VERB} -eq 1 ] && echo "# Exploring cross-sectional data ... "
		for y in "${YEAR[@]}"; do
			for t in "${TYPE[@]}"; do
				([ ${VERB} -eq 1 ] || ! [ -z "${TESTECHO}" ]) && echo "" && echo " * Preparing bulk file for survey: C, year: ${y}, and type: ${t}" 
				# run the script for all parameters provided
				udb_file_merge ${IDIR}/Cross ${ODIR}/Cross C ${t} ${y} ${PREF} ${EXT} ${VERB}  
			done
		done
	fi
fi
