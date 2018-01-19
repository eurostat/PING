#!/bin/bash
# @brief:    Automatic generation of html documentation from markdown files
#
#    mmdoc2html.sh [-help] [-v] [-test] [-of <oname>] [-od <dir>] <filename>
#
# @note:
# Some DOS-related issue when running this command
# In order to deal with embedded control-M's in the file (source of the issue), it
# may be necessary to run dos2unix.
#
# @date:     02/02/2017
# @credit:   grazzja <mailto:jacopo.grazzini@ec.europa.eu>
 
case "$OSTYPE" in
  #linux*)   	echo "LINUX" ;;
  #darwin*)  	echo "OSX" ;; 
  #win*)     	echo "Windows" ;;
  cygwin*)  	DRIVE=/cygdrive ;;
  msys*|mingw*)	DRIVE=;;
  #bsd*)     	echo "BSD" ;;
  #solaris*) 	echo "SOLARIS" ;;
  *)        echo "unknown: $OSTYPE" ;;
esac

ROOTDIR=${DRIVE}/z
# \\s-isis.eurostat.cec\0eusilc
ROOTDIR=z:

DOCGEN=${DRIVE}/c/PGM/doxygen/bin/doxygen.exe

PINGDIR=${ROOTDIR}/PING
DIRDOC=${PINGDIR}/docs

CFG_DIR=${DIRDOC}/dox
CFG_RELDIR=../dox
CFG_FILE=doxygen-eusilc-config.cfg

## basic checks: command error or help
#if [ $# -eq 0 ]; then
#    echo "`basename $0` : Generate a browsable documentation from bunch of markdown files."
#    echo "Run: `basename $0` -help for further help. Exiting program..."
#    #echo "Syntax : `basename $0` [-help] [-v] [-test] [-of <oname>] [-od <dir>] <input>"
#    exit 

