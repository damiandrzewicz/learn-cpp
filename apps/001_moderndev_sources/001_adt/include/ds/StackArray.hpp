#pragma once

#include "IStack.hpp"

#include <array>
#include <cstddef>
#include <stdexcept>
#include <utility>

namespace ds
{

template <typename T, std::size_t Capacity>
class StackArray final : public IStack<T>
{
public:
    static_assert(Capacity > 0, "StackArray capacity must be greater than zero");

    void push(const T& v) override
    {
        push_impl(v);
    }
    void push(T&& v) override
    {
        push_impl(std::move(v));
    }

    [[nodiscard]] virtual T pop() override
    {
        ensure_not_empty();
        --top_index_;
        return std::move(data_[top_index_]);
    }

    [[nodiscard]] virtual bool is_empty() const noexcept override
    {
        return top_index_ == 0;
    }

private:
    template <class U>
    void push_impl(U&& v)
    {
        ensure_space();
        data_[top_index_] = std::forward<U>(v);
        ++top_index_;
    }

    void ensure_space()
    {
        if (top_index_ >= Capacity)
        {
            throw std::runtime_error("StackArray::push: capacity exceeded");
        }
    }

    void ensure_not_empty()
    {
        if (is_empty())
        {
            throw std::runtime_error("StackArray::pop: stack is empty");
        }
    }

    std::array<T, Capacity> data_{};
    std::size_t top_index_{0};
};

}  // namespace ds