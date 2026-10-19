cmake_minimum_required(VERSION 3.20)
project(ChatGPTminer VERSION 0.2.0 LANGUAGES CXX)

find_package(Threads REQUIRED)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_library(pearl_core
    src/config.cpp
    src/gpu_manager.cpp
    src/devfee.cpp
    src/stratum_client.cpp)
target_include_directories(pearl_core PUBLIC include)
target_link_libraries(pearl_core PUBLIC ${CMAKE_DL_LIBS} Threads::Threads)
target_compile_options(pearl_core PRIVATE -Wall -Wextra -Wpedantic)

add_executable(chatgptminer src/main.cpp)
target_link_libraries(chatgptminer PRIVATE pearl_core)

include(CTest)
if(BUILD_TESTING)
  add_executable(pearl_tests tests/core_tests.cpp)
  target_link_libraries(pearl_tests PRIVATE pearl_core)
  add_test(NAME core_tests COMMAND pearl_tests)
endif()

install(TARGETS chatgptminer RUNTIME DESTINATION bin)

