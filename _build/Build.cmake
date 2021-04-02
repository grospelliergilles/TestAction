#set(TEST_DIR "/tmp/my_work_dir")
set(CONFIG_TYPE Debug)
#file(MAKE_DIRECTORY ${TEST_DIR})
# L'appelant doit spécifier les variables suivantes:
# - GIT_WORKSPACE: le chemin de base de ce dépot
# - CONFIG_BUILD_DIR: le répertoire où seront compilées les sources

# Sous windows, il faut convertir en chemin CMake pour éviter les
# incohérences entre les '/' et les '\'.
file(TO_CMAKE_PATH "${CONFIG_BUILD_DIR}" CONFIG_BUILD_DIR)
file(TO_CMAKE_PATH "${GIT_WORKSPACE}" GIT_WORKSPACE)

# A partir de CMake 3.20:
# cmake_path(CONVERT "${CONFIG_BUILD_DIR}" TO_CMAKE_PATH_LIST CONFIG_BUILD_DIR NORMALIZE)
# cmake_path(CONVERT "${GIT_WORKSPACE}" TO_CMAKE_PATH_LIST GIT_WORKSPACE NORMALIZE)

set(CONFIG_CACHE_DIR "${GIT_WORKSPACE}/_build/CacheMain.txt")

macro(do_command)
  message("TRY COMMAND ARG=${ARGN}")
  execute_process(
    COMMAND ${ARGN}
    RESULT_VARIABLE RET_VALUE
    WORKING_DIRECTORY ${CONFIG_BUILD_DIR}
    )
  message(STATUS "RET_VALUE=${RET_VALUE}")
  if (NOT RET_VALUE EQUAL 0)
    message(FATAL_ERROR "Bad return value R=${RET_VALUE}")
  endif()
endmacro()

if (UNIX)
  set(GENERATOR_ARG "-GNinja")
endif()
if (WIN32)
  # TODO: Il faut recopier les '.dll' utilisées dans le répertoire des libs
endif()

message(STATUS "Configure and build arccon")
do_command(${CMAKE_COMMAND} -S "${GIT_WORKSPACE}/arccon" -B "${CONFIG_BUILD_DIR}/arccon" ${GENERATOR_ARG}
  "-DVCPKG_CMAKE_CACHE=${CONFIG_BUILD_DIR}/vcpkg/my.vcpkg.config.cmake"
  -C "${CONFIG_CACHE_DIR}"
  "-DCMAKE_INSTALL_PREFIX=${CONFIG_BUILD_DIR}/install_arccon"
  )
do_command(${CMAKE_COMMAND} --build "${CONFIG_BUILD_DIR}/arccon")
do_command(${CMAKE_COMMAND} --build "${CONFIG_BUILD_DIR}/arccon" --target install)

message(STATUS "Configure and build arccore")
do_command(${CMAKE_COMMAND} -S "${GIT_WORKSPACE}/arccore" -B "${CONFIG_BUILD_DIR}/arccore" ${GENERATOR_ARG}
  "-DVCPKG_CMAKE_CACHE=${CONFIG_BUILD_DIR}/vcpkg/my.vcpkg.config.cmake"
  -C "${CONFIG_CACHE_DIR}"
  "-DCMAKE_INSTALL_PREFIX=${CONFIG_BUILD_DIR}/install_arccore"
  "-DArccon_ROOT=${CONFIG_BUILD_DIR}/install_arccon"
  -DBUILD_SHARED_LIBS=TRUE
  )
do_command(${CMAKE_COMMAND} --build "${CONFIG_BUILD_DIR}/arccore")
do_command(${CMAKE_COMMAND} --build "${CONFIG_BUILD_DIR}/arccore" --target test)

# ----------------------------------------------------------------------------
# Local Variables:
# tab-width: 2
# indent-tabs-mode: nil
# coding: utf-8-with-signature
# End:
