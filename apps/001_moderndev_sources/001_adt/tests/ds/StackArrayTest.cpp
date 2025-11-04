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
    EXPECT_EQ(2, s.pop());
    EXPECT_EQ(1, s.pop());
    EXPECT_TRUE(s.is_empty());
}

TEST(StackArray, EmplaceAndTryPop)
{
    StackArray<std::string, 3> s;

    s.emplace(3, 'x');
    auto v = s.try_pop();

    ASSERT_TRUE(v.has_value());
    EXPECT_EQ("xxx", *v);
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

TEST(StackArray, PushByReference)
{
    StackArray<std::string, 2> s;
    std::string str = "hello";

    s.push(str);
    str = "world";
    s.push(std::move(str));

    EXPECT_EQ("world", s.pop());
    EXPECT_EQ("hello", s.pop());
}

// Covers capacity=1 successful push/pop path (previously only underflow was tested)
TEST(StackArray, CapacityOneHappyPath)
{
    StackArray<int, 1> s;
    EXPECT_TRUE(s.is_empty());

    int x = 42;
    s.push(x);  // cover const& overload for int, Capacity=1

    EXPECT_FALSE(s.is_empty());
    EXPECT_EQ(42, s.pop());  // cover pop success for Capacity=1 instantiation
    EXPECT_TRUE(s.is_empty());
}

// Ensure const& overload is exercised for int with capacity > 1
TEST(StackArray, IntLvaluePush)
{
    StackArray<int, 4> s;

    int a = 7;
    int b = 9;
    s.push(a);  // const& overload
    s.push(b);  // const& overload

    EXPECT_EQ(9, s.pop());
    EXPECT_EQ(7, s.pop());
}

// Exercise IStack<int>::try_pop both branches (value and nullopt)
TEST(StackArray, TryPopIntBothPaths)
{
    StackArray<int, 2> s;
    EXPECT_FALSE(s.try_pop().has_value());  // empty branch

    s.emplace(123);        // uses push(T&&)
    auto v = s.try_pop();  // value branch
    ASSERT_TRUE(v.has_value());
    EXPECT_EQ(123, *v);

    EXPECT_FALSE(s.try_pop().has_value());  // empty again
}
