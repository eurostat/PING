#!/usr/bin/bash
# @brief:    Search for string in EU-SILC SAS programs
#
#    strsearchsas.sh [-h] [-v] [-i<ind>] [-d<var>] [-c] <string>
#
# @note:
# Some DOS-related issue when running this command
# In order to deal with embedded control-M's in the file (source of the issue), it
# may be necessary to run dos2unix.
#
# @date:     14/07/2017
# @credit:   grazzja <mailto:jacopo.grazzini@ec.europa.eu>
 
PROGRAM=`basename $0`

case "$(uname -s)" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    CYGWIN*)    MACHINE=Cygwin;;
    MINGW*)     MACHINE=MinGw;;
    *)          MACHINE="UNKNOWN:${unameOut}"
esac

if [ "${MACHINE}" == "Cygwin" ]; then
	DRIVE=$(echo `mount --show-cygdrive-prefix` | sed -e 's/Prefix//;s/Type//;s/Flags//;s/user//;s/binmode//')
else
	DRIVE=/
fi 
#DRIVE="${DRIVE#"${DRIVE%%[![:space:]]*}"}" 
#DRIVE="${DRIVE%"${DRIVE##*[![:space:]]}"}"
trim() {
   local var="$*"
   var="${var#"${var%%[![:space:]]*}"}" # remove leading whitespace characters
   var="${var%"${var##*[![:space:]]}"}"  # remove trailing whitespace characters
   echo -n "$var"
}
DRIVE=`trim $DRIVE`

if ! [ "${DRIVE:-1}" == "/" ]; then
	ROOTDIR=${DRIVE}/z #0eusilc?
else
	ROOTDIR=${DRIVE}z
fi
PGMDIR=${ROOTDIR}/IDB_RDB/pgm

SASEXT=sas
REXT=R

function usage() { 
	! [ -z "$1" ] && echo "$1";
    echo "";
    echo "=================================================================================";
    echo "${PROGRAM} : Search for string in EU-SILC R/SAS programs.";
    echo "Run: ${PROGRAM} -help for further help. Exiting program...";
    echo "=================================================================================";
    echo "";
    exit 1; 
}

function help() {
	! [ -z "$1" ] && echo "$1";
    echo "";
    echo "=================================================================================";
    echo "${PROGRAM} : Search for string in EU-SILC SAS programs.";
    echo "=================================================================================";
    echo "";
    echo "Syntax";
 	echo "------";
    echo "    ${PROGRAM} [-h] [-v] [-i<ind>] [-d<var>] [-c] <string>";
    echo "";
    echo "Parameters";
  	echo "----------";
    echo " <string> : string to search for in the various EU-SILC  R/SAS programs;";
    echo " -i<ind>  : (option) indicator programs to be explored: it can be RDB, RDB2, EDB, LDB;";
    echo "            when set to ALL, all programs are explored; equivalent long option is '--ind=';";
    echo " -d<var>  : (option) programs generating derived variables to be explored: it can be";
    echo "            CVAR, EVAR or LVAR; when set to ALL, all variables (i.e., the programs)";
	echo "            are explored; equivalent long option is '--der=';";
	echo " -c       : (option) option set to use case sensitivenes; when set, the case (upper or";
	echo "            lower letters) of the string is taken into account; when not set (default),";
	echo "            it is as if GREP used the '-i' option; equivalent long option is '--case=';";
    echo " -h       : (option) display this help; equivalent long option is '--help=';";
    echo " -v       : (option) verbose mode (all kind of useless comments...); equivalent long";
	echo "            option is '--verb='.";
	echo "";
    echo "Examples";
	echo "--------";
    echo "* Check the presence of the dimension lev_diff (no case sensitiveness) in any of the" ;
	echo "  indicator programs:";
    echo "     ${PROGRAM} lev_diff -iALL -v";
    echo "  or equivalently:";
    echo "     ${PROGRAM} lev_diff --ind=ALL -v";
    echo "  which returns: ";
    echo "     C_IND/DI10 pgm/_igtp02 pgm/_mdes09 E_IND/e_mdes09";
    echo "";
    echo "* Check the presence of the dimension SEV_DEP (no case sensitiveness) in any of the"; 
	echo "  indicator programs:";
    echo "     ${PROGRAM} SEV_DEP -dCVAR -v";
    echo "  or equivalently:";
    echo "    ${PROGRAM} SEV_DEP --der=CVAR -v";
    echo "  which returns:";
	echo "     C_Var/140.VAR_DEP_SEV_EXT_Reliability C_Var/190.VAR_AROPE C_Var/210.Update_All_Variables";
    echo "";
    echo "        European Commission  -   DG ESTAT   -   The EU-SILC team  -  2017        ";
    echo "=================================================================================";
    exit 1;
}

## basic checks: command error or help
[ $# -eq 0 ] && usage
# [ $# -eq 1 ] && [ $1 = "--help" ] && help
 
INDNAMES=(RDB 				RDB2 		EDB 				LDB)
INDDIRS=( ${PGMDIR}/C_IND 	${PGMDIR}	${PGMDIR}/E_IND		${PGMDIR}/L_IND )
VARNAMES=(CVAR 				EVAR				LVAR)
VARDIRS=( ${PGMDIR}/C_Var	${PGMDIR}/E_Var 	${PGMDIR}/L_Var )

VERB=0
CASENSE=0
HELP=0

ind=()
var=()

# we use getopt to pass the arguments
TEMP=`getopt -o i::d::chv --long ind::,der::,case,help,verb -n '${PROGRAM}' -- "$@"`
eval set -- "$TEMP"
# extract options and their arguments into variables.
while true ; do
     case "$1" in
         -h|--help) help;;
         -i|--ind)
            case "$2" in
                 "") ind=ALL; shift 2;;
                 *) ind+=("$2"); shift 2;;
             esac ;;
         -d|--der)
            case "$2" in
                 "") var=ALL; shift 2;;
                 *) var+=("$2"); shift 2;;
             esac ;;
         -v|--verb) VERB=1; shift;;
		 -c|--case)	CASENSE=1; shift;;
         --) shift; break;;
         *) echo "Internal error!" ; exit 1;;
     esac 	 
