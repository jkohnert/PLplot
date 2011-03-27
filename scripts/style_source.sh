#!/bin/bash

# $Id$

# This script will run uncrustify on all source files registered in
# the lists below (and scripts/convert_comment.py on all C source
# files registerd below) and summarize which uncrustified or
# comment-converted files would be different.  (convert_comment.py
# converts /* ... */ style comments to the c99-acceptable // form of
# comments because uncrustify does not (yet) have that configuration
# choice.)  Also there are options to view the differences in detail
# and/or apply them.  This script must be run from the top-level
# directory of the PLplot source tree.

# Copyright (C) 2009-2010 Alan W. Irwin
#
# This file is part of PLplot.
#
# PLplot is free software; you can redistribute it and/or modify
# it under the terms of the GNU Library General Public License as published
# by the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# PLplot is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with PLplot; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

usage()
{
echo '
Usage: ./style_source.sh [OPTIONS]

Options:
   [--diff [diff options]]  Show detailed style differences in source code
                            with optional concatanated diff options headed
                            by a single hyphen.  If no diff options are
                            specified, then -auw is used by default.
   [--nodiff]               Summarize style differences in source code (default).
   [--apply]                Apply style differences to source code (POWERFUL).
   [--noapply]              Do not apply style differences to source code (default).
   [--help]                 Show this message.

'
   exit $1
}

# Figure out what script options were specified by the user.
# Defaults
export diff=OFF
export apply=OFF
export diff_options="-auw"

while test $# -gt 0; do

    case $1 in
	--diff)
	    diff=ON
	    case $2 in
		-[^-]*)
		    diff_options=$2
		    shift
		    ;;
	    esac
	    ;;
	--nodiff)
	    diff=OFF
	    ;;
	--apply)
	    apply=ON
	    ;;
	--noapply)
	    apply=OFF
	    ;;
	--help)
            usage 0 1>&2
            ;;
	*)
            usage 1 1>&2
            ;;
    esac
    shift
done

allowed_version=0.56
version=$(uncrustify --version)
if [ "$version" != "uncrustify $allowed_version" ] ; then
    echo "
Detected uncrustify version = '$version'.
This script only works with uncrustify $allowed_version."
    exit 1
fi

if [ ! -f src/plcore.c ] ; then 
    echo "This script can only be run from PLplot top-level source tree."
    exit 1
fi

if [ "$apply" = "ON" ] ; then
    echo '
The --apply option is POWERFUL and will replace _all_ files mentioned in
previous runs of style_source.sh with their uncrustified versions.
'
    ANSWER=
    while [ "$ANSWER" != "yes" -a "$ANSWER" != "no" ] ; do
	echo -n "Continue (yes/no)? "
	read ANSWER
    done
    if [ "$ANSWER" = "no" ] ; then
	echo "Immediate exit specified!"
	exit
    fi
fi

export csource_LIST
# Top level directory.
csource_LIST="config.h.cmake"

# src directory
csource_LIST="$csource_LIST src/*.[ch]"

# All C source (i.e., exclude qt.h) in include directory.
csource_LIST="$csource_LIST $(ls include/*.h include/*.h.in include/*.h.cmake |grep -v qt.h)" 

# Every subdirectory of lib.
csource_LIST="$csource_LIST lib/*/*.[ch] lib/qsastime/qsastimeP.h.in"

# C part of drivers.
csource_LIST="$csource_LIST drivers/*.c"

# C part of examples.
csource_LIST="$csource_LIST examples/c/*.[ch] examples/tk/*.c"

# C source in fonts.
csource_LIST="$csource_LIST fonts/*.c"

# C source in utils.
csource_LIST="$csource_LIST utils/*.c"

