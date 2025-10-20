#include "ds/StackArray.hpp"

#include <gtest/gtest.h>

using ds::StackArray;

TEST(StackArray, PushPopBasic)
{
    // Arrange
    StackArray<int, 4> s;
    EXPECT_TRUE(s.is_empty());

    s.push(1);
    s.push(2);

    EXPECT_FALSE(s.is_empty());
    EXPECT_EQ(s.pop(), 2);
    EXPECT_EQ(s.pop(), 1);
    EXPECT_TRUE(s.is_empty());
}

TEST(StackArray, EmplaceAndTryPop)
{
    StackArray<std::string, 3> s;
    s.emplace(3, 'x');  // "xxx"
    auto v = s.try_pop();
    ASSERT_TRUE(v.has_value());
    EXPECT_EQ(*v, "xxx");
    EXPECT_FALSE(s.try_pop().has_value());
}

TEST(StackArray, OverflowThrows)
{
    StackArray<int, 2> s;
    s.push(10);
    s.push(20);
    EXPECT_THROW(s.push(30), std::runtime_error);
}

TEST(StackArray, UnderflowThrows)
{
    StackArray<int, 1> s;
    EXPECT_THROW((void) s.pop(), std::runtime_error);
}
