cmake_minimum_required(VERSION 3.22.1)

project("uinput_keyboard")

add_library(uinput_keyboard SHARED
    uinput_keyboard.cpp
)

find_library(log-lib log)

target_link_libraries(uinput_keyboard
    ${log-lib}
)
