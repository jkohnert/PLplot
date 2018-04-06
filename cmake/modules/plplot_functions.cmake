# Collection of useful functions that are required by PLplot.

function(list_example_files path device suffix output_list)
  # Return list of files (with ${path}/ prepended to form the full path
  # name for each file) that are generated by plplot-test.sh for a
  # particular device and file suffix corresponding to front-end
  # language.  This list will be used for OUTPUT files of a custom
  # command so that these files will be properly deleted by "make
  # clean".  Thus, it doesn't matter if we miss a few examples or
  # pages that are only implemented for one of the languages.
  # However, if we specify a file that is not generated by
  # plplot-test.sh for the specified device and language, then that
  # custom command is never satisfied and will continue to regenerate
  # the files.  Therefore only specify examples and pages that you
  # _know_ are generated by all language bindings.
  # MAINTENANCE
  set(examples_pages_LIST
    x00:01
    x01:01
    x02:02
    x03:01
    x04:02
    x05:01
    x06:05
    x07:20
    # x08:10 when Ada and OCaml are propagated.
    x08:08
    x09:05
    x10:01
    x11:08
    x12:01
    x13:01
    x14:02
    x14a:02
    x15:03
    x16:05
    x17:01
    x18:08
    # x19:05 when Ada and OCaml are propagated.
    x19:04
    x20:06
    x21:03
    x22:04
    x23:16
    x24:01
    x25:08
    x26:02
    x27:20
    x28:05
    x29:10
    x30:02
    x31:01
    # 32 missing deliberately since that only implemented for C
    x33:04
    )

  # This list taken directly from plplot-test.sh.cmake.  Update as needed.
  # MAINTENANCE
  if(
      ${device} STREQUAL "png" OR
      ${device} STREQUAL "pngcairo" OR
      ${device} STREQUAL "epscairo" OR
      ${device} STREQUAL "jpeg" OR
      ${device} STREQUAL "xfig" OR
      ${device} STREQUAL "svg" OR
      ${device} STREQUAL "svgcairo" OR
      ${device} STREQUAL "bmpqt" OR
      ${device} STREQUAL "jpgqt" OR
      ${device} STREQUAL "pngqt" OR
      ${device} STREQUAL "ppmqt" OR
      ${device} STREQUAL "tiffqt" OR
      ${device} STREQUAL "svgqt" OR
      ${device} STREQUAL "epsqt" OR
      ${device} STREQUAL "pdfqt" OR
      ${device} STREQUAL "gif"
      )
    set(familying ON)
  else(
      ${device} STREQUAL "png" OR
      ${device} STREQUAL "pngcairo" OR
      ${device} STREQUAL "epscairo" OR
      ${device} STREQUAL "jpeg" OR
      ${device} STREQUAL "xfig" OR
      ${device} STREQUAL "svg" OR
      ${device} STREQUAL "svgcairo" OR
      ${device} STREQUAL "bmpqt" OR
      ${device} STREQUAL "jpgqt" OR
      ${device} STREQUAL "pngqt" OR
      ${device} STREQUAL "ppmqt" OR
      ${device} STREQUAL "tiffqt" OR
      ${device} STREQUAL "svgqt" OR
      ${device} STREQUAL "epsqt" OR
      ${device} STREQUAL "pdfqt" OR
      ${device} STREQUAL "gif"
      )
    set(familying OFF)
  endif(
    ${device} STREQUAL "png" OR
    ${device} STREQUAL "pngcairo" OR
    ${device} STREQUAL "epscairo" OR
    ${device} STREQUAL "jpeg" OR
    ${device} STREQUAL "xfig" OR
    ${device} STREQUAL "svg" OR
    ${device} STREQUAL "svgcairo" OR
    ${device} STREQUAL "bmpqt" OR
    ${device} STREQUAL "jpgqt" OR
    ${device} STREQUAL "pngqt" OR
    ${device} STREQUAL "ppmqt" OR
    ${device} STREQUAL "tiffqt" OR
    ${device} STREQUAL "svgqt" OR
    ${device} STREQUAL "epsqt" OR
    ${device} STREQUAL "pdfqt" OR
    ${device} STREQUAL "gif"
    )
  set(file_list)

  foreach(example_pages ${examples_pages_LIST})
    string(REGEX REPLACE "^(.*):.*$" "\\1" example ${example_pages})
    string(REGEX REPLACE "^.*:(.*)$" "\\1" pages ${example_pages})
    if(${suffix} STREQUAL "a")
      string(REGEX REPLACE "^x" "xtraditional" traditional_example ${example})
      string(REGEX REPLACE "^x" "xstandard" example ${example})
    else(${suffix} STREQUAL "a")
      set(traditional_example)
    endif(${suffix} STREQUAL "a")
    if(familying)
      foreach(famnum RANGE 1 ${pages})
        if(famnum LESS 10)
          set(famnum 0${famnum})
        endif(famnum LESS 10)
        list(APPEND file_list ${path}/${example}${suffix}${famnum}.${device})
        if(traditional_example)
          list(APPEND file_list ${path}/${traditional_example}${suffix}${famnum}.${device})
        endif(traditional_example)
      endforeach(famnum RANGE 1 ${pages})
    else(familying)
      list(APPEND file_list ${path}/${example}${suffix}.${device})
      if(traditional_example)
        list(APPEND file_list ${path}/${traditional_example}${suffix}.${device})
      endif(traditional_example)
    endif(familying)
    if(NOT ${example} MATCHES "x.*14a")
      list(APPEND file_list ${path}/${example}${suffix}_${device}.txt)
      if(traditional_example)
        list(APPEND file_list ${path}/${traditional_example}${suffix}_${device}.txt)
      endif(traditional_example)
    endif(NOT ${example} MATCHES "x.*14a")
  endforeach(example_pages ${examples_pages_LIST})

  set(${output_list} ${file_list} PARENT_SCOPE)
