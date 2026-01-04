/**
 * @file test_hello_world.cpp
 * @brief contains an example unit test suit using catch2 for the library 'library'
 *
 * @date 30.08.2025
 * @author Jakob Wandel
 * @version 1.0
 **/

#include <catch2/benchmark/catch_benchmark.hpp>
#include <catch2/benchmark/catch_chronometer.hpp>
#include <catch2/catch_test_macros.hpp>
#include <cstdio>
#include <library/math.hpp>

#include <vector>

// https://github.com/catchorg/Catch2/blob/devel/docs/Readme.md

TEST_CASE("Basic test case") {
  REQUIRE(1 + 1 == 2);  // Simple assertion
}

TEST_CASE("Section example") {
  SECTION("First section")  // NOLINT misc-const-correctness
  {
    REQUIRE(1 == 1);
  }
  SECTION("Second section")  // NOLINT misc-const-correctness
  {
    REQUIRE(2 == 2);
  }
}


TEST_CASE("Fibonacci") {
  CHECK(lib::fibonacci(0) == 1);
  CHECK(lib::fibonacci(5) == 8);

  constexpr int TWENTY      = 20;
  constexpr int THIRTY_FIVE = 35;

  BENCHMARK("Fibonacci 20") { return lib::fibonacci(TWENTY); };

  BENCHMARK("Fibonacci 35") { return lib::fibonacci(THIRTY_FIVE); };

  BENCHMARK_ADVANCED("Run with pre initialized data")
  (Catch::Benchmark::Chronometer meter) {
    std::vector<int> test_data{1, 2, 3, 4};
    meter.measure([&test_data] {
      for (const int data : test_data) {
        constexpr int result = lib::fibonacci(data);
        Catch::Benchmark::DoNotOptimize(result);
      }
    });
  };
}
