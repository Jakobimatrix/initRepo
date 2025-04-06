#include <library/math.hpp>

namespace lib{
constexpr std::uint64_t fibonacci(std::uint64_t number) {
  return number < 2 ? 1 : fibonacci(number - 1) + fibonacci(number - 2);
}
}