endfunction(list_example_files)

# CMake-2.6.x duplicates this list so work around that bug by removing
# those duplicates.
if(CMAKE_PLATFORM_IMPLICIT_LINK_DIRECTORIES)
  list(REMOVE_DUPLICATES CMAKE_PLATFORM_IMPLICIT_LINK_DIRECTORIES)
endif(CMAKE_PLATFORM_IMPLICIT_LINK_DIRECTORIES)

# Filter all CMAKE_<LANG>_IMPLICIT_LINK_DIRECTORIES list elements from
# rpath_in list.  Note, this uses variables that are only defined after
# languages have been enabled but according to the documentation the
# logic is only invoked when the function is invoked so this should be
# OK _if care is used that this function is invoked only after the
# languages have been enabled_.  C is enabled immediately so that will
# serve most purposes, but CXX and Fortran are enabled later so if
# you want those special system locations removed (unlikely but
# possible) then you are going to have to be somewhat more careful
# when this function is invoked.

function(filter_rpath rpath)
  #message("DEBUG: ${rpath} = ${${rpath}}")
  set(internal_rpath ${${rpath}})
  if(internal_rpath)
    # Remove duplicates and empty elements.
    list(REMOVE_DUPLICATES internal_rpath)
    list(REMOVE_ITEM internal_rpath "")
    set(directories_to_be_removed
      ${CMAKE_C_IMPLICIT_LINK_DIRECTORIES}
      ${CMAKE_CXX_IMPLICIT_LINK_DIRECTORIES}
      ${CMAKE_Fortran_IMPLICIT_LINK_DIRECTORIES}
      )

    if(directories_to_be_removed)
      list(REMOVE_DUPLICATES directories_to_be_removed)
    endif(directories_to_be_removed)

    if(directories_to_be_removed)
      list(REMOVE_ITEM internal_rpath ${directories_to_be_removed})
    endif(directories_to_be_removed)
  endif(internal_rpath)
  #message("DEBUG: (filtered) ${rpath} = ${internal_rpath}")
  set(${rpath} ${internal_rpath} PARENT_SCOPE)
endfunction(filter_rpath)

