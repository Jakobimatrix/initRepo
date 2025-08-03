/**
 * @file math.hpp
 * @brief contains math functions
 *
 * @date 30.03.2025
 * @author Jakob Wandel
 * @version 1.0
 **/

#pragma once

namespace lib {
/**
 * @brief Computes the nth Fibonacci number.
 *
 * @param number The position in the Fibonacci sequence to compute.
 * @return The nth Fibonacci number.
 *
 * @note This implementation uses recursion and has exponential time complexity.
 */
constexpr int fibonacci(int number) {
  return number < 2 ? 1 : fibonacci(number - 1) + fibonacci(number - 2);
}
}  // namespace lib
