cmake_minimum_required(VERSION 3.10)
project(lab1_task1 C)
 
set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)
 
# Обычная C-версия
add_executable(lab1_task1 lab1_task1.c)
 
# Упрощённая C-версия (приближенная к ассемблеру)
add_executable(lab1_task1_simplified lab1_task1_simplified.c)