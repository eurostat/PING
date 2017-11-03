#!/bin/bash
# @name: 	latest_update
# @brief:   Update a hierarchical directory archive of CSV files organised per country/per 
#			year with data from another directory with similar structure.
#
# @notes:
# Some DOS-related issue when running this command: in order to deal with embedded control-M's 
# in the file (source of the issue), it may be necessary to run dos2unix; launch it using a 
# PuTTY terminal, e.g. running:
#		dos2unix latest_update.sh 
#
# @date:     02/10/2017
# @author: grazzja <jacopo.grazzini@ec.europa.eu>

# DIRNEWCRONOS=/cygdrive/z/IDB_RDB/newcronos

BASHVERS=${BASH_VERSION%.*}

function uppercase () {
	if (( $(bc <<< "${BASHVERS} < 4") )); then
		echo  $( tr '[:lower:]' '[:upper:]' <<< $1)
	else
		echo ${1^^} # does not work on bash version < 4
	fi
}
function trim() {
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

if [ "${MACHINE}" == "Cygwin" ]; then
	DRIVE=$(echo `mount --show-cygdrive-prefix` | sed -e 's/Prefix//;s/Type//;s/Flags//;s/user//;s/binmode//')
else
	DRIVE=/
fi 
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
    echo "${PROGRAM} : Update a hierarchical directory archive of CSV files organised per";
    echo "		country/per year with data from another directory with similar structure";
    echo "Run: ${PROGRAM} -h for further help. Exiting program...";
    echo "=================================================================================";
    echo "";
	exit 1; 
}

