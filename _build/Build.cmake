#set(TEST_DIR "/tmp/my_work_dir")
set(CONFIG_TYPE RelWithDebInfo)
set(CONFIG_TYPE Debug)
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
  "configure_dependencies" "build_dependencies" "install_dependencies"
  "configure_axlstar" "build_axlstar" "install_axlstar"
  "configure_arccore" "build_arccore" "test_arccore" "install_arccore"
  "configure_arcane" "build_arcane" "test_arcane" "install_arcane"
  )
if (NOT BUILD_COMMANDS)
  set(BUILD_COMMANDS ${ALL_COMMANDS})
endif()

message(STATUS "Build command = ${BUILD_COMMANDS}")

function(do_command command_name)
  set(options        )
  set(oneValueArgs   WORKING_DIRECTORY)
  set(multiValueArgs )

  cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
  message(STATUS "WORKING_DIRECTORY=${ARGS_WORKING_DIRECTORY}")
  if (NOT ARGS_WORKING_DIRECTORY)
    set(ARGS_WORKING_DIRECTORY ${CONFIG_BUILD_DIR})
  endif()

  message(STATUS "TRY COMMAND COMMAND=${command_name} WORKING_DIRECTORY=${ARGS_WORKING_DIRECTORY} ARGS=${ARGS_UNPARSED_ARGUMENTS}")

  execute_process(
    COMMAND ${command_name} ${ARGS_UNPARSED_ARGUMENTS}
    RESULT_VARIABLE RET_VALUE
    WORKING_DIRECTORY ${ARGS_WORKING_DIRECTORY}
    )
  message(STATUS "RET_VALUE=${RET_VALUE}")
  if (NOT RET_VALUE EQUAL 0)
    message(FATAL_ERROR "Bad return value R=${RET_VALUE}")
  endif()
endfunction()

set(CONFIG_VCPKG_INSTALL_PATH "${CONFIG_BUILD_DIR}/vcpkg/vcpkg_installed")

if (WIN32)
  set(DO_WITH_VCPKG_TOOLCHAIN TRUE)
endif()

if (UNIX)
  set(DO_WITH_VCPKG_TOOLCHAIN TRUE)
  set(GENERATOR_ARG "-GNinja")
endif()
if (WIN32)
  # TODO: Il faut recopier les '.dll' utilisées dans le répertoire des libs
  # si on n'utilise pas 'vcpkg'
  # TODO: regarder s'il est intéressant d'utiliser aussi ninja sous windows
endif()

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

if("configure_dependencies" IN_LIST BUILD_COMMANDS)
  do_command(${CMAKE_COMMAND} -S "${GIT_WORKSPACE}/dependencies" -B "${CONFIG_BUILD_DIR}/dependencies" ${GENERATOR_ARG}
  "-DVCPKG_CMAKE_CACHE=${VCPKG_CMAKE_CACHE}"
  -C "${CONFIG_CACHE_DIR}"
  "-DArccon_ROOT=${CONFIG_BUILD_DIR}/install_arccon"
  "-DCMAKE_INSTALL_PREFIX=${CONFIG_BUILD_DIR}/install_dependencies"
  )
endif()
if("build_dependencies" IN_LIST BUILD_COMMANDS)
  do_command(${CMAKE_COMMAND} --build "${CONFIG_BUILD_DIR}/dependencies")
endif()
if("install_dependencies" IN_LIST BUILD_COMMANDS)
  do_command(${CMAKE_COMMAND} --build "${CONFIG_BUILD_DIR}/dependencies" --target install)
endif()

if("configure_axlstar" IN_LIST BUILD_COMMANDS)
  do_command(${CMAKE_COMMAND} -S "${GIT_WORKSPACE}/axlstar" -B "${CONFIG_BUILD_DIR}/axlstar" ${GENERATOR_ARG}
  "-DVCPKG_CMAKE_CACHE=${VCPKG_CMAKE_CACHE}"
  -C "${CONFIG_CACHE_DIR}"
  "-DArcDependencies_ROOT=${CONFIG_BUILD_DIR}/install_dependencies"
  "-DArccon_ROOT=${CONFIG_BUILD_DIR}/install_arccon"
  "-DCMAKE_INSTALL_PREFIX=${CONFIG_BUILD_DIR}/install_axlstar"
  )
endif()

if("build_axlstar" IN_LIST BUILD_COMMANDS)
  do_command(${CMAKE_COMMAND} --build "${CONFIG_BUILD_DIR}/axlstar")
endif()
if("install_axlstar" IN_LIST BUILD_COMMANDS)
  do_command(${CMAKE_COMMAND} --build "${CONFIG_BUILD_DIR}/axlstar" --target install)
endif()