csource_LIST="$csource_LIST bindings/tcl/*.[ch] bindings/f95/*.c bindings/f95/plstubs.h bindings/gnome2/*/*.c bindings/ocaml/plplot_impl.c bindings/ocaml/plcairo/plcairo_impl.c bindings/python/plplot_widgetmodule.c bindings/f77/*.c bindings/f77/plstubs.h bindings/tk/*.[ch] bindings/tk-x-plat/*.[ch] bindings/octave/plplot_octave.h.in bindings/octave/plplot_octave_rej.h bindings/octave/massage.c"

export cppsource_LIST

# C++ part of bindings/c++
cppsource_LIST="bindings/c++/plstream.cc  bindings/c++/plstream.h"

# C++ part of include. 
cppsource_LIST="$cppsource_LIST include/qt.h"

# C++ part of drivers.
cppsource_LIST="$cppsource_LIST drivers/wxwidgets.h drivers/*.cpp" 

# C++ part of examples.
cppsource_LIST="$cppsource_LIST examples/c++/*.cc examples/c++/*.cpp examples/c++/*.h"

# C++ source in bindings.
cppsource_LIST="$cppsource_LIST bindings/qt_gui/plqt.cpp bindings/wxwidgets/wxPLplotstream.cpp bindings/wxwidgets/wxPLplotwindow.cpp bindings/wxwidgets/wxPLplotwindow.h bindings/wxwidgets/wxPLplotstream.h.in"

export javasource_LIST

# Java part of bindings/java
javasource_LIST="bindings/java/*.java bindings/java/*.java.in"

# Java part of examples/java
javasource_LIST="$javasource_LIST examples/java/*.java"

export dsource_LIST

# D part of bindings/d
dsource_LIST="bindings/d/*.d"

# D part of examples/d
dsource_LIST="$dsource_LIST examples/d/*.d"

# Check that source file lists actually refer to files.
for source in $csource_LIST $cppsource_LIST $javasource_LIST $dsource_LIST ; do
    if [ ! -f $source ] ; then
	echo $source is not a regular file so this script will not work without further editing.
	exit 1
    fi
done

transform_source()
{
    # $1 is a list of source files of a particular language.
    # $2 is the language identification string for those source files in
    # the form needed by uncrustify.  From the uncrustify man page those
    # language id forms are C, CPP, D, CS, JAVA, PAWN, VALA, OC, OC+
    u_command="uncrustify -c uncrustify.cfg -q -l $2"
    # $3 is either "comments" to indicate comments will be transformed
    # using scripts/convert_comment.py or any other string (or
    # nothing) to indicate uncrustify will be used.
    if [ "$3" = "comments" ] ; then
        c_command="scripts/convert_comment.py"
	# Check all files for run-time errors with the python script.
	# These run-time errors signal that there is some comment
	# style which the script cannot handle.  The reason we do this
	# complete independent check here is that run-time errors can
	# be lost in the noise if a large conversion is being done.
	# Also, run-time errors will not occur for the usual case
	# below where cmp finds an early difference.
	for language_source in $1 ; do
	    $c_command < $language_source >/dev/null
	    c_command_rc=$?
	    if [ $c_command_rc -ne 0 ] ; then
		echo "ERROR: $c_command failed for file $language_source"
		exit 1
	    fi
	done
    else
        c_command="cat -"
    fi

    # Process $c_command after $u_command so that comments will be rendered
    # in standard form by uncrustify before scripts/convert_comment.py
    # is run.

    for language_source in $1 ; do
	$u_command < $language_source | $c_command | \
	    cmp --quiet $language_source -
	if [ "$?" -ne 0 ] ; then
	    ls $language_source
	    if [ "$diff" = "ON" ] ; then
		$u_command < $language_source | $c_command | \
		    diff $diff_options $language_source -
	    fi

	    if [ "$apply" = "ON" ] ; then
		$u_command < $language_source | $c_command >| /tmp/temporary.file
		mv -f /tmp/temporary.file $language_source
	    fi
	fi
    done
}

transform_source "$csource_LIST" C "comments"
transform_source "$cppsource_LIST" CPP "comments"
transform_source "$javasource_LIST" JAVA "comments"
transform_source "$dsource_LIST" D
