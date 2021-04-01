#set(TEST_DIR "/tmp/my_work_dir")
set(CONFIG_TYPE Debug)
#file(MAKE_DIRECTORY ${TEST_DIR})

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

message(STATUS "Configure and build arccon")
do_command(${CMAKE_COMMAND} -S "${GIT_WORKSPACE}/arccon" -B "${CONFIG_BUILD_DIR}/arccon" -GNinja
  "-DVCPKG_CMAKE_CACHE=${CONFIG_BUILD_DIR}/vcpkg/my.vcpkg.config.cmake"
  -C "${GIT_WORKSPACE}/vcpkg_manifest/CacheMain.txt"
  "-DCMAKE_INSTALL_PREFIX=${CONFIG_BUILD_DIR}/install_arccon"
  )
do_command(${CMAKE_COMMAND} --build "${CONFIG_BUILD_DIR}/arccon")
do_command(${CMAKE_COMMAND} --build "${CONFIG_BUILD_DIR}/arccon" --target install)

message(STATUS "Configure and build arccore")
do_command(${CMAKE_COMMAND} -S "${GIT_WORKSPACE}/arccore" -B "${CONFIG_BUILD_DIR}/arccore" -GNinja
  "-DVCPKG_CMAKE_CACHE=${CONFIG_BUILD_DIR}/vcpkg/my.vcpkg.config.cmake"
  -C "${GIT_WORKSPACE}/vcpkg_manifest/CacheMain.txt"
  "-DCMAKE_INSTALL_PREFIX=${CONFIG_BUILD_DIR}/install_arccore"
  "-DArccon_ROOT=${CONFIG_BUILD_DIR}/install_arccon"
  -DBUILD_SHARED_LIBS=TRUE
  )
do_command(${CMAKE_COMMAND} --build "${CONFIG_BUILD_DIR}/arccore")
