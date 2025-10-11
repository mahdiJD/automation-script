#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <iomanip>

std::string human_readable(unsigned long long bytes) {
    const char* units[] = {"B", "KB", "MB", "GB", "TB"};
    int i = 0;
    double val = (double)bytes;
    while (val >= 1024.0 && i < 4) {
        val /= 1024.0;
        ++i;
    }
    std::ostringstream oss;
    oss << std::fixed << std::setprecision(2) << val << " " << units[i];
    return oss.str();
}

int main() {
    std::ifstream meminfo("/proc/meminfo");
    if (!meminfo) {
        std::cerr << "Cannot open /proc/meminfo\n";
        return 1;
    }

    unsigned long long memTotalKB = 0, memAvailableKB = 0;
    std::string line;
    while (std::getline(meminfo, line)) {
        if (line.rfind("MemTotal:", 0) == 0) {
            std::istringstream iss(line);
            std::string key, unit;
            iss >> key >> memTotalKB >> unit;
        } else if (line.rfind("MemAvailable:", 0) == 0) {
            std::istringstream iss(line);
            std::string key, unit;
            iss >> key >> memAvailableKB >> unit;
        }
        if (memTotalKB && memAvailableKB) break;
    }

    unsigned long long totalBytes = memTotalKB * 1024ULL;
    unsigned long long availBytes = memAvailableKB * 1024ULL;
    unsigned long long usedBytes = totalBytes - availBytes;

    std::cout << "total RAM: " << human_readable(totalBytes) << '\n';
    std::cout << ": " << human_readable(availBytes) << '\n';
    std::cout << "in used: " << human_readable(usedBytes) << '\n';

    return 0;
}
