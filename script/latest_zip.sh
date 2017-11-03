#!/bin/bash
# @name: 	latest_zip
# @brief:   Compress the latest archive of UDB datasets (useful for transmission).
#
# @notes:
# Some DOS-related issue when running this command: in order to deal with embedded control-M's 
# in the file (source of the issue), it may be necessary to run dos2unix; launch it using a 
# PuTTY terminal, e.g. running:
#		dos2unix latest_zip.sh 
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
    echo "${PROGRAM} : Compress the latest archive of UDB datasets";
    echo "Run: ${PROGRAM} --help for further help. Exiting program...";
    echo "=================================================================================";
    echo "";
	exit 1; 
}

help() {
	! [ -z "$1" ] && echo "$1";
	echo "";
    echo "=================================================================================";
    echo "${PROGRAM} : Compress the latest archive of UDB datasets";
    echo "=================================================================================";
    echo "";
    echo "Syntax";
 	echo "------";
    echo "    ${PROGRAM} [-o <odir>] [-f <ofn>] [-d <depth>] [-h] [-v] [-t] <idir>";
    echo "";
    echo "Parameters";
  	echo "----------";
    echo " <idir>    :  output directory storing the bulk UDB datasets;";
    echo " -o <odir> :  (option) input directory where the zip datasets are stored; when not";
	echo "              set, (default), the zipped archives will be stored under the input";
	echo "              directory in <idir>/zip;";
    echo " -f <ofn> :   (option) generic name used as a prefix for the output split files;";
	echo "              default <ofn> is empty ('');";
	echo " -d <depth> : (option) depth (0, 1 or 2) of the zip operation, i.e. apply the zipping";
	echo "              at level <depth>; '-d 0' means zip folder <idir>, '-d 1' means zip all";
	echo "              folders under <idir>, '-d 2' means descend at level 2 of folders below";
	echo "              the <idir>;"
    echo " -h        : (option) display this help;";
    echo " -v        : (option) verbose mode (all kind of useless comments...);";
	echo " -t        : (option) test the process; run with your arguments to see the list of";
	echo "              operations that will actually be realised; recommended."
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


## Some useful internal paramaters

# machine dependent (or not) options for FIND command
FIND=find
if [ "${MACHINE}" == "Mac" ]; then 
	OPTFIND=-E #BSD predicate
	OPTREGEX=("-regex")
else
	OPTFIND=
	OPTREGEX=("-regextype" "posix-extended" "-regex") #"-regextype posix-awk"  #
fi
	
# machine dependent (or not) options for TAR command
TAR=tar
# reminder: some of TAR main operation modes
#    -A, --catenate, --concatenate   append tar files to an archive
#    -c, --create               create a new archive
#    -r, --append               append files to the end of an archive
#    -u, --update               only append files newer than copy in archive
OPTCTAR=cvfz
TAREXT=tar
TGZEXT=tgz

# machine dependent (or not) options for other commands
ZIP=gzip
MV=mv
MKDIR=mkdir
OPTMKD=-p

## Define (set/pass) the script paramaters

# set the default values
VERB=0
IDIR=
ODIR=
OFN=
DEPTH=1

# we use getopts to pass the arguments
# options are: [-i <idir>] [-f <ofn>] [-d <depth>] [-h] [-v]

while getopts :o:f:d:htv OPTION; do
	# extract options and their arguments into variables.
	case $OPTION in
	o) ODIR=$OPTARG
		;;
    f) OFN=$OPTARG
		;;
	d) DEPTH=$OPTARG
		# check that the proposed structure is supported
		[ "$DEPTH" == "0" ] || [ "$DEPTH" == "1" ] || [ "$DEPTH" == "2" ] || usage "!!! Argument DEPTH=$DEPTH not supported - Exiting !!! "
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
	esac
done

shift $((OPTIND-1))  #This tells getopts to move on to the next argument.

function absolute_path() { # work with folders and files
	# arguments: 	1:relative path
	# returns: absolute path
	echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

# further checks (possible after the shifts above)
[ $# -lt 1 ] && usage "!!! Missing input IDIR argument - Exiting !!!"
[ $# -gt 1 ] && usage "!!! Only one argument can be passed - Exiting !!!"

# retrieve the input directory
IDIR=$1
[ -d "${IDIR}" ] || usage "!!! Input directory IDIR=${IDIR} not found - Exiting !!!"

# set the default input directory
if [ -z "${ODIR}" ]; then
	ODIR=${IDIR}/zip
fi

# set absolute path
IDIR=`absolute_path ${IDIR}`
ODIR=`absolute_path ${ODIR}`

[ -d "${ODIR}" ] || (${TESTECHO[@]} ${MKDIR} ${OPTMKD} ${ODIR} && echo "! Output directory ODIR=${ODIR} will be created !")

optdepth=("-mindepth" "$DEPTH" "-maxdepth" "$DEPTH") # see http://mywiki.wooledge.org/BashFAQ/050

for dir in `${FIND} ${IDIR} ${optdepth[@]} -type d`; do
 	[ ${VERB} -eq 1 ] && (echo ""; echo "* Archiving folder ${dir}")
	# avoid tar zipping itself...
	[ "$dir" == "${ODIR}" ] && continue
	# retrieve some pieces of path
	subdir=${dir#$IDIR/}
	current=${subdir##*/}
	parent=${subdir%$current}
	# create parent folder in output directory
	! [ -z "${parent}" ] && ${TESTECHO[@]} ${MKDIR} ${OPTMKD} ${ODIR}/${parent} 
	${TESTECHO[@]} ${TAR} ${OPTCTAR} ${current}.${TGZEXT} -C ${IDIR}/${parent} ${current}/
	${TESTECHO[@]} ${MV} ${current}.${TGZEXT} ${ODIR}/${parent} 
done
