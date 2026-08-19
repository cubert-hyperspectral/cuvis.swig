list(APPEND CMAKE_MODULE_PATH
  "${CMAKE_CURRENT_LIST_DIR}/cuvis.c")

find_package(Cuvis 3.4...<3.6 REQUIRED)

set(SWIG_FILES 
	${CMAKE_CURRENT_LIST_DIR}/src/cuvis_il.i)
	

CMAKE_POLICY(SET CMP0086 NEW)
CMAKE_POLICY(SET CMP0078 NEW)
CMAKE_POLICY(SET CMP0122 NEW)

FIND_PACKAGE(SWIG REQUIRED)
INCLUDE(${SWIG_USE_FILE})

set (UseSWIG_TARGET_NAME_PREFERENCE STANDARD)
SET_SOURCE_FILES_PROPERTIES(${SWIG_FILES} PROPERTIES CPLUSPLUS ON)

file(MAKE_DIRECTORY ${SWIG_OUTPUT_DIR})

SWIG_ADD_LIBRARY(${target_name} TYPE SHARED LANGUAGE ${SWIG_LANGUAGE} SOURCES ${SWIG_FILES} OUTPUT_DIR ${SWIG_OUTPUT_DIR}  OUTFILE_DIR ${CMAKE_CURRENT_BINARY_DIR}/generated)

set_PROPERTY(TARGET ${target_name} PROPERTY UseSWIG_MODULE_VERSION 1)

SET_PROPERTY(SOURCE ${target_name} PROPERTY SWIG_MODULE_NAME ${target_name})

SET_PROPERTY(TARGET ${target_name} PROPERTY SWIG_INCLUDE_DIRECTORIES ${Cuvis_INCLUDE_DIR})

target_link_libraries(${target_name} PRIVATE cuvis::c) 

# What the binding was built against, reported at import time so a mismatch with the
# deployed library is visible rather than silent. The version alone does not identify a
# build, hence the hash. Defined here rather than per binding, because the interface file
# that consumes it is shared by every target language.
target_compile_definitions(${target_name} PRIVATE
  CUVIS_BINDING_BUILT_VERSION="${Cuvis_VERSION}"
  CUVIS_BINDING_BUILT_HASH="${Cuvis_BUILD_HASH}")

target_include_directories(${target_name} INTERFACE
    ${INTERFACE_OUTPUT_DIR}
)