function help() {
	! [ -z "$1" ] && echo "$1";
	echo "";
    echo "=================================================================================";
    echo "${PROGRAM} : Update a hierarchical directory archive of CSV files organised per";
    echo "		country/per year with data from another directory with similar structure";
    echo "=================================================================================";
    echo "";
    echo "Syntax";
 	echo "------";
    echo "    ${PROGRAM} [-o <odir>] [-b <by>] [-s <suff>] [-p <pref>] [-z <arch>]";
	echo "				[-h] [-v] [-t] <idir>";
    echo "";
    echo "Parameters";
  	echo "----------";
    echo " <idir>    : input directory storing the latest release of anonymised UDB datasets;";
	echo "             this is composed of Cross/ and/or Long folders that contain the bulk";
	echo "             UDB datasets specifically recomputed for that release; for instance, its";
	echo "             structure may look like:";
	echo "                    |-- Cross";
	echo "                    |   |-- AT";
	echo "                    |   |   |-- 2014";
	echo "                    |   |   |   |-- UDB_cAT14D_release_17-09.csv";
	echo "                    |   |   |   |-- UDB_cAT14P_release_17-09.csv";
	echo "                    |   |   |   |-- UDB_cAT14H_release_17-09.csv";
	echo "                    |   |   |   |-- UDB_cAT14R_release_17-09.csv";
	echo "                    |   |   |-- 2015";
	echo "                    |   |   |   |-- UDB_cAT15D_release_17-09.csv";
	echo "                    |   |   |   |-- UDB_cAT15P_release_17-09.csv";
	echo "                    |   |   |   |-- UDB_cAT15H_release_17-09.csv";
	echo "                    |   |   |   |-- UDB_cAT15R_release_17-09.csv";
	echo "                    |   |   |-- 2016";
	echo "                    |   |   |-- ...";
	echo "                    |   |-- BE";
	echo "                    |   |   |-- 2014";
	echo "                    |   |   |-- ...";
	echo "                    |   |-- ...";
	echo "                    |-- Long";
	echo "                    |-- ...";
	echo "             when the directory is organised per country/per year (see '-b' option"; 
	echo "             below)";
    echo " -o <odir> : (option) output directory where the latest UDB version is available";
	echo "             for every country and every survey year; when not set, (default), the"; 
	echo "             folder [Z:\7.3_Dissemination\data\latest] is used as output directory;"; 
	echo " -a <op> :   (option) action to perform when updating the files, either copy"; 
	echo "             (<op>='cp'); or move (<op>='mv'); default is 'cp';";
    echo " -z <arch> : (option) the files that are replaced will be saved into a zip archive for"; 
	echo "             backup purpose; the archive will be actually named <today>_<arch>.tar.gz,";
	echo "             where <today> is today's date;";
    echo " -p <pref> : (option) generic prefix used to name all files from the input directory;"; 
	echo "             this will be removed when copied into the output directory; default is"; 
	echo "             '', i.e. no prefix is considered;";
    echo " -s <suff> : (option) ibid for generic suffix used to name all input files; default"; 
	echo "             is '', i.e. no suffix is considered;";
	echo " -b <by> :   (option) flag defining the hierarchical structure in both the input and";
	echo "             output directories; it can be either 'GEO' (default) or 'TIME'; in the";
	echo "             first case (GEO) the output directory will be organised as (like example";
	echo "             above):";
	echo "                    |-- Cross";
	echo "                    |   |-- AT";
	echo "                    |   |   |-- 2014";
	echo "                    |   |   |   |-- UDB_cAT14D.csv";
	echo "                    |   |   |   |-- UDB_cAT14P.csv";
	echo "                    |   |   |   |-- UDB_cAT14H.csv";
	echo "                    |   |   |   |-- UDB_cAT14R.csv";
	echo "                    |   |   |-- 2013";
	echo "                    |   |   |   |-- UDB_cAT13D.csv";
	echo "                    |   |   |   |-- UDB_cAT13P.csv";
	echo "                    |   |   |   |-- UDB_cAT13H.csv";
	echo "                    |   |   |   |-- UDB_cAT13R.csv";
	echo "                    |   |   |-- ...";
	echo "                    |   |-- BE";
	echo "                    |   |   |-- 2014";
	echo "                    |   |   |   |-- UDB_cBE14D.csv";
	echo "                    |   |   |   |-- UDB_cBE14P.csv";
	echo "                    |   |   |   |-- UDB_cBE14H.csv";
	echo "                    |   |   |   |-- UDB_cBE14R.csv";
	echo "                    |   |   |-- 2013";
	echo "                    |   |   |   |-- UDB_cBE13D.csv";
	echo "                    |   |   |   |-- UDB_cBE13P.csv";
	echo "                    |   |   |   |-- UDB_cBE13H.csv";
	echo "                    |   |   |   |-- UDB_cBE13R.csv";
	echo "                    |   |   |-- ...";
	echo "                    |   |-- ...";
	echo "                    |-- Long";
	echo "                    |-- ...";
	echo "              and so forth, while in the second case (TIME), it will look like:"
	echo "                    |-- Cross";
	echo "                    |   |-- 2014";
	echo "                    |   |   |-- AT";
	echo "                    |   |   |   |-- UDB_cAT14D.csv";
	echo "                    |   |   |   |-- UDB_cAT14P.csv";
	echo "                    |   |   |   |-- UDB_cAT14H.csv";
	echo "                    |   |   |   |-- UDB_cAT14R.csv";
	echo "                    |   |   |-- BE";
	echo "                    |   |   |   |-- UDB_cBE14D.csv";
	echo "                    |   |   |   |-- UDB_cBE14P.csv";
	echo "                    |   |   |   |-- UDB_cBE14H.csv";
	echo "                    |   |   |   |-- UDB_cBE14R.csv";
	echo "                    |   |-- 2013";
	echo "                    |   |   |-- AT";
	echo "                    |   |   |   |-- UDB_cAT13D.csv";
	echo "                    |   |   |   |-- UDB_cAT13P.csv";
	echo "                    |   |   |   |-- UDB_cAT13H.csv";
	echo "                    |   |   |   |-- UDB_cAT13R.csv";
	echo "                    |   |   |-- BE";
	echo "                    |   |   |   |-- UDB_cBE13D.csv";
	echo "                    |   |   |   |-- UDB_cBE13P.csv";
	echo "                    |   |   |   |-- UDB_cBE13H.csv";
	echo "                    |   |   |   |-- UDB_cBE13R.csv";
	echo "                    |   |-- ...";
	echo "                    |-- Long";
	echo "                    |-- ...";
	echo "             and so forth; note that the case FLAT, where all files are stored under"; 
	echo "             <odir>, has NOT been implemented yet";
    echo " -h        : (option) display this help;";
    echo " -v        : (option) verbose mode (all kind of useless comments...);";
	echo " -t        : (option) test the process; run with your arguments to see the list of";
	echo "              operations that will actually be realised; recommended."
	echo "";
    echo "Note";
	echo "----";
	echo "As mentioned above, the default output directory with the latest available versions";
	echo "of UDBs for every single country and every survey year is:";
	echo "              [Z:\7.3_Dissemination\data\latest]";
	echo "";
    echo "Examples";
	echo "--------";
    echo " TBD";
    echo "";
    echo "     European Commission   -   DG ESTAT   -   The EU-SILC team    -   2017 ";
    echo "=================================================================================";
    echo "";
    exit 1;
}

