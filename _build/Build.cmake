#set(TEST_DIR "/tmp/my_work_dir")
set(CONFIG_TYPE RelWithDebInfo)
#file(MAKE_DIRECTORY ${TEST_DIR})
# L'appelant doit spécifier les variables suivantes:
# - GIT_WORKSPACE: le chemin de base de ce dépot
# - CONFIG_BUILD_DIR: le répertoire où seront compilées les sources

cmake_policy(SET CMP0057 NEW)

# Sous windows, il faut convertir en chemin CMake pour éviter les
# incohérences entre les '/' et les '\'.
file(TO_CMAKE_PATH "${CONFIG_BUILD_DIR}" CONFIG_BUILD_DIR)
file(TO_CMAKE_PATH "${GIT_WORKSPACE}" GIT_WORKSPACE)

# A partir de CMake 3.20:
# cmake_path(CONVERT "${CONFIG_BUILD_DIR}" TO_CMAKE_PATH_LIST CONFIG_BUILD_DIR NORMALIZE)
# cmake_path(CONVERT "${GIT_WORKSPACE}" TO_CMAKE_PATH_LIST GIT_WORKSPACE NORMALIZE)

set(CONFIG_CACHE_DIR "${GIT_WORKSPACE}/_build/CacheMain.cmake")
set(VCPKG_CMAKE_CACHE "${CONFIG_BUILD_DIR}/vcpkg/my.vcpkg.config.cmake")
set(ALL_COMMANDS
  "configure_arccon" "build_arccon" "install_arccon"
  "configure_arccore" "build_arccore" "test_arccore" "install_arccore"
  )
if (NOT BUILD_COMMANDS)
  set(BUILD_COMMANDS ${ALL_COMMANDS})
endif()

message(STATUS "Build command = ${BUILD_COMMANDS}")

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

set(CONFIG_VCPKG_INSTALL_PATH "${CONFIG_BUILD_DIR}/vcpkg/vcpkg_installed")

if (WIN32)
  set(DO_WITH_VCPKG TRUE)
endif()

if (UNIX)
  set(GENERATOR_ARG "-GNinja")
  set(TEST_TARGET test)
endif()
if (WIN32)
  set(TEST_TARGET RUN_TESTS)
  # TODO: Il faut recopier les '.dll' utilisées dans le répertoire des libs
endif()

message(STATUS "Configure and build arccon")
if("configure_arccon" IN_LIST BUILD_COMMANDS)
  do_command(${CMAKE_COMMAND} -S "${GIT_WORKSPACE}/arccon" -B "${CONFIG_BUILD_DIR}/arccon" ${GENERATOR_ARG}
  "-DVCPKG_CMAKE_CACHE=${VCPKG_CMAKE_CACHE}"
  -C "${CONFIG_CACHE_DIR}"
  "-DCMAKE_INSTALL_PREFIX=${CONFIG_BUILD_DIR}/install_arccon"
  )
endif()
if("build_arccon" IN_LIST BUILD_COMMANDS)
  do_command(${CMAKE_COMMAND} --build "${CONFIG_BUILD_DIR}/arccon")
endif()
if("install_arccon" IN_LIST BUILD_COMMANDS)
  do_command(${CMAKE_COMMAND} --build "${CONFIG_BUILD_DIR}/arccon" --target install)
endif()

message(STATUS "Configure and build arccore")
if("configure_arccore" IN_LIST BUILD_COMMANDS)
  if (DO_WITH_VCPKG)
    # Copie le fichier contenant les dépendances des packages 'vcpkg' nécessaires pour arccore
    file(COPY "${GIT_WORKSPACE}/_build/arccore/vcpkg.json" DESTINATION "${GIT_WORKSPACE}/arccore")
    do_command(${CMAKE_COMMAND} -S "${GIT_WORKSPACE}/arccore" -B "${CONFIG_BUILD_DIR}/arccore" ${GENERATOR_ARG}
      "-DVCPKG_CMAKE_CACHE=${VCPKG_CMAKE_CACHE}"
      "-DCMAKE_INSTALL_PREFIX=${CONFIG_BUILD_DIR}/install_arccore"
      "-DArccon_ROOT=${CONFIG_BUILD_DIR}/install_arccon"
      -DBUILD_SHARED_LIBS=TRUE
      -DCMAKE_TOOLCHAIN_FILE=${GIT_WORKSPACE}/vcpkg/scripts/buildsystems/vcpkg.cmake
      -DCMAKE_BUILD_TYPE=${CONFIG_TYPE}
      -DARCCORE_BUILD_MODE=Check
      )
  else()
    do_command(${CMAKE_COMMAND} -S "${GIT_WORKSPACE}/arccore" -B "${CONFIG_BUILD_DIR}/arccore" ${GENERATOR_ARG}
      "-DVCPKG_CMAKE_CACHE=${VCPKG_CMAKE_CACHE}"
      -C "${CONFIG_CACHE_DIR}"
      "-DCMAKE_INSTALL_PREFIX=${CONFIG_BUILD_DIR}/install_arccore"
      "-DArccon_ROOT=${CONFIG_BUILD_DIR}/install_arccon"
      -DBUILD_SHARED_LIBS=TRUE
      -DCONFIG_COPY_DLLS=TRUE
      -DCMAKE_BUILD_TYPE=${CONFIG_TYPE}
      -DARCCORE_BUILD_MODE=Check
      )
  endif()
endif()

if("build_arccore" IN_LIST BUILD_COMMANDS)
  do_command(${CMAKE_COMMAND} --build "${CONFIG_BUILD_DIR}/arccore")
endif()
#do_command(${CMAKE_COMMAND} --build "${CONFIG_BUILD_DIR}/arccore" --target test)
if("test_arccore" IN_LIST BUILD_COMMANDS)
  do_command(${CMAKE_COMMAND} --build "${CONFIG_BUILD_DIR}/arccore" --target ${TEST_TARGET})
endif()

# ----------------------------------------------------------------------------
# Local Variables:
# tab-width: 2
# indent-tabs-mode: nil
# coding: utf-8-with-signature
# End:
