include(Documentation)

set(SWIPL      ${CMAKE_INSTALL_PREFIX}/bin/swipl)
set(LATEX2HTML ${CMAKE_INSTALL_PREFIX}/lib/swipl/bin/latex2html ${DOC_OPTIONS})
set(DOC2TEX    ${SWIPL_ROOT}/man/doc2tex)
set(RUNTEX     ${SWIPL_ROOT}/man/runtex ${DOC_OPTIONS})
set(PLTOTEX    ${SWIPL} ${SWIPL_ROOT}/packages/pltotex.pl --)
set(TXTTOTEX   ${SWIPL} ${SWIPL_ROOT}/packages/txttotex.pl --)
set(LIBTOTEX   ${SWIPL} ${SWIPL_ROOT}/man/libtotex.pl --)

function(doc2tex file)
  string(REPLACE ".doc" ".tex" tex ${file})
  add_custom_command(
      OUTPUT ${tex}
      COMMAND ${DOC2TEX} ${CMAKE_CURRENT_SOURCE_DIR}/${file} > ${tex}
      DEPENDS ${file})
  set(texfiles ${texfiles} ${tex} PARENT_SCOPE)
endfunction()

function(txt2tex file)
  string(REPLACE ".txt" ".tex" tex ${file})
  add_custom_command(
      OUTPUT ${tex}
      COMMAND ${TXTTOTEX} ${CMAKE_CURRENT_SOURCE_DIR}/${file}
      DEPENDS ${file})
  set(texfiles ${texfiles} ${tex} PARENT_SCOPE)
endfunction()

function(copy_file file)
  add_custom_command(
      OUTPUT ${file}
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
              ${CMAKE_CURRENT_SOURCE_DIR}/${file} ${file})
  set(cpfiles ${cpfiles} ${file} PARENT_SCOPE)
endfunction()


# pldoc file.pl [out.tex] [library(lib)]

function(pldoc file)
  set(tex)
  set(lib)
  set(options)

  foreach(arg ${ARGN})
    if(arg MATCHES ".*\\.tex")
      set(tex ${arg})
    elseif(arg MATCHES "library")
      set(lib "\"${arg}\"")
    elseif(arg MATCHES "^--")
      set(options ${options} ${arg})
    endif()
  endforeach()

  if(NOT tex)
    string(REGEX REPLACE "\\.(pl|md)" ".tex" tex ${file})
    string(REPLACE "_" "" tex ${tex})
  endif()

  if(NOT lib)
    if(file MATCHES "\\.md")
      set(lib ${CMAKE_CURRENT_SOURCE_DIR}/${file})
    else()
      get_filename_component(base ${file} NAME_WE)
      if(libsubdir)
	set(lib "\"library('${libsubdir}/${base}')\"")
      else()
	set(lib "\"library('${base}')\"")
      endif()
    endif()
  endif()

  get_filename_component(base ${file} NAME_WE)
  add_custom_command(
      OUTPUT ${tex}
      COMMAND ${PLTOTEX} --out=${tex} ${seclevel} ${options} ${lib}
      DEPENDS ${file})

  set(texfiles ${texfiles} ${tex} PARENT_SCOPE)
endfunction()

function(flush_src)
  if(src)
    pldoc(${src})
  endif()
  set(src "" PARENT_SCOPE)
  set(texfiles ${texfiles} PARENT_SCOPE)
endfunction()

# pkg_doc(pkg
#	  [ SOURCE file.pl [out.tex] [library(...)] ]*
#	  [ SOURCES file.pl file.doc ... ])

function(pkg_doc pkg)
  set(pldoc)
  set(docfiles)
  set(mode)
  set(texfiles)
  set(cpfiles)
  set(src)
  set(seclevel)
  set(libsubdir)

  foreach(arg ${ARGN})
    if(arg STREQUAL "SOURCES")
      flush_src()
      set(mode sources)
    elseif(arg STREQUAL "SOURCE")
      flush_src()
      set(mode source)
      set(src)
    elseif(arg STREQUAL "LIBSUBDIR")
      set(mode lbsubdir)
    elseif(arg STREQUAL "SECTION")
      flush_src()
      set(seclevel --section)
      set(mode sources)
    elseif(arg STREQUAL "SUBSECTION")
      flush_src()
      set(seclevel --subsection)
      set(mode sources)
    elseif(arg STREQUAL "SUBSUBSECTION")
      flush_src()
      set(seclevel --subsubsection)
      set(mode sources)
    elseif(mode STREQUAL "source")
      set(src ${src} ${arg})
    elseif(mode STREQUAL "lbsubdir")
      set(libsubdir ${arg})
      set(mode)
    else()
      if(arg MATCHES "\\.(pl|md)")
        pldoc(${arg})
      elseif(arg MATCHES "\\.doc")
        doc2tex(${arg})
      elseif(arg MATCHES "\\.txt")
        txt2tex(${arg})
      elseif(arg MATCHES "\\.(gif|pdf|eps|bib)")
        copy_file(${arg})
      elseif(arg MATCHES "\\.tex")
        set(texfiles ${texfiles} ${arg})
      endif()
    endif()
  endforeach()
  flush_src()

  doc2tex(${pkg}.doc)

  tex_byproducts(${pkg} byproducts)

  prepend(texdeps ${CMAKE_CURRENT_BINARY_DIR}/ ${pkg}.tex ${texfiles} ${cpfiles})

  add_custom_command(
      OUTPUT ${pkg}.pdf
      COMMAND ${RUNTEX} --pdf ${pkg}
      DEPENDS ${texdeps}
      BYPRODUCTS ${byproducts}
      COMMENT "Generating ${pkg}.pdf")

  add_custom_target(
      ${pkg}.doc.pdf
      DEPENDS ${pkg}.pdf)

  add_custom_command(
      OUTPUT ${pkg}.html
      COMMAND ${LATEX2HTML} ${pkg}
      DEPENDS ${texdeps})

  add_custom_target(
      ${pkg}.doc.html
      DEPENDS ${pkg}.html)

  add_dependencies(doc ${pkg}.doc.pdf ${pkg}.doc.html)

  if(INSTALL_DOCUMENTATION)
    if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${pkg}.html)
      install(FILES ${pkg}.html
	      DESTINATION ${SWIPL_INSTALL_PREFIX}/doc/packages/)
    else()
      install(FILES ${pkg}.html
	      DESTINATION ${SWIPL_INSTALL_PREFIX}/doc/packages/)
    endif()
  endif()
endfunction()
