#pragma once

#include <optional>

// Data Structures namespace
namespace ds
{

template <typename T>
struct IStack
{
    virtual ~IStack() = default;

    /**
     * @brief Pushes a value onto the stack.
     */
    virtual void push(const T& v) = 0;

    /**
     * @brief Pops the top value off the stack and returns it.
     * @throws std::runtime_error if the stack is empty.
     */
    virtual void push(T&& v) = 0;

    /**
     * @brief Pops the top value off the stack and returns it.
     * @throws std::runtime_error if the stack is empty.
     */
    [[nodiscard]] virtual T pop() = 0;

    /**
     * @brief Checks if the stack is empty.
     * @return true if the stack is empty, false otherwise.
     */
    [[nodiscard]] virtual bool is_empty() const noexcept = 0;

    /**
     * @brief Constructs and pushes a value onto the stack.
     */
    template <typename... Args>
    void emplace(Args&&... args)
        requires std::constructible_from<T, Args...>
    {
        push(T(std::forward<Args>(args)...));
    }

    /**
     * @brief Checks if the stack is empty.
     * @return true if the stack is empty, false otherwise.
     */
    [[nodiscard]] bool empty() const noexcept
    {
        return is_empty();
    }

    /**
     * @brief Tries to pop the top value off the stack.
     * @return std::optional containing the popped value, or std::nullopt if the
     * stack is empty.
     */
    [[nodiscard]] std::optional<T> try_pop()
    {
        if (is_empty())
        {
            return std::nullopt;
        }
        return pop();
    }
};

}  // namespace ds
