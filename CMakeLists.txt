cmake_minimum_required(VERSION 3.11)

project(example CXX)

message(STATUS "Searching for MPI library")
find_package(MPI REQUIRED COMPONENTS CXX)
add_executable(example vcpkg_manifest/main.cpp)
enable_testing()
target_link_libraries(example PRIVATE MPI::MPI_CXX)
add_test(NAME t1 COMMAND ${MPIEXEC_EXECUTABLE} -n 4 ${CMAKE_CURRENT_BINARY_DIR}/example)
