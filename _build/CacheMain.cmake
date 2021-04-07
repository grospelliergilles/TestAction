message(STATUS "VCPKG_CMAKE_CACHE = ${VCPKG_CMAKE_CACHE}")
if (NOT VCPKG_CMAKE_CACHE)
  message(ERROR "VCPKG_CMAKE_CACHE is not defined")
endif()
include(${VCPKG_CMAKE_CACHE})

set(VCPKG_PREFIX_TRIPLET "${VCPKG_PREFIX}/${VCPKG_TARGET_TRIPLET}" CACHE STRING "")
set(MPI_HOME "${VCPKG_PREFIX_TRIPLET}/tools/openmpi" CACHE STRING "")
list(APPEND CMAKE_PREFIX_PATH "${VCPKG_PREFIX_TRIPLET}")
# Ce répertoire est nécessaire pour trouver 'gtest_main' de googletest
list(APPEND CMAKE_LIBRARY_PATH "${VCPKG_PREFIX_TRIPLET}/lib/manual-link")
set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" CACHE STRING "CMake prefix path")
set(CMAKE_LIBRARY_PATH "${CMAKE_LIBRARY_PATH}" CACHE STRING "CMake library path")

message(STATUS "PRINT: ${VCPKG_CMAKE_CACHE}")
message(STATUS "PRINT: CMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}")
message(STATUS "PRINT: CMAKE_LIBRARY_PATH=${CMAKE_LIBRARY_PATH}")
message(STATUS "PRINT: VCPKG_PREFIX_TRIPLET=${VCPKG_PREFIX_TRIPLET}")
message(STATUS "PRINT: CONFIG_COPY_DLLS=${CONFIG_COPY_DLLS}")

if(WIN32 AND CONFIG_COPY_DLLS)
  message(STATUS "Win32!")
  message(STATUS "PATH=${CMAKE_BINARY_DIR}")
  file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
  #file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
  #file(COPY "${VCPKG_PREFIX_TRIPLET}/bin" DESTINATION "${CMAKE_BINARY_DIR}/lib" PATTERN "*.dll")
  file(GLOB DLL_LIST "${VCPKG_PREFIX_TRIPLET}/bin/*.dll")
  message(STATUS "DLL_LIST:${DLL_LIST}")
  foreach(F ${DLL_LIST})
    message(STATUS "F=${F}")
    file(COPY "${F}" DESTINATION "${CMAKE_BINARY_DIR}/lib")
  endforeach()
endif()

# ----------------------------------------------------------------------------
# Local Variables:
# tab-width: 2
# indent-tabs-mode: nil
# coding: utf-8-with-signature
# End:
