#!/bin/bash
# @name: 	latest_genesis
# @brief:   Split a bulk CSV archive file and create a hierarchical directory structure 
#			of CSV files organised per country/per year.
#
# @notes:
# 1. This is a "one-shot" script, i.e. you will probably never need to run it again after
# the files have been created; it is kept for maintenance and tracability purpose.
# 2. Some DOS-related issue when running this command: in order to deal with embedded control-M's 
# in the file (source of the issue), it may be necessary to run dos2unix; launch it using a 
# PuTTY terminal, e.g. running:
#		dos2unix latest_genesis.sh 
#
# @date:     17/09/2017
# @author: grazzja <jacopo.grazzini@ec.europa.eu>

# DIRNEWCRONOS=/cygdrive/z/IDB_RDB/newcronos

BASHVERS=${BASH_VERSION%.*}

PROGRAM=`basename $0`

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

if [ "${MACHINE}" == "Cygwin" ]; then
	DRIVE=$(echo `mount --show-cygdrive-prefix` | sed -e 's/Prefix//;s/Type//;s/Flags//;s/user//;s/binmode//')
else
	DRIVE=/
fi 
trim() {
   local var="$*"
   var="${var#"${var%%[![:space:]]*}"}" # remove leading whitespace characters
   var="${var%"${var##*[![:space:]]}"}"  # remove trailing whitespace characters
   echo -n "$var"
}
DRIVE=`trim $DRIVE`

# ROOTDIR=`pwd`
if ! [ "${DRIVE:-1}" == "/" ]; then
	ROOTDIR=${DRIVE}/z #0eusilc?
else
	ROOTDIR=${DRIVE}z
fi

function usage() { 
	! [ -z "$1" ] && echo "$1";
	echo "";
    echo "=================================================================================";
    echo "${PROGRAM} : Split a bulk CSV archive file into a hierarchical directory";
    echo "              of CSV files organised per country/per year";
    echo "Run: ${PROGRAM} -h for further help. Exiting program...";
    echo "=================================================================================";
    echo "";
	exit 1; 
}

help() {
	! [ -z "$1" ] && echo "$1";
	echo "";
    echo "=================================================================================";
    echo "${PROGRAM} : Split a bulk CSV archive file into a hierarchical directory.";
    echo "              of CSV files organised per country/per year";
    echo "=================================================================================";
    echo "";
    echo "Syntax";
 	echo "------";
    echo "    ${PROGRAM} [-o <odir>] [-f <ofn>] [-e <ext>] [-c <lim>] [-b <by>]";
    echo "                  [-h] [-v] [-t] <idir>";
    echo "";
    echo "Parameters";
  	echo "----------";
    echo " <idir>    : input directory storing the bulk UDB datasets; this is composed of";
	echo "             subfolders with digital names that contain the bulk UDB datasets, e.g.";
	echo "             it will look like:";
	echo "                    | ...";
	echo "                    |-- 2013";
	echo "                    |   |-- UDB_c13D_ver 2013-4 from 01-03-17.csv";
	echo "                    |   |-- UDB_c13H_ver 2013-4 from 01-03-17.csv";
	echo "                    |   |-- UDB_c13P_ver 2013-4 from 01-03-17.csv";
	echo "                    |   |-- UDB_c13R_ver 2013-4 from 01-03-17.csv";
	echo "                    |-- 2014";
	echo "                    |   |-- UDB_c14D_ver 2014-3 from 01-03-17.csv";
	echo "                    |   |-- UDB_c14H_ver 2014-3 from 01-03-17.csv";
	echo "                    |   |-- UDB_c14P_ver 2014-3 from 01-03-17.csv";
	echo "                    |   |-- UDB_c14R_ver 2014-3 from 01-03-17.csv";
	echo "                    | ...";
    echo " -o <odir> : (option) output directory where the split programs are stored; when not";
    echo "             set (default), <idir> is used as the output directory;";
    echo " -f <ofn> :  (option) generic name used as a prefix for the output split files; default";
    echo "             is 'UDB_c';";
    echo " -e <ext> :  (option) type (i.e. format) of the output files; default is 'csv', but 'txt'";
    echo "             is also accepted;";
    echo " -c <lim> :  (option) delimiter used in input file; default is ',';";
	echo " -b <by> :   (option) flag defining the hierarchical structure in the output directory";
	echo "             <odir>; it can be either 'GEO' (default), 'TIME' or 'FLAT'; in the first case";
	echo "             (GEO) the output directory will be organised as:";
	echo "                    | ...";
	echo "                    |-- AT";
	echo "                    |   |-- 2013";
	echo "                    |   |   |-- UDB_cAT13D.csv";
	echo "                    |   |   |-- UDB_cAT13P.csv";
	echo "                    |   |   |-- UDB_cAT13H.csv";
	echo "                    |   |   |-- UDB_cAT13R.csv";
	echo "                    |   |-- 2014";
	echo "                    |   |   |-- UDB_cAT14D.csv";
	echo "                    |   |   |-- UDB_cAT14P.csv";
	echo "                    |   |   |-- UDB_cAT14H.csv";
	echo "                    |   |   |-- UDB_cAT14R.csv";
	echo "                    |   | ...";
	echo "                    |-- BE";
	echo "                    |   |-- 2013";
	echo "                    |   |   |-- UDB_cBE13D.csv";
	echo "                    |   |   |-- UDB_cBE13P.csv";
	echo "                    |   |   |-- UDB_cBE13H.csv";
	echo "                    |   |   |-- UDB_cBE13R.csv";
	echo "                    |   |-- 2014";
	echo "                    |   |   |-- UDB_cBE14D.csv";
	echo "                    |   |   |-- UDB_cBE14P.csv";
	echo "                    |   |   |-- UDB_cBE14H.csv";
	echo "                    |   |   |-- UDB_cBE14R.csv";
	echo "                    |   | ...";
	echo "                    | -- ...";
	echo "              and so forth, while in the second case (TIME), it will look like:"
	echo "                    | ...";
	echo "                    |-- 2013";
	echo "                    |   |-- AT";
	echo "                    |   |   |-- UDB_cAT13D.csv";
	echo "                    |   |   |-- UDB_cAT13P.csv";
	echo "                    |   |   |-- UDB_cAT13H.csv";
	echo "                    |   |   |-- UDB_cAT13R.csv";
	echo "                    |   | ...";
	echo "                    |   |-- BE";
	echo "                    |   |   |-- UDB_cBE13D.csv";
	echo "                    |   |   |-- UDB_cBE13P.csv";
	echo "                    |   |   |-- UDB_cBE13H.csv";
	echo "                    |   |   |-- UDB_cBE13R.csv";
	echo "                    |   |-- ...";
	echo "                    |-- 2014";
	echo "                    |   |-- AT";
	echo "                    |   |   |-- UDB_cAT14D.csv";
	echo "                    |   |   |-- UDB_cAT14P.csv";
	echo "                    |   |   |-- UDB_cAT14H.csv";
	echo "                    |   |   |-- UDB_cAT14R.csv";
	echo "                    |   |-- BE";
	echo "                    |   |   |-- UDB_cBE14D.csv";
	echo "                    |   |   |-- UDB_cBE14P.csv";
	echo "                    |   |   |-- UDB_cBE14H.csv";
	echo "                    |   |   |-- UDB_cBE14R.csv";
	echo "                    |   |-- ...";
	echo "              and so forth; as for the last case (FLAT), all files are stored under <odir>";
    echo " -h        : (option) display this help;";
    echo " -v        : (option) verbose mode (all kind of useless comments...);";
	echo " -t        : (option) test the process; run with your arguments to see the list of";
	echo "              operations that will actually be realised; recommended."
	echo "";
    echo "Examples";
	echo "--------";
    echo " TBD";
    echo "";
    echo " European Commission - DG ESTAT - The EU-SILC team (aka me, myself and I) - 2017 ";
    echo "=================================================================================";
    echo "";
    exit 1;
}

## basic checks: command error or help
[ $# -eq 0 ] && usage
# [ $# -eq 1 ] && [ $1 = "--help" ] && help

## Define (set/pass) the script paramaters
 
VERB=0
 
# set the default values
IDIR=
ODIR=
SURVEY=
ONAME=UDB
EXT=csv
DELIM=,
DIRBY=GEO


# we use getopts to pass the arguments
# options are: [-o <odir>] [-b <dirby>] [-s <suff>] [-p <pref>] [-z <arch>] [-a <op>]

while getopts :o:a:p:s:z:b:htv OPTION; do
	# extract options and their arguments into variables.
	case $OPTION in
	o) ODIR=$OPTARG
		# check the existence of the directory
		[ -d "$ODIR" ] || usage "!!! Output directory ODIR=$ODIR not found - Exiting !!!"
		;;
    f) ONAME=$OPTARG
		;;
    e) EXT=$OPTARG
		# check that the format is supported
		[ "$EXT" == "ext" ] || [ "$EXT" == "txt" ] || usage "!!! Format EXT=$EXT not supported - Exiting !!!"; 
        ;;
    c) DELIM=$OPTARG;;
	b) DIRBY=$OPTARG
		# check that the proposed structure is supported
		[ "$DIRBY" == "GEO" ] || [ "$DIRBY" == "TIME" ] || usage "!!! Argument DIRBY=$DIRBY not recognised - Exiting !!! "
		;;
    h) help #show help
		;;
	t) TESTECHO=("echo" "..."  "run:")
		;;
    v) VERB=1
		;;
    \?) #unrecognized option - show help
      usage "!!! option $OPTARG not allowed - Exiting !!!"
		;;
     #: )
     #  echo "Invalid option: $OPTARG requires an argument" 1>&2
     # ;;
	esac
