cmake_policy(VERSION 3.16)

if(NOT EXISTS "/home/me/Repository/system/nixos/configs/workshop/plasma-dock/build/install_manifest.txt")
    message(FATAL_ERROR "Cannot find install manifest: /home/me/Repository/system/nixos/configs/workshop/plasma-dock/build/install_manifest.txt")
endif()

file(READ "/home/me/Repository/system/nixos/configs/workshop/plasma-dock/build/install_manifest.txt" files)
string(REGEX REPLACE "\n" ";" files "${files}")
foreach(file ${files})
    message(STATUS "Uninstalling $ENV{DESTDIR}${file}")
    if(IS_SYMLINK "$ENV{DESTDIR}${file}" OR EXISTS "$ENV{DESTDIR}${file}")
        execute_process(
            COMMAND "/nix/store/w9jm660dykns6hzrdhxmqfywnc9ail8g-cmake-4.1.2/bin/cmake" -E remove "$ENV{DESTDIR}${file}"
            RESULT_VARIABLE rm_retval
            )
        if(NOT "${rm_retval}" STREQUAL 0)
            message(FATAL_ERROR "Problem when removing $ENV{DESTDIR}${file}")
        endif()
    else()
        message(STATUS "File $ENV{DESTDIR}${file} does not exist.")
    endif()
endforeach()
