# Set the installation prefix from $SWIPL_INSTALL_PREFIX.  If this
# environment variable ends in /@builddir@, replace @builddir@ with
# the name of the binary build directory, so we can easily install
# multiple different versions in the same filesystem

function(set_install_prefix)
  set(prefix "$ENV{SWIPL_INSTALL_PREFIX}")

  if(prefix)
    if(prefix MATCHES "@builddir@")
      get_filename_component(bindir ${CMAKE_CURRENT_BINARY_DIR} NAME)
      string(REGEX REPLACE "\@builddir\@" ${bindir} install_prefix ${prefix})
    else()
      string(REGEX REPLACE "/\@builddir\@" "" install_prefix ${prefix})
    endif()
    set(CMAKE_INSTALL_PREFIX ${install_prefix} PARENT_SCOPE)
  endif()
endfunction()