if(MINGW)
  # Useful function to convert Windows list of semicolon-delimited
  # PATHs to the equivalent list of MSYS PATHs (exactly like the
  # colon-delimited Unix list of PATHs except the driver letters are
  # specified as the initial one-character component of each of the
  # PATHs).  For example, this function will transform the Windows
  # list of PATHs, "z:\path1;c:\path2" to "/z/path1:/c/path2".
  function(determine_msys_path MSYS_PATH NATIVE_PATH)
    #message(STATUS "NATIVE_PATH = ${NATIVE_PATH}")
    string(REGEX REPLACE "^\([a-zA-z]\):" "/\\1" PATH  "${NATIVE_PATH}")
    string(REGEX REPLACE ";\([a-zA-z]\):" ";/\\1" PATH  "${PATH}")
    string(REGEX REPLACE ";" ":" PATH  "${PATH}")
    file(TO_CMAKE_PATH "${PATH}" PATH)
    #message(STATUS "MSYS_PATH = ${PATH}")
    set(${MSYS_PATH} ${PATH} PARENT_SCOPE)
  endfunction(determine_msys_path)
endif(MINGW)

function(configure_file_generate)
  # Configure files that contain both normal items
  # to configure (referenced as ${VAR} or @VAR@) as well as
  # generator expressions (referenced as $<...>).
  # The arguments of this function have exactly the
  # same syntax and meaning as configure_file.

  list(GET ARGV 0 input_file)
  list(GET ARGV 1 output_file)
  set(configure_file_generate_suffix "_cf_only")
  set(intermediate_file ${output_file}${configure_file_generate_suffix})

  # Locally modify ARGV so that output file for configure file is
  # redirected to intermediate_file.
  list(REMOVE_AT ARGV 1)
  list(INSERT ARGV 1 ${intermediate_file})

  # Configure all but generator expressions.
  configure_file(${ARGV})

  # Configure generator expressions.
  # N.B. these ${output_file} results will only be available
  # at generate time.
  file(GENERATE
    OUTPUT ${output_file}
    INPUT ${intermediate_file}
    )
endfunction(configure_file_generate)

