#pragma once

#include "IStack.hpp"

#include <array>
#include <stdexcept>

namespace ds
{

template <typename T, std::size_t Capacity>
class StackArray final : public IStack<T>
{
public:
    static_assert(Capacity > 0, "StackArray capacity must be greater than zero");

    virtual void push(const T& v) override
    {
        ensure_space();
        data_[top_index_] = v;
        ++top_index_;
    }

    virtual void push(T&& v) override
    {
        ensure_space();
        data_[top_index_] = std::move(v);
        ++top_index_;
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