done

## note the possible use of getopts as well, e.g.:
#while getopts "l:" opt; do
#    case $opt in
#        l) 
#			db+=("$OPTARG");;
# 		\?)
#			echo "Invalid option: -$OPTARG" >&2
#			exit 1;;
#		:)
#			echo "Option -$OPTARG requires an argument." >&2
#			exit 1;;
#   esac
#done
#shift $((OPTIND -1))

[ $# -gt 1 ] && usage "!!! Only one string can be searched for at once - Exiting !!!"

searchstr=$1
[ $VERB -eq 1 ] && echo "# Setting parameters: input/output search paths..."	\
				&& echo "* String searched: ${searchstr}"

## further settings

idirs=()

# retrieve the list of indicator programs to explore
if [ ${#ind[@]} -ge 1 ]; then
	if [ "${ind}" == "ALL" ]; then 
		ind=("${INDNAMES[@]}") # copy the array
		[ $VERB -eq 1 ] && echo "* All programs for indicator estimation will be explored:"
	else
		[ $VERB -eq 1 ] && echo "* Search operated for indicators in the following databases/directories:"
	fi
	for (( i=0; i<${#ind[@]}; i++ )); do
		for (( j=0; j<${#INDDIRS[@]}; j++ )); do	
			if [ ${ind[i]} == ${INDNAMES[j]} ]; then
				[ $VERB -eq 1 ] && echo "  - ${ind[$i]}: 	${INDDIRS[j]} "
				idirs+=(${INDDIRS[j]})
				break
			fi
		done
		[ $j -ge ${#INDDIRS[@]} ] && usage "!!! Indicator library ${ind[i]} not recognised - Exiting !!!"
		# if we reach that point, some issue...
	done
fi

# retrieve the list of variable programs to explore
if [ ${#var[@]} -ge 1 ]; then
	if [ "${var}" == "ALL" ]; then 
		var=("${VARNAMES[@]}") # copy the array
		[ $VERB -eq 1 ] && echo "* All programs for derived variables calculation will be explored:"
	else
		[ $VERB -eq 1 ] && echo "* Search operated for variables in the following databases:"
	fi
	for (( i=0; i<${#var[@]}; i++ )); do
		for (( j=0; j<${#VARDIRS[@]}; j++ )); do	
			if [ ${var[i]} == ${VARNAMES[j]} ]; then
				[ $VERB -eq 1 ] && echo "  - ${var[$i]}: 	${VARDIRS[j]} "
				idirs+=(${VARDIRS[j]})
				break
			fi
		done
		[ $j -ge ${#VARDIRS[@]} ] && usage "!!! Derived variables library ${var[i]} not recognised - Exiting !!!"
	done
fi

# merge names
names=()
for (( i=0; i<${#idirs[@]}; i++ )); do
	names+=(`basename ${idirs[$i]}`)
done
# instead of names=("${ind[@]}" "${var[@]}")

[ $VERB -eq 1 ] && echo 										\
				&& echo "# Run the simple string search..."		\
				&& echo "  (programs are explored one by one)"


GREPCMD=grep
if [ $CASENSE -eq 1 ];     then
	GREPOPTS=(-c)
else
	GREPOPTS=(-c -i)
fi

ofiles=()
onames=()

for (( i=0; i<${#idirs[@]}; i++ )); do
	dir=${idirs[$i]}
	[ $VERB -eq 1 ] && echo "* Check in directory ${dir}:"
	for f in ${dir}/*.$SASEXT; do
		if ! [ -e ${f} ];     then
			echo "    => no SAS file found !!!"
			break
		else
			[ $VERB -eq 1 ] && echo "  - file $f..."
			if [ `${GREPCMD} ${GREPOPTS[@]} ${searchstr} ${f}` -ge 1 ]; then
				ofiles+=("${f}")
				onames+=("${names[$i]}")
				[ $VERB -eq 1 ] && echo "    => string ${searchstr} found !"
			fi
		fi
	done
done

[ $VERB -eq 1 ] && echo 								\
				&& echo "# Return the final list..."

result=()

if ! [ ${#ofiles[@]} -eq 0 ]; then
	if [ $VERB -eq 1 ];     then
		echo "* Files where ${searchstr} is present:"
		for (( i=0; i<${#ofiles[@]}; i++ )); do
			echo "  - ${onames[$i]}: ${ofiles[$i]}"
		done
	fi
	for (( i=0; i<${#onames[@]}; i++ )); do
		result+=("${onames[$i]}/`basename ${ofiles[$i]} .$SASEXT`")
	done
else
	[ $VERB -eq 1 ] && echo "No file in ${ind[@]} ${var[@]} contains the string ${searchstr} !!!"
fi

echo 
echo ${result[@]}
