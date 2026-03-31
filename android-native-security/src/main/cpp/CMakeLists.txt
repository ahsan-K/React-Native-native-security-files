cmake_minimum_required(VERSION 3.4.1)

set(CMAKE_ANDROID_STL_TYPE c++_static)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-z,max-page-size=16384")

# SSL pinning native library
add_library(
        sslpinning
        SHARED
        ssl_pinning.cpp
        anti_frida.cpp
)

find_library(
        log-lib
        log
)

target_link_libraries(
        sslpinning
        ${log-lib}
)
