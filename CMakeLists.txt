cmake_minimum_required(VERSION 3.15)

project(raylib-android LANGUAGES CXX)

set(CMAKE_MSVC_RUNTIME_LIBRARY "$<$<NOT:$<CONFIG:Debug>>:MultiThreaded>")

add_executable(raylib-android)

set_property(TARGET raylib-android PROPERTY CXX_STANDARD 20)

include(FetchContent)
set(FETCHCONTENT_QUIET OFF)
FetchContent_Declare(raylib URL "https://github.com/raysan5/raylib/archive/refs/tags/5.0.tar.gz")
FetchContent_MakeAvailable(raylib)

file(GLOB_RECURSE raylib-android_src "src/*.cpp")
target_sources(raylib-android PRIVATE
  "${raylib-android_src}")

target_include_directories(raylib-android PRIVATE
  "include")

target_link_libraries(raylib-android PRIVATE raylib)
if (APPLE)
  target_link_libraries(raylib-android PRIVATE "-framework IOKit")
  target_link_libraries(raylib-android PRIVATE "-framework Cocoa")
  target_link_libraries(raylib-android PRIVATE "-framework OpenGL")
endif()

target_compile_options(raylib-android PRIVATE "-Wall")
if(MSVC)
  target_link_options(raylib-android PRIVATE "$<$<NOT:$<CONFIG:Debug>>:LINKER:/SUBSYSTEM:WINDOWS,/ENTRY:mainCRTStartup>")
endif()