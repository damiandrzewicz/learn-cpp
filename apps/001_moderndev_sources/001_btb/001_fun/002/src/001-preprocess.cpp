#include <iostream>
#define SQUARE(x) ((x) * (x))

int main()
{
#ifdef DEBUG
    std::cout << "Debug mode!" << std::endl;
#endif
    std::cout << SQUARE(3) << "\n";
}