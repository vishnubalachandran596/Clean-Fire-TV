cmake_minimum_required(VERSION 3.19)
# Apmf deferred checks require CMP0099 (link directories as INTERFACE).
if(POLICY CMP0099)
  cmake_policy(SET CMP0099 NEW)
endif()

project(CleanHomeShell
  VERSION 1.0
  LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_link_options("LINKER:--no-undefined" "LINKER:-z,defs")
endif()

set(HEADERS
  kepler/turbo-modules/generated/CleanHomeShellSpec.h
  kepler/turbo-modules/CleanHomeShell.h
)

set(SOURCES
  kepler/turbo-modules/generated/CleanHomeShellSpec.cpp
  kepler/turbo-modules/CleanHomeShell.cpp
  kepler/AutoLinkInit.cpp
)

find_package(turbomoduleAPI CONFIG REQUIRED)
find_package(Apmf REQUIRED)
find_package(Kepler REQUIRED)

kepler_add_turbo_module_library(CleanHomeShell SHARED ${HEADERS} ${SOURCES})

kepler_add_idl_import_library(
  cleanhome_tasks_idl
  PACKAGES
  com.amazon.kepler.tasks
)

target_link_libraries(CleanHomeShell PRIVATE cleanhome_tasks_idl)

install(TARGETS CleanHomeShell)