done

shift $((OPTIND-1))  #This tells getopts to move on to the next argument.

# # variant with getopt : we avoid... 
# TEMP=`getopt -o o:f:e:c:b:vh --long odir:,oname:,ext:,delim:,dirby:,help,verb -n '${PROGRAM}' -- "$@"`
# eval set -- "$TEMP"
# while true ; do
#      case "$1" in
#          -h|--help) help;; 
#          -o|--odir)
# 			[ -d "$2" ] || usage "!!! Output directory ODIR=$2 not found - Exiting !!!";
#             ODIR=$2; shift 2;;
#          -f|--oname)
#             ONAME=$2; shift 2;;
#          -e|--ext)
# 			[ "$2" == "ext" ] || [ "$2" == "txt" ] || usage "!!! Format EXT=$2 not supported - Exiting !!!"; 
#             EXT=$2; shift 2;;
#          -c|--delim)
#             DELIM=$2; shift 2;;
# 		 -b|--dirby) 
# 			[ "$2" == "GEO" ] || [ "$2" == "TIME" ] || [ "$2" == "FLAT" ] || usage "!!! Argument DIRBY=$2 not recognised - Exiting !!! "; 
# 			DIRBY=$2; shift 2;;
#          -v|--verb) VERB=1; shift;;
#          --) shift; break;;
#          *) echo "!!! Internal error !!!" ; exit 1;;
#      esac 	 
# done

