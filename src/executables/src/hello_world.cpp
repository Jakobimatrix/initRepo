/**
 * @file hello_world.cpp
 * @brief Example entrance point for the executable.
 *
 * @date 30.08.2025
 * @author Jakob Wandel
 * @version 1.0
 **/

#include <format>
#include <iostream>
#include <library/math.hpp>

int main() {
  std::cout << std::format("Hello, World {}!\n", lib::fibonacci(3));
  return 0;
}