## basic checks: command error or help
[ $# -eq 0 ] && usage
# [ $# -eq 1 ] && [ $1 = "--help" ] && help

## Some useful internal paramaters

DEFODIR=${ROOTDIR}/7.3_Dissemination/data/latest

# machine dependent (or not) options for FIND command
FIND=find
if [ "${MACHINE}" == "Mac" ]; then 
	OPTFIND=-E #BSD predicate
	OPTREGEX=("-regex")
else
	OPTFIND=
	OPTREGEX=("-regextype" "posix-extended" "-regex") #"-regextype posix-awk"  #
fi
OPTDEPTH=("-mindepth" "1" "-maxdepth" "1") # declared as an array: see http://mywiki.wooledge.org/BashFAQ/050
OPTTYPE=("-type" "d")
ALPHAREG='.*/[[:alpha:]]{2}'   	# or './[a-Z]{2}': ISO-codes of countries 
DIGITREG='.*/[[:digit:]]{4}' 	# or './2[0-9]{3}': survey year 
	
# machine dependent (or not) options for TAR command
TAR=tar
# reminder: some of TAR main operation modes
#    -A, --catenate, --concatenate   append tar files to an archive
#    -c, --create               create a new archive
#    -r, --append               append files to the end of an archive
#    -u, --update               only append files newer than copy in archive
OPTCTAR=cvf
OPTATAR=rvf
OPTUTAR=uvf
TAREXT=tar

# machine dependent (or not) options for other commands
ZIP=gzip
CAT=cat
MV=mv
CP=cp
OPTMV=
RM=rm
OPTRM=-f
MKDIR=mkdir
OPTMKD=-p

DUMMYSTRING=___DUMMY

## Define (set/pass) the script paramaters

# set the default values
VERB=0
IDIR=
ODIR=
PREF=
SUFF=
ARCH=
DIRBY=GEO
ACTION=CP
TESTECHO=

# we use getopts to pass the arguments
# options are: [-o <odir>] [-b <dirby>] [-s <suff>] [-p <pref>] [-z <arch>] [-a <op>]

while getopts :o:a:p:s:z:b:htv OPTION; do
	# extract options and their arguments into variables.
	case $OPTION in
	o) ODIR=$OPTARG
		# check the existence of the directory
		[ -d "$ODIR" ] || usage "!!! Output directory ODIR=$ODIR not found - Exiting !!!"
		;;
	a) ACTION=$OPTARG
		# check that the action proposed is supported
		[ "${ACTION}" == "MV" ] || [ "${ACTION}" == "CP" ] || usage "!!! Argument ACTION=$ACTION not recognised - Exiting !!! "
		;;
    p) PREF=$OPTARG
		;;
    s) SUFF=$OPTARG
		;;
    z) ARCH=$OPTARG
		;;
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
# TEMP=`getopt -o o:s:p:z:b:a:tvh --long odir:,suff:,pref:,arch:,dirby:,action:,test,help,verb -n '${PROGRAM}' -- "$@"`
# eval set -- "$TEMP"
# while true ; do
#      case "$1" in
#          -h|--help) help;;
#          -o|--odir)
# 			[ -d "$2" ] || usage "!!! Output directory ODIR=$2 not found - Exiting !!!";
#             ODIR=$2; shift 2;;
#          -p|--pref)
#             PREF=$2; shift 2;;
#          -s|--suff)
#             SUFF=$2; shift 2;;
#          -z|--arch)
#             ARCH=$2; shift 2;;
# 		 -b|--dirby) 
# 			[ "$2" == "GEO" ] || [ "$2" == "TIME" ] || usage "!!! Argument DIRBY=$2 not recognised - Exiting !!! "; 
# 			DIRBY=$2; shift 2;;
# 		 -a|--action) 
# 			ACTION=$2; 
# 			[ "${ACTION}" == "MV" ] || [ "${ACTION}" == "CP" ] || usage "!!! Argument ACTION=$2 not recognised - Exiting !!! "; 
# 			shift 2;;
# 		 -t|--test) TESTECHO=("echo" "..."  "run:"); shift;;
#        -v|--verb) VERB=1; shift;;
#        --) shift; break;;
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
	ODIR=${DEFODIR}
fi
	
# test that the organisation/structure of input and output directory is compatible
([ -d "${ODIR}/Cross" ] || [ -d "${ODIR}/Long" ]) && (! [ -d "${IDIR}/Cross" ] && ! [ -d "${IDIR}/Long" ]) \
	&& usage "!!! Incompatible directory organisation: Cross/ and Long/ subfolders are missing in ${IDIR} - Exiting !!!"
	
(! [ -d "${ODIR}/Cross" ] && ! [ -d "${ODIR}/Long" ]) && ([ -d "${IDIR}/Cross" ] || [ -d "${IDIR}/Long" ]) \
	&& usage "!!! Incompatible directory organisation: Cross/ and Long/ subfolders are missing in ${ODIR} - Exiting !!!"

