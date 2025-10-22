#pragma once

#include "ds/IStack.hpp"

#include <memory>
#include <stdexcept>
#include <utility>

namespace ds
{

template <typename T>
class StackList : public ds::IStack<T>
{
public:
    void push(const T& v) override
    {
        push_impl(v);
    }

    void push(T&& v) override
    {
        push_impl(std::move(v));
    }

    [[nodiscard]] T pop() override
    {
        if (is_empty())
        {
            throw std::runtime_error("StackList::pop: stack is empty");
        }

        auto temp = std::move(head_);  // keep strong exception safety
        head_ = std::move(temp->next);
        return std::move(temp->data);
    }

    [[nodiscard]] bool is_empty() const noexcept override
    {
        return head_ == nullptr;
    }

private:
    struct Node
    {
        template <class U>
        Node(U&& d, std::unique_ptr<Node> n) : data(std::forward<U>(d)), next(std::move(n))
        {
        }

        T data;
        std::unique_ptr<Node> next;
    };

    template <class U>
    void push_impl(U&& v)
    {
        head_ = std::make_unique<Node>(std::forward<U>(v), std::move(head_));
    }

    std::unique_ptr<Node> head_;
};

}  // namespace ds