if("configure_arccore" IN_LIST BUILD_COMMANDS)
  set(ARCCORE_CMAKE_COMMON_ARGS -S "${GIT_WORKSPACE}/arccore"  -B "${CONFIG_BUILD_DIR}/arccore" ${GENERATOR_ARG}
    "-DVCPKG_CMAKE_CACHE=${VCPKG_CMAKE_CACHE}"
    "-DCMAKE_INSTALL_PREFIX=${CONFIG_BUILD_DIR}/install_arccore"
    "-DArccon_ROOT=${CONFIG_BUILD_DIR}/install_arccon"
    -DBUILD_SHARED_LIBS=TRUE
    -DCMAKE_BUILD_TYPE=${CONFIG_TYPE}
    -DARCCORE_BUILD_MODE=Check
    )

  if (DO_WITH_VCPKG_TOOLCHAIN)
    # Copie le fichier contenant les dépendances des packages 'vcpkg' nécessaires pour arccore
    file(COPY "${GIT_WORKSPACE}/_build/arccore/vcpkg.json" DESTINATION "${GIT_WORKSPACE}/arccore")
    do_command(${CMAKE_COMMAND} ${ARCCORE_CMAKE_COMMON_ARGS}
      -DCMAKE_TOOLCHAIN_FILE=${GIT_WORKSPACE}/vcpkg/scripts/buildsystems/vcpkg.cmake
      )
  else()
    do_command(${CMAKE_COMMAND} ${ARCCORE_CMAKE_COMMON_ARGS}
      -C "${CONFIG_CACHE_DIR}"
      -DCONFIG_COPY_DLLS=TRUE
      )
  endif()
endif()

if("build_arccore" IN_LIST BUILD_COMMANDS)
  do_command(${CMAKE_COMMAND} --build "${CONFIG_BUILD_DIR}/arccore")
endif()
#do_command(${CMAKE_COMMAND} --build "${CONFIG_BUILD_DIR}/arccore" --target test)
if("test_arccore" IN_LIST BUILD_COMMANDS)
  message(STATUS "CMAKE_CTEST_COMMAND IS: ${CMAKE_CTEST_COMMAND}")
  do_command(${CMAKE_CTEST_COMMAND} WORKING_DIRECTORY "${CONFIG_BUILD_DIR}/arccore")
endif()
if("install_arccore" IN_LIST BUILD_COMMANDS)
  do_command(${CMAKE_COMMAND} --build "${CONFIG_BUILD_DIR}/arccore" --target install)
endif()

# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------

if("configure_arcane" IN_LIST BUILD_COMMANDS)
  set(ARCANE_CMAKE_COMMON_ARGS -S "${GIT_WORKSPACE}/arcane"  -B "${CONFIG_BUILD_DIR}/arcane" ${GENERATOR_ARG}
    "-DVCPKG_CMAKE_CACHE=${VCPKG_CMAKE_CACHE}"
    "-DCMAKE_INSTALL_PREFIX=${CONFIG_BUILD_DIR}/install_arcane"
    "-DArccon_ROOT=${CONFIG_BUILD_DIR}/install_arccon"
    "-DArccore_ROOT=${CONFIG_BUILD_DIR}/install_arccore"
    "-DAxlstar_ROOT=${CONFIG_BUILD_DIR}/install_axlstar"
    "-DArcDependencies_ROOT=${CONFIG_BUILD_DIR}/install_dependencies"
    "-DARCANE_DEFAULT_PARTITIONER=Metis"
    "-DARCCON_REGISTER_PACKAGE_VERSION=2"
    -DARCANE_WANT_ARCCON_EXPORT_TARGET=OFF
    -DBUILD_SHARED_LIBS=TRUE
    -DCMAKE_BUILD_TYPE=${CONFIG_TYPE}
    )

  if (DO_WITH_VCPKG_TOOLCHAIN)
    # Copie le fichier contenant les dépendances des packages 'vcpkg' nécessaires pour arcane
    file(COPY "${GIT_WORKSPACE}/_build/arcane/vcpkg.json" DESTINATION "${GIT_WORKSPACE}/arcane")
    do_command(${CMAKE_COMMAND} ${ARCANE_CMAKE_COMMON_ARGS}
      -DCMAKE_TOOLCHAIN_FILE=${GIT_WORKSPACE}/vcpkg/scripts/buildsystems/vcpkg.cmake
      )
  else()
    do_command(${CMAKE_COMMAND} ${ARCANE_CMAKE_COMMON_ARGS}
      -C "${CONFIG_CACHE_DIR}"
      -DCONFIG_COPY_DLLS=TRUE
      )
  endif()
endif()

if("build_arcane" IN_LIST BUILD_COMMANDS)
  do_command(${CMAKE_COMMAND} --build "${CONFIG_BUILD_DIR}/arcane")
endif()
#do_command(${CMAKE_COMMAND} --build "${CONFIG_BUILD_DIR}/arcane" --target test)
if("test_arcane" IN_LIST BUILD_COMMANDS)
  message(STATUS "CMAKE_CTEST_COMMAND IS: ${CMAKE_CTEST_COMMAND}")
  do_command(${CMAKE_CTEST_COMMAND} WORKING_DIRECTORY "${CONFIG_BUILD_DIR}/arcane" -I 1,40)
endif()

# ----------------------------------------------------------------------------
# Local Variables:
# tab-width: 2
# indent-tabs-mode: nil
# coding: utf-8-with-signature
# End:
