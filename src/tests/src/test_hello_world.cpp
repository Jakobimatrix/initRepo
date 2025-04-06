#include <catch2/catch_test_macros.hpp>

#include <library/math.hpp>

#include <cstdio>
#include <sstream>

// https://github.com/catchorg/Catch2/blob/devel/docs/Readme.md

TEST_CASE("Basic test case") {
  REQUIRE(1 + 1 == 2);  // Simple assertion
}

TEST_CASE("String output with printf") {
  std::ostringstream output;
  printf("Hello, %s!\n", "Catch2");
  REQUIRE(output.str() == "Hello, Catch2!\n");
}

TEST_CASE("Section example") {
  SECTION("First section") {
    REQUIRE(1 == 1);
  }
  SECTION("Second section") {
    REQUIRE(2 == 2);
  }
}


TEST_CASE("Fibonacci") {
  CHECK(Fibonacci(0) == 1);
  CHECK(Fibonacci(5) == 8);

  BENCHMARK("Fibonacci 20") {
    return Fibonacci(20);
  };

  BENCHMARK("Fibonacci 35") {
    return Fibonacci(35);
  };

  BENCHMARK_ADVANCED("advanced")(Catch::Benchmark::Chronometer meter) {
    std::vector<std::uint64_t> data{1,2,3,4};
    meter.measure([] { for(const std::uint64_t d : data){Fibonacci(d)}; });
  };
}