if [ $# -eq 1 ] && [ $1 = "-help" ]; then 
    echo "================================================================================="
    echo "`basename $0` : Generate a browsable documentation from bunch of markdown files."
    echo "================================================================================="
    echo ""
    echo "Syntax";
 	echo "------"
    echo "    `basename $0` [-help] [-v] [-test] [-of <oname>] [-od <dir>] <input>"
    echo ""
    echo "Parameters"
  	echo "----------"
    echo " input        :   input R/SAS filename or a directory with R/SAS files "
    echo " -help        :   display this help"
    echo " -v           :   verbose mode (all kind of useless comments...)"
    echo " -test        :   test mode; a temporary output will be generated and displayed;"
    echo "                  use it for checking purpose prior to the automatic generation"
    echo " -od <dir>    :   output directory for storing the output formatted files; in the"
    echo "                  case of test mode (see option -test above), this is overwritten"
    echo "                  by the temporary directory /tmp/; default: same location as"
	echo "                  input original file"
    echo " -of <name>   :   output name; it is either the name of the output file (with or"
    echo "                  without .md extension) in the case parameter <input> is passed"
    echo "                  (see above) as a file, or a generic suffix to be added to the"
    echo "                  output file names otherwise; when a suffix is passed, the '_'" 
	echo "                  symbol is added prior to the suffix; default: empty suffix"
    echo ""
    echo ""
    echo "        European Commission  -   DG ESTAT   -   The EU-SILC team  -  2017        "
    echo "================================================================================="
    exit 
fi
 
 
## set output parameters
input_directory=${DIRDOC}/md/
static_directory=${input_directory}/_static
module_directory=${input_directory}/_static_/modules
output_directory=${DIRDOC}/

doxygen_directory=${DIRDOC}/dox
image_directory=${DIRDOC}/img

cfg=${CFG_RELDIR}/${CFG_FILE}
dox=${DOCGEN}

ocfg=0

idir=0
odir=0
doxdir=0

ohtml=0
generate_html=YES
html_output=./html # relative path... or absolute path: ${DIRDOC}/html? you choose...

olatex=0
generate_latex=NO
latex_output=./latex # relative path

oxml=0
generate_xml=NO
xml_output=./xml # relative path

oman=0
generate_man=NO
man_output=./man # relative path

ortf=0
generate_rtf=NO
rtf_output=./rtf # relative path

test=0
verb=0

# hum, hum... use getopt!!! ok, next time...

## loop over the command arguments
for i in $@;
    do
    if [ ${i:0:1} = "-" ];     then
        if [ $i = "-verb" ] || [ $i = "-v" ];         then
            verb=1
        elif [ $i = "-test" ];         then
            test=1
        elif [ $i = "-cfg" ];         then
 			ocfg=1
        elif [ $i = "-idir" ];         then
 			idir=1
        elif [ $i = "-odir" ];         then
 			odir=1
        elif [ $i = "-html" ];     then
			ohtml=1
            generate_html=1
        elif [ $i = "-nohtml" ];     then
			html_output=""
            generate_html=0
        elif [ $i = "-xml" ];     then
			oxml=1
            generate_xml=1
        elif [ $i = "-latex" ];      then
 			olatex=1
            generate_latex=YES
		elif [ $i = "-rtf" ];     then
			ortf=1
			generate_rtf=YES
        elif [ $i = "-man" ];     then
			oman=1
            generate_man=YES
        #elif [ $ohtml -eq 1 ];      then
        #    echo "Output html directory set to default..."
		#	ohtml=0
        elif [ $olatex -eq 1 ];      then
            echo "Output latex directory set to default..."
			olatex=0
        elif [ $oxml -eq 1 ];        then   
            echo "Output xml directory set to default..."
			oxml=0
        elif [ $ortf -eq 1 ];      then
            echo "Output rtf directory set to default..."
			ortf=0
        elif [ $oman -eq 1 ];        then   
            echo "Output man directory set to default..."
			oman=0
        else
            echo "Unknown option: $i. Exiting program..."
            exit
        fi        
    elif [ $ocfg -eq 1 ];     then
        cfg=$i
        ocfg=0
    elif [ $idir -eq 1 ];		then
        input_directory=$i
        idir=0
    elif [ $odir -eq 1 ];     	then
        output_directory=$i
        odir=0
    elif [ $ohtml -eq 1 ];     	then
        html_output=$i
        ohtml=0
    elif [ $olatex -eq 1 ];     then
        latex_output=$i
        olatex=0
     elif [ $oxml -eq 1 ];     	then
        xml_output=$i
        oxml=0
    elif [ $ortf -eq 1 ];     	then
        rtf_output=$i
        ortf=0
    elif [ $oman -eq 1 ];     	then
        man_output=$i
        oman=0
    else   
        progname=$i
    fi
done

if [ "${generate_latex}" = "NO" ]; then
	latex_output=
fi
if [ "${generate_man}" = "NO" ]; then
	man_output=
fi
if [ "${generate_xml}" = "NO" ]; then
	xml_output=
fi
if [ "${generate_rtf}" = "NO" ]; then
	rtf_output=
fi


export PINGDIR=${PINGDIR}
export INPUT_DIRECTORY=${input_directory}
export STATIC_DIRECTORY=${static_directory}
export MODULE_DIRECTORY=${module_directory}
export OUTPUT_DIRECTORY=${output_directory}
export DOXYGEN_DIRECTORY=${doxygen_directory}
export IMAGE_DIRECTORY=${image_directory}
export GENERATE_HTML=${generate_html}
export HTML_OUTPUT=${html_output}
export GENERATE_LATEX=${generate_latex}
export LATEX_OUTPUT=${latex_output}
export GENERATE_MAN=${generate_man}
export MAN_OUTPUT=${man_output}
export GENERATE_XML=${generate_xml}
export XML_OUTPUT=${xml_output}
export GENERATE_RTF=${generate_rtf}
export RTF_OUTPUT=${rtf_output}
# envsetting="INPUT_DIRECTORY=${input_directory} OUTPUT_DIRECTORY=${output_directory}"
# envsetting+=" DOXYGEN_DIRECTORY=${doxygen_directory} IMAGE_DIRECTORY=${image_directory}"
# envsetting+=" GENERATE_HTML=${generate_html} HTML_OUTPUT=${html_output}"
# envsetting+=" GENERATE_LATEX=${generate_latex} LATEX_OUTPUT=${latex_output}"
# envsetting+=" GENERATE_MAN=${generate_man} MAN_OUTPUT=${man_output}"
# envsetting+=" GENERATE_XML=${generate_xml} XML_OUTPUT=${xml_output}"
# envsetting+=" GENERATE_RTF=${generate_rtf} RTF_OUTPUT=${rtf_output}"
# echo "env ${envsetting} ${dox} ${cfg}"
# env ${envsetting} ${dox} ${cfg}

echo ${dox} ${cfg}
${dox} ${cfg}

  
## further settings
if [ $verb -eq 1 ];     then
 	echo
	echo "* Setting parameters: input/output filenames and directories..."
fi