# further checks (possible after the shifts above)
[ $# -lt 1 ] && usage "!!! Missing input IDIR argument - Exiting !!!"
[ $# -gt 1 ] && usage "!!! Only one argument can be passed - Exiting !!!"

# retrieve the input directory
IDIR=$1
[ -d "${IDIR}" ] || usage "!!! Input directory IDIR=${IDIR} not found - Exiting !!!"

# set the input directory
if [ -z "${ODIR}" ]; then
	ODIR=${IDIR} # no need to check at this stage
fi

[ ${VERB} -eq 1 ] 	&& (echo "";					   			\
			    echo "# Setting parameters..."; 		   \
			    echo "  - input directory: ${IDIR}";	   \
			    echo "  - file type: ${EXT}";	      	   \
			    echo "  - output directory: ${ODIR}";     	   \
			    echo "  - output generic naming: ${ONAME}";	   \
			    echo "  - directory organisation: ${DIRBY}")

function udb_file_split() {
	# arguments: 	1:input 2:oname 3:odir 4:ext 5:delim 6:dirby 7:verbose 
	# returns: split cross-sectional or longitudinal files organised into a hierarchical directory structure 
	# see also:
	# https://unix.stackexchange.com/questions/343720/how-to-split-a-csv-file-per-initial-column-with-headers

	# note the difficulty with longitudinal files: more than one year is available for each country; those
	# need however to be merged together
	
	# create the array (note the presence of outside parentheses) of distinct years
	years=( $(awk -F , 'NR>1 { a[$1]++ } END { for (b in a) { print b } }' $1) )
	# note that in the case of cross-sectional data, there should be a unique year
	nyears=${#years[@]}
	# initialise the variable YEAR with the first year in the list
	year=${years[0]}
	# look for the most recent year, i.e. the maximum value of YEARS, starting from YEAR
	for y in "${years[@]}" ; do
		((y > year)) && year=$y
	done
	# this will work indifferently for cross-sectional and longitudinal files

	if [ $6 == "GEO" ]; then
	# 	awk -v o="$2" -v d="$3" -v e="$4" -v FS="$5" -v v=$7 \
	# 	   'NR==1{h=$0; l=substr($0,1,1); next};
	# !seen[$1,$2]++{system("test -d "d"/"$2"/"$1" || (mkdir -p "d"/"$2"/"$1" && test "v" && echo ... creating folder "d"/"$2"/"$1")"); 
	# f=d"/"$2"/"$1"/"o$2substr($1,3,2)l"."e; system("test "v" && echo ... ... extracting file "o$2substr($1,3,2)l"."e); print h > f};
	# {f=d"/"$2"/"$1"/"o$2substr($1,3,2)l"."e; print >> f; 
	# close(f)}' $1
	#
	# note: since we know that YEAR defined above will be used for generating the filename,
	# may it be cross-sectional or longitudinal, we actually replace the search option !seen[$1,$2] 
	# by !seen[$2] (uniquiness search on country only)
		awk -v o="$2" -v d="$3" -v e="$4" -v FS="$5" -v v=$7 -v y=${year} \
		   'NR==1{h=$0; l=substr($0,1,1); next};
	!seen[$2]++{system("test -d "d"/"$2"/"y" || (mkdir -p "d"/"$2"/"y" && test "v" && echo ... creating folder "d"/"$2"/"y")"); 
	f=d"/"$2"/"y"/"o$2substr(y,3,2)l"."e; system("test "v" && echo ... ... extracting file "o$2substr(y,3,2)l"."e); print h > f};
	{f=d"/"$2"/"y"/"o$2substr(y,3,2)l"."e; print >> f; 
	close(f)}' $1
	# Explanation:
	#  -v o="$2" : assign the value of the 2nd argument of the script to the awk variable o;
	#  -v d="$3" : ibid with the 3rd argument of the script to the awk variable d; 
	#  -v d="$4" : ibid with the 4th argument of the script to the awk variable e; 
	#  -v FS=$5 : define the field separator FS as the 5th argument of the script (e.g., the
	#		delimiter ','); this will ensure that the awk parameters $1, $2 etc. (i.e., the 
	#		ones that appear in the command) refer to the CSV columns (rather than, for 
	#		instance, space separated values);
	#  NR==1{h=$0; l=substr($0,1,1); next} : treat the first line specially (NR==1), by storing 
	#		the full header line in a variable h (h=$0), retrieving the type of the file (first
	#		char of the header (l=substr($0,1,1)), since it is usually RB010, DB010, PB010 or 
	#		HB010, and skip the line (next);
	#  !seen[$1,$2]++system("mkdir -p "d"/"$2"/"$1); f=d"/"$2"/"$1"/"o$2substr($1,3,2)l"."e; print h > f : 
	#		treat the first occurrence of any parameters pair ($1,$2) specially (!seen[$1,$2]) 
	#		by first creating a folder (system("mkdir -p "d"/"$2"/"$1)), then create a file with
	#   	appropriate name (o$2substr($1,3,2)l"."e), and save the header to that file 
	#		(print h > f); note some intermediary tests to check whether the directory exists 
	#		before creating it, and to display verbose information;
	#  {f=d"/"$2"/"$1"/"o$2substr($1,3,2)l"."e; print >> f; close(f)} : add the current line to 
	#		the file previously created (print >> f) and close the file descriptor (close(f)) to
	#		avoid keeping it around once processing of all lines with a specific ID is done.
	#
	# Ibid (adapt) for other cases (TIME and FLAT) below).
	
	elif [ $6 == "TIME" ]; then
		awk -v o="$2" -v d="$3" -v e="$4" -v FS="$5" -v v=$7 -v y=${year} \
		   'NR==1{h=$0; l=substr($0,1,1); next};
			!seen[$2]++{system("test -d "d"/"y"/"$2" || (mkdir -p "d"/"y"/"$2" && test "v" && echo ... creating folder "d"/"y"/"$2")"); 
			f=d"/"y"/"$2"/"o$2substr(y,3,2)l"."e; system("test "v" && echo ... ... extracting file "o$2substr(y,3,2)l"."e); print h > f};
			{f=d"/"y"/"$2"/"o$2substr(y,3,2)l"."e; print >> f; 
			close(f)}' $1

	elif [ $6 == "FLAT" ]; then
		awk -v o="$2" -v d="$3" -v e="$4" -v FS="$5" -v v=$7 -v y=${year} \
		   'NR==1{h=$0; next};
			!seen[$2]++{f=d"/"o$2substr(y,3,2)l"."e; system("test "v" && echo ... creating file "o$2substr(y,3,2)l"."e); print h > f};
			{f=d"/"o$2substr(y,3,2)l"."e; print >> f; 
			close(f)}' $1
			
	else
		echo "!!! Internal error !!!" ; exit 1;
	fi
}

## array of years
#years=(2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015)
#for year in $(printf '%4d\n' {2001..2015}); do
#  echo "$year"
#done

# store the original IFS
oIFS=${IFS}
# the following IFS setting prevents the word-splitting of filenames with blanks 
IFS=$'\n'
# see also:
# https://unix.stackexchange.com/questions/9496/looping-through-files-with-spaces-in-the-names

FIND=find
if [ "${MACHINE}" == "Mac" ]; then 
	OPTFIND=-E #BSD predicate
else
	predicate= #"-regextype posix-awk"  #"-regextype posix-extended
fi
OPTREGEX=("-regex")
OPTDEPTH=("-mindepth" "1" "-maxdepth" "1") # see http://mywiki.wooledge.org/BashFAQ/050
digitreg='.*/[[:digit:]]{4}' 	# or './2[0-9]{3}': survey year 

# run the script over all files found in the given directory
for dir in `${FIND} ${predicate} ${IDIR} ${OPTDEPTH[@]} -type d ${OPTREGEX[@]} ${digitreg}`; do
 	[ ${VERB} -eq 1 ] && (echo ""; echo "* Exploring folder ${dir} - Looking for bulk ${EXT} files")
    ${FIND} ${dir} ${OPTDEPTH[@]} -type f -name "*.${EXT}" -print0 | while IFS= read -r -d '' file; do
		[ ${VERB} -eq 1 ] && echo "  - file `basename ${file}` is being split"
		udb_file_split ${file} ${ONAME} ${ODIR} ${EXT} ${DELIM} ${DIRBY} ${VERB} || exit 1
    done
done

# reset the original IFS
IFS=${oIFS}

