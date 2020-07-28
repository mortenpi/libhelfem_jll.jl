cmake_minimum_required(VERSION 3.10)
project(libhelfem-cxxwrap CXX)

set(CMAKE_MACOSX_RPATH 1)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

# Find libcxxwrap
find_package(JlCxx)
get_target_property(JlCxx_location JlCxx::cxxwrap_julia LOCATION)
get_filename_component(JlCxx_location ${JlCxx_location} DIRECTORY)

# Try to find the Armadillo C++ library
find_package(Armadillo REQUIRED)
message("Found Armadillo ${ARMADILLO_VERSION_NAME} (v${ARMADILLO_VERSION_MAJOR}.${ARMADILLO_VERSION_MINOR}.${ARMADILLO_VERSION_PATCH})")
message("ARMADILLO_VERSION_STRING: ${ARMADILLO_VERSION_STRING}")
message("ARMADILLO_INCLUDE_DIRS:   ${ARMADILLO_INCLUDE_DIRS}")
message("ARMADILLO_LIBRARIES:      ${ARMADILLO_LIBRARIES}")
if(NOT (${ARMADILLO_VERSION_MAJOR} EQUAL "9"))
    message(FATAL_ERROR "Invalid Armadillo version, expected 9.")
endif()

# RPATH handling
set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib;${JlCxx_location};${HDF5}/lib;${OPENBLAS}/lib;${GSL}/lib")
set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)

# Include directories
include_directories("${ARMADILLO_INCLUDE_DIRS}")

add_library(helfem-cxxwrap SHARED libhelfem-cxxwrap.cc)
#target_include_directories(helfem-cxxwrap PUBLIC ${ARMADILLO_INCLUDE_DIRS})
target_link_libraries(helfem-cxxwrap PUBLIC "helfem" ${ARMADILLO_LIBRARIES} JlCxx::cxxwrap_julia)

# Installation locations for files.
install(TARGETS helfem-cxxwrap LIBRARY DESTINATION lib)
