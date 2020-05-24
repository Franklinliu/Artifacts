include(ExternalProject)

if (${CMAKE_SYSTEM_NAME} STREQUAL "Emscripten")
    set(JSONCPP_CMAKE_COMMAND emcmake cmake)
else()
    set(JSONCPP_CMAKE_COMMAND ${CMAKE_COMMAND})
endif()

set(prefix "${CMAKE_BINARY_DIR}/deps")
set(JSONCPP_LIBRARY "${prefix}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}jsoncpp${CMAKE_STATIC_LIBRARY_SUFFIX}")
set(JSONCPP_INCLUDE_DIR "${prefix}/include")

# TODO: Investigate why this breaks some emscripten builds and
# check whether this can be removed after updating the emscripten
# versions used in the CI runs.
if(EMSCRIPTEN)
    # Do not include all flags in CMAKE_CXX_FLAGS for emscripten,
    # but only use -std=c++14. Using all flags causes build failures
    # at the moment.
    set(JSONCPP_CXX_FLAGS -std=c++14)
else()
    set(JSONCPP_CXX_FLAGS ${CMAKE_CXX_FLAGS})
endif()

set(byproducts "")
if(CMAKE_VERSION VERSION_GREATER 3.1)
    set(byproducts BUILD_BYPRODUCTS "${JSONCPP_LIBRARY}")
endif()

ExternalProject_Add(jsoncpp-project
    PREFIX "${prefix}"
    DOWNLOAD_DIR "${CMAKE_SOURCE_DIR}/deps/downloads"
    DOWNLOAD_NAME jsoncpp-1.8.4.tar.gz
    URL https://github.com/open-source-parsers/jsoncpp/archive/1.8.4.tar.gz
    URL_HASH SHA256=c49deac9e0933bcb7044f08516861a2d560988540b23de2ac1ad443b219afdb6
    CMAKE_COMMAND ${JSONCPP_CMAKE_COMMAND}
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
               -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
               -DCMAKE_INSTALL_LIBDIR=lib
               # Build static lib but suitable to be included in a shared lib.
               -DCMAKE_POSITION_INDEPENDENT_CODE=${BUILD_SHARED_LIBS}
               -DJSONCPP_WITH_TESTS=OFF
               -DJSONCPP_WITH_PKGCONFIG_SUPPORT=OFF
               -DCMAKE_CXX_FLAGS=${JSONCPP_CXX_FLAGS}
               -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    ${byproducts}
)

# Create jsoncpp imported library
add_library(jsoncpp STATIC IMPORTED)
file(MAKE_DIRECTORY ${JSONCPP_INCLUDE_DIR})  # Must exist.
set_property(TARGET jsoncpp PROPERTY IMPORTED_LOCATION ${JSONCPP_LIBRARY})
set_property(TARGET jsoncpp PROPERTY INTERFACE_SYSTEM_INCLUDE_DIRECTORIES ${JSONCPP_INCLUDE_DIR})
set_property(TARGET jsoncpp PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${JSONCPP_INCLUDE_DIR})
add_dependencies(jsoncpp jsoncpp-project)
