#include <iostream>
#include <ctime>

int main() {
    std::cout << "Hello, World!" << std::endl;

    // Print current date and time
    std::time_t now = std::time(nullptr);
    std::cout << "Current date and time: " << std::ctime(&now);

    // Print a simple calculation
    int a = 5, b = 3;
    std::cout << "Sum of " << a << " and " << b << " is " << (a + b) << std::endl;

    // Print a motivational message
    std::cout << "Keep learning C++!" << std::endl;

    return 0;
}