function(configure_library_build library library_type lib_src tll_arguments)
  # This function should be duplicated for the PLplot, ephcom, and
  # te_gen software projects.  Configure build of one of the PLplot,
  # ephcom or te_gen libraries, modules (dll's), or swig modules and
  # corresponding namespaced ALIAS library in a uniform way.  This
  # function is implemented using a combination of the add_library and
  # target_link_libraries (or swig_add_library and
  # swig_link_libraries) commands followed by setting relevant library
  # properties.

  # library contains a string corresponding to the target name of a library.

  # library_type should be one of
  # * empty string (in which case the library is one of SHARED or STATIC
  #   depending on the value of BUILD_SHARED_LIBS)
  # * SHARED (the library is built as a shared library)
  # * STATIC (the library is built as a static library)
  # * MODULE (the library is built as a dll)
  # * <language> (where [case-insensitive] language is one of the languages supported by
  # * swig, and library is built as a swig module.

  # lib_src contains a list of source files for the library.

  # tll_arguments contains a list of arguments for (swig|target)_link_libraries
  # for the library.  If tll_arguments evaluates to a false value (e.g.,
  # an empty string), then (swig|target)_link_libraries will not be called.

  # N.B. Actual arguments used for calls to configure_library_build are values
  # or lists of values and NOT variables.  Therefore, only one level
  # of dereferencing required to access the argument values.

  #message(STATUS "DEBUG: library = ${library}")
  #message(STATUS "DEBUG: lib_src = ${lib_src}")
  #message(STATUS "DEBUG: tll_arguments = ${tll_arguments}")
  #message(STATUS "DEBUG: namespace = ${namespace}")

  # Global variables which must be defined
  #message(STATUS "DEBUG: BUILD_SHARED_LIBS = ${BUILD_SHARED_LIBS}")
  #message(STATUS "DEBUG: NON_TRANSITIVE = ${NON_TRANSITIVE}")
  #message(STATUS "DEBUG: ${library}_SOVERSION = ${${library}_SOVERSION}")
  #message(STATUS "DEBUG: ${library}_VERSION = ${${library}_VERSION}")
  #message(STATUS "DEBUG: CMAKE_INSTALL_LIBDIR = ${CMAKE_INSTALL_LIBDIR}")
  #message(STATUS "DEBUG: USE_RPATH = ${USE_RPATH}")

  # Sanity checks on values of argument variables:
  if("${library}" STREQUAL "")
    message(FATAL_ERROR "configure_library_build: library is empty when it should be a library target name")
  endif("${library}" STREQUAL "")

  if("${library_type}" STREQUAL "")
    # If "${library_type}" is an empty string, then the library is built as static
    # or shared depending on BUILD_SHARED_LIBS, and a swig module build is NOT
    # being configured.
    if(BUILD_SHARED_LIBS)
      set(library_type SHARED)
    else(BUILD_SHARED_LIBS)
      set(library_type STATIC)
    endif(BUILD_SHARED_LIBS)
    set(if_swig_module OFF)
  elseif("${library_type}" STREQUAL "STATIC" OR "${library_type}" STREQUAL "SHARED" OR "${library_type}" STREQUAL "MODULE")
    # For these cases a a swig module build is NOT being configured.
    set(if_swig_module OFF)
  else("${library_type}" STREQUAL "")
    # Assume the caller is trying to configure a build of a swig module by
    # specifying the swig language as "${library_type}" (with any case).
    set(if_swig_module ON)
    # Lower case language used from now on.
    string(TOLOWER "${library_type}" language)
  endif("${library_type}" STREQUAL "")

  if("${lib_src}" STREQUAL "")
    message(FATAL_ERROR "configure_library_build: lib_src is empty when it should be a list of library source files for the ${library} library")
  endif("${lib_src}" STREQUAL "")

  # Sanity check that the external variable LIBRARY_NAMESPACE has been set correctly.
  if(NOT "${LIBRARY_NAMESPACE}" MATCHES ".*::$")
    message(FATAL_ERROR "configure_library_build:LIBRARY_NAMESPACE = ${LIBRARY_NAMESPACE} does not have the correct trailing \"::\"")
  endif(NOT "${LIBRARY_NAMESPACE}" MATCHES ".*::$")

  # Sanity check that all relevant external variables not checked
  # above have been DEFINED.
  set(variables_list)
  list(APPEND variables_list
    NON_TRANSITIVE
    )

  set(original_library ${library})
  set(library ${LIBRARY_TARGET_PREFIX}${library})
  if(if_swig_module)
    foreach(variable ${variables_list})
      if(NOT DEFINED ${variable})
	message(FATAL_ERROR "configure_library_build: (external) ${variable} = NOT DEFINED")
      endif(NOT DEFINED ${variable})
    endforeach(variable ${variables_list})
    swig_add_library(${library} LANGUAGE "${language}" TYPE MODULE SOURCES ${lib_src})
    # Propagate value of this variable (set in swig_add_library macro) to calling environment.
    # Example:
    # original_library = plplotc
    # library = ${LIBRARY_TARGET_PREFIX}plplotc
    # ${SWIG_MODULE_${library}_REAL_NAME} = _${LIBRARY_TARGET_PREFIX}plplotc
    # SWIG_MODULE_plplotc_REAL_NAME (in parent scope) = _${LIBRARY_TARGET_PREFIX}plplotc
    # Alias library name = PLPLOT::plplotc

    set(SWIG_MODULE_${original_library}_REAL_NAME ${SWIG_MODULE_${library}_REAL_NAME} PARENT_SCOPE)
    # Create equivalent namespaced ALIAS library to be used whenever
    # the library target is read only.
    add_library(${LIBRARY_NAMESPACE}${original_library} ALIAS ${SWIG_MODULE_${library}_REAL_NAME})

    if(NOT "${tll_arguments}" STREQUAL "")
      if(NON_TRANSITIVE)
	target_link_libraries(${SWIG_MODULE_${library}_REAL_NAME} PRIVATE ${tll_arguments})
      else(NON_TRANSITIVE)
	target_link_libraries(${SWIG_MODULE_${library}_REAL_NAME} PUBLIC ${tll_arguments})
      endif(NON_TRANSITIVE)
    endif(NOT "${tll_arguments}" STREQUAL "")

    # It is assumed RPATH for swig-generated modules is handled
    # externally, but set the following property to allow symbols to
    # be visible in the module.
    set_target_properties(
      ${SWIG_MODULE_${library}_REAL_NAME}
      PROPERTIES
      COMPILE_DEFINITIONS "USINGDLL"
      )
  else(if_swig_module)
    if("${library_type}" STREQUAL "SHARED")
      list(APPEND variables_list
	${original_library}_SOVERSION
	${original_library}_VERSION
	CMAKE_INSTALL_LIBDIR
	USE_RPATH
	)
    endif("${library_type}" STREQUAL "SHARED")

    foreach(variable ${variables_list})
      if(NOT DEFINED ${variable})
	message(FATAL_ERROR "configure_library_build: (external) ${variable} = NOT DEFINED")
      endif(NOT DEFINED ${variable})
    endforeach(variable ${variables_list})

    add_library(${library} ${library_type} ${lib_src})
    # Create equivalent namespaced ALIAS library to be used whenever
    # the library target is read only.
    add_library(${LIBRARY_NAMESPACE}${original_library} ALIAS ${library})

    if(NOT "${tll_arguments}" STREQUAL "")
      if(NON_TRANSITIVE)
	target_link_libraries(${library} PRIVATE ${tll_arguments})
      else(NON_TRANSITIVE)
	target_link_libraries(${library} PUBLIC ${tll_arguments})
      endif(NON_TRANSITIVE)
    endif(NOT "${tll_arguments}" STREQUAL "")

    # Set library target properties for just the SHARED, MODULE, and STATIC library cases.
    if("${library_type}" STREQUAL "SHARED")
      if(USE_RPATH)
	# Use default setting for LIB_INSTALL_RPATH
	if(NOT DEFINED LIB_INSTALL_RPATH)
	  set(LIB_INSTALL_RPATH "${CMAKE_INSTALL_LIBDIR}")
	endif(NOT DEFINED LIB_INSTALL_RPATH)

	filter_rpath(LIB_INSTALL_RPATH)
	if(LIB_INSTALL_RPATH)
          set_target_properties(
            ${library}
            PROPERTIES
            INSTALL_RPATH "${LIB_INSTALL_RPATH}"
            )
	endif(LIB_INSTALL_RPATH)
      else(USE_RPATH)
	# INSTALL_NAME_DIR only relevant to Mac OS X
	# systems.  Also, this property is only set when rpath is
	# not used (because otherwise it would supersede
	# rpath).
	set_target_properties(
          ${library}
          PROPERTIES
          INSTALL_NAME_DIR "${CMAKE_INSTALL_LIBDIR}"
          )
      endif(USE_RPATH)

      set_target_properties(
	${library}
	PROPERTIES
	COMPILE_DEFINITIONS "USINGDLL"
	SOVERSION ${${original_library}_SOVERSION}
	VERSION ${${original_library}_VERSION}
	)
    elseif("${library_type}" STREQUAL "MODULE")
      # It is assumed RPATH for modules is handled externally, but set
      # the following property to allow symbols to be visible in the
      # module.
      set_target_properties(
	${library}
	PROPERTIES
	COMPILE_DEFINITIONS "USINGDLL"
	)
    elseif("${library_type}" STREQUAL "STATIC")
      set_target_properties(
	${library}
	PROPERTIES
	# This allows static library builds to be linked by shared libraries.
	POSITION_INDEPENDENT_CODE ON
	)
    endif("${library_type}" STREQUAL "SHARED")
  endif(if_swig_module)
endfunction(configure_library_build library library_type lib_src tll_arguments)
