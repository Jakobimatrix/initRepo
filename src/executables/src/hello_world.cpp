#include <format>
#include <iostream>
#include <library/math.hpp>

int main() {
  std::cout << std::format("Hello, World {}!\n", lib::fibonacci(3));
  return 0;
}