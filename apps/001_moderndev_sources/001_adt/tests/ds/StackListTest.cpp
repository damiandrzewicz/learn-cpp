#include "ds/StackList.hpp"

#include <gtest/gtest.h>

using ds::StackList;

TEST(StackList, PushPopBasic)
{
    // Arrange
    StackList<int> s;
    EXPECT_TRUE(s.is_empty());

    s.push(1);
    s.push(2);

    EXPECT_FALSE(s.is_empty());
    EXPECT_EQ(2, s.pop());
    EXPECT_EQ(1, s.pop());
    EXPECT_TRUE(s.is_empty());
}

TEST(StackList, EmplaceAndTryPop)
{
    StackList<std::string> s;

    s.emplace(3, 'x');
    auto v = s.try_pop();

    ASSERT_TRUE(v.has_value());
    EXPECT_EQ("xxx", *v);
    EXPECT_FALSE(s.try_pop().has_value());
}

TEST(StackList, UnderflowThrows)
{
    StackList<int> s;
    EXPECT_THROW((void) s.pop(), std::runtime_error);
}

TEST(StackList, PushByReference)
{
    StackList<std::string> s;
    std::string str = "hello";

    s.push(str);
    str = "world";
    s.push(std::move(str));

    EXPECT_EQ("world", s.pop());
    EXPECT_EQ("hello", s.pop());
}