# check other parameters 
if ! [ -z "${ARCH}" ]; then
	ARCH=${TODAY}_${ARCH}.${TAREXT}
else
	ARCH=${DUMMYSTRING}
fi
if [ -z ${PREF} ]; then
	PREF=${DUMMYSTRING}
fi
if [ -z ${SUFF} ]; then
	SUFF=${DUMMYSTRING}
fi

# verbose announcements	
[ ${VERB} -eq 1 ] 	&& (echo "";					   			\
			    echo "# Setting parameters..."; 		   		\
			    echo "  - input directory: ${IDIR}";	   		\
			    echo "  - output directory: ${ODIR}";     	   	\
			    echo "  - directory organisation: ${DIRBY}")
[ ${VERB} -eq 1 ] && [ "${PREF}" != "${DUMMYSTRING}" ] && echo "  - generic input prefix: ${PREF}";	  
[ ${VERB} -eq 1 ] && [ "${SUFF}" != "${DUMMYSTRING}" ] && echo "  - generic input suffix: ${SUFF}";	
[ ${VERB} -eq 1 ] && [ "${ARCH}" != "${DUMMYSTRING}" ] && echo "  - output archive name: ${ARCH}";

	
# function for file renaming (removing prefix and suffix for original name)
function udb_file_rename() {
	# arguments: 	1:filename 2:pref 3:suff
	# returns: new filename 
	
	file=$(trim $1)
	pref=$(trim $2)
	suff=$(trim $3)

	path=${file%/*} # not used
	filename=${file##*/} # or also: ${file%.*}, with full path however
	extension=${filename##*.} # or also: ${file##*.}
	basename=${filename%.*}
	
	if [ "${pref}" != "${DUMMYSTRING}" ]; then
		basename=${basename%${pref}}
		# $(echo -n $basename | sed 's/${pref}//g') # ${basename/${pref}/} 
	fi
	
	if [ "$3" != "${DUMMYSTRING}" ]; then
		basename=${basename%${suff}}
		# $(echo -n $basename | sed 's/${suff}//g') # ${basename/${suff}/} 
	fi
	
	# return the updated basename
	echo -n ${basename}.${extension}
}

# function for directory copy/move
function udb_dir_copy() {
	# arguments: 	1:input 2:odir 3:action 4:pref 5:suff 6:dirby 7:arch 8:verbose 
	# returns: move/copy and rename files  

	if [ "${MACHINE}" == "Mac" ]; then 
		predicate=-E #BSD predicate
	else
		predicate= #"-regextype posix-awk"
	fi

	if [ $6 == "FLAT" ]; then
		[ ${VERB} -eq 1 ] && echo "  - copy all files from $1 to $2"
		echo 
	elif ! ([ $6 == "GEO" ] || [ $6 == "TIME" ]); then
		echo "!!! Internal error !!!" ; exit 1;
	fi

	if [ $6 == "GEO" ]; then
		regdir1=${ALPHAREG}
		regdir2=${DIGITREG}
	elif [ $6 == "TIME" ]; then
		regdir1=${DIGITREG}
		regdir2=${DIGITREG}
	fi
		
	# build the	string used as a search basename for the files to be moved
	search=()
	if [ "$4" != "${DUMMYSTRING}" ]; then
		search+=("$4*")
	fi
	if [ "$5" != "${DUMMYSTRING}" ]; then
		search+=("$5*")
	fi

	# store the original IFS
	oIFS=${IFS}
	# see also: https://unix.stackexchange.com/questions/9496/looping-through-files-with-spaces-in-the-names
	# the following IFS setting prevents the word-splitting of filenames with blanks 
	IFS=$'\n'

	if [ "$7" != "${DUMMYSTRING}" ]; then
		[ ${VERB} -eq 1 ] && (echo ""; echo "* Creating archive $2/$7")
		(echo "@brief: Backup files of updated UDB files from \"latest\" archive"; echo "@date: `date`"; echo "@author: `whoami`"; echo) | ${CAT} - > /tmp/README.txt
		[ -z "${TESTECHO}" ] && (cd /tmp/; ${TAR} ${OPTCTAR} $2/$7 README.txt)
		sleep 2 # because we launched a subprocess... 
		# ${TAR} ${OPTCTAR} $7 -C /tmp/ /tmp/README.txt # does not work as expected...
	fi
	
	# use dynamic variable to define the actual operation (move or copy)
	action=$3
	optact=OPT$3
	
	# look into the hierarchy
	for path1 in `${FIND} ${OPTFIND} $1 ${OPTDEPTH[@]} ${OPTTYPE[@]} ${OPTREGEX[@]} ${regdir1}`; do
		[ ${VERB} -eq 1 ] && (echo ""; echo "* Exploring folder ${path1}")
		dir1=${path1##*/}
		${FIND} ${path1} ${OPTDEPTH[@]} ${OPTTYPE[@]} ${OPTREGEX[@]} ${regdir2} -print0 | while IFS= read -r -d '' path2; do
			dir2=${path2##*/}
			[ "$7" != "${DUMMYSTRING}" ] && echo "@folder ${dir1}/${dir2}" | ${CAT} - >> /tmp/README.txt
			# check whether a directory with same name already exists in the outptut
			if  [ -d $2/${dir1}/${dir2} ]; then
				if [ "$7" != "${DUMMYSTRING}" ]; then
					[ ${VERB} -eq 1 ] && echo "  - add output folder ${dir1}/${dir2}/ to archive $7"
					# add the output folder to the archive
					! [ -z "${TESTECHO}" ] && echo "... run: (cd $2; ${TAR} ${OPTATAR} $7 ${dir1}/${dir2}/)"
					[ -z "${TESTECHO}" ] && ${TAR} ${OPTATAR} $2/$7 -C $2 ${dir1}/${dir2}/
				fi
					[ ${VERB} -eq 1 ] && echo "  - remove contents of output folder ${dir1}/${dir2}/"
				# delete the contents of the folder 
				${TESTECHO[@]} ${RM} ${OPTRM} ${file} $2/${dir1}/${dir2}/*
			fi
			# create the folder in the case it does not already exist in the output directory
			${TESTECHO[@]} ${MKDIR} ${OPTMKD} $2/${dir1}/${dir2}/ 
			if [ -z "$search" ]; then 
				[ ${VERB} -eq 1 ] && echo "  - copy all input folder contents to $2/${dir1}/${dir2}"
				# no action on the file, move all folder contents to the output
				${TESTECHO[@]} ${!action} ${!optact} ${path2}/* $2/${dir1}/${dir2}/
			else
				# go through all files (one by one) since they may have to be renamed as well
				# for file in ${path2}/*${search}; do
				${FIND} ${path2} ${OPTDEPTH[@]} -type f -name "*${search}" -print0 | while IFS= read -r -d '' file; do
					if [ "$7" != "${DUMMYSTRING}" ]; then
						[ ${VERB} -eq 1 ] && (echo ""; echo "  - update README in archive $7")
						echo " - ${file##*/}" | ${CAT} - >> /tmp/README.txt
						! [ -z "${TESTECHO}" ] && echo "... run: (cd /tmp/; ${TAR} ${OPTUTAR} $2/$7 README.txt)"
						[ -z "${TESTECHO}" ] && (cd /tmp/; ${TAR} ${OPTUTAR} $2/$7 README.txt)
						sleep 2
					fi
					nbase=$(udb_file_rename ${file} ${PREF} ${SUFF})
					[ ${VERB} -eq 1 ] && echo "  - copy and rename ${file} into $2/${dir1}/${dir2}/${nbase}"
					# move or copy the file
					${TESTECHO[@]} ${!action} ${!optact} ${file} $2/${dir1}/${dir2}/${nbase}
				done
			fi
		done
	done	

	# reset the original IFS
	IFS=${oIFS}	
}

# run the script over all files found in the given directory

if ! [ -d "${IDIR}/Cross" ] && ! [ -d "${IDIR}/Long" ]; then
	udb_dir_copy  ${IDIR} ${ODIR} ${ACTION} ${PREF} ${SUFF} ${DIRBY} ${ARCH} ${VERB} || exit 1
	[ "${ARCH}" != "${DUMMYSTRING}" ] && ${ZIP} ${ODIR}/${ARCH}
else
	[ -d "${IDIR}/Cross" ] && udb_dir_copy  ${IDIR}/Cross ${ODIR}/Cross ${ACTION} ${PREF} ${SUFF} ${DIRBY} ${ARCH} ${VERB} || exit 1
	[ "${ARCH}" != "${DUMMYSTRING}" ] && ${ZIP} ${ODIR}/Cross/${ARCH}
	[ -d "${IDIR}/Long" ] && udb_dir_copy  ${IDIR}/Long ${ODIR}/Long ${ACTION} ${PREF} ${SUFF} ${DIRBY} ${ARCH} ${VERB} || exit 1
	[ "${ARCH}" != "${DUMMYSTRING}" ] && ${ZIP} ${ODIR}/Long/${ARCH}
fi

