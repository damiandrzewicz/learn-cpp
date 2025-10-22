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
    EXPECT_EQ(s.pop(), 2);
    EXPECT_EQ(s.pop(), 1);
    EXPECT_TRUE(s.is_empty());
}

TEST(StackList, EmplaceAndTryPop)
{
    StackList<std::string> s;

    s.emplace(3, 'x');  // "xxx"
    auto v = s.try_pop();

    ASSERT_TRUE(v.has_value());
    EXPECT_EQ(*v, "xxx");
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

    EXPECT_EQ(s.pop(), "world");
    EXPECT_EQ(s.pop(), "hello");
}
