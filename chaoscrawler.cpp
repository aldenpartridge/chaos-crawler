#include <iostream>
#include <fstream>
#include <sstream>
#include <filesystem>
#include <vector>
#include <thread>
#include <regex>
#include <curl/curl.h>
#include <cstdlib>
#include <zip.h>
#include <nlohmann/json.hpp>

namespace fs = std::filesystem;
using json = nlohmann::json;

const std::string BASE_DIR = std::string(getenv("HOME")) + "/subdomains";
const std::string INDEX_URL = "https://chaos-data.projectdiscovery.io/index.json";
const std::string INDEX_FILE = "/tmp/index.json";

size_t write_data(void *ptr, size_t size, size_t nmemb, FILE *stream) {
    return fwrite(ptr, size, nmemb, stream);
}

bool download_file(const std::string &url, const std::string &output_path) {
    CURL *curl;
    FILE *fp;
    CURLcode res;
    
    curl = curl_easy_init();
    if (!curl) {
        std::cerr << "Failed to initialize CURL" << std::endl;
        return false;
    }

    fp = fopen(output_path.c_str(), "wb");
    curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_data);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, fp);
    res = curl_easy_perform(curl);
    curl_easy_cleanup(curl);
    fclose(fp);

    return (res == CURLE_OK);
}

bool validate_url(const std::string &url) {
    const std::regex url_regex(R"((https?:\/\/)?(([a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9])\.)+[a-zA-Z]{2,6}(:[0-9]{1,5})?(\/.*)?)");
    return std::regex_match(url, url_regex);
}

bool unzip_file(const std::string &zip_path, const std::string &extract_path) {
    int err = 0;
    zip *archive = zip_open(zip_path.c_str(), ZIP_RDONLY, &err);
    if (!archive) {
        std::cerr << "Failed to open ZIP file: " << zip_path << std::endl;
        return false;
    }

    for (zip_int64_t i = 0; i < zip_get_num_entries(archive, 0); i++) {
        const char *filename = zip_get_name(archive, i, 0);
        std::string file_path = extract_path + "/" + filename;
        
        struct zip_file *zfile = zip_fopen_index(archive, i, 0);
        if (!zfile) {
            std::cerr << "Failed to open file in ZIP: " << filename << std::endl;
            continue;
        }

        std::ofstream out(file_path, std::ios::binary);
        char buffer[4096];
        zip_int64_t bytes_read;
        while ((bytes_read = zip_fread(zfile, buffer, sizeof(buffer))) > 0) {
            out.write(buffer, bytes_read);
        }
        out.close();
        zip_fclose(zfile);
    }

    zip_close(archive);
    return true;
}

void create_directory(const std::string &path) {
    if (!fs::exists(path)) {
        fs::create_directories(path);
    }
}

void process_program(const std::string &name, const std::string &url, const std::string &platform, bool bounty) {
    std::string sanitized_name = name;
    std::string sanitized_platform = platform.empty() ? "unknown_platform" : platform;
    std::string bounty_dir = bounty ? "bounty" : "no_bounty";
    
    std::string program_dir = BASE_DIR + "/" + sanitized_platform + "/" + bounty_dir + "/" + sanitized_name;
    create_directory(program_dir);
    
    std::string zip_path = program_dir + "/" + sanitized_name + ".zip";

    if (!validate_url(url)) {
        std::cerr << "Invalid URL for " << name << ": " << url << std::endl;
        return;
    }

    std::cout << "Downloading " << name << "..." << std::endl;
    if (!download_file(url, zip_path)) {
        std::cerr << "Failed to download " << name << std::endl;
        return;
    }

    std::cout << "Unzipping " << name << "..." << std::endl;
    if (!unzip_file(zip_path, program_dir)) {
        std::cerr << "Failed to unzip " << zip_path << std::endl;
        return;
    }

    std::cout << "Processing complete for " << name << std::endl;
}

int main(int argc, char *argv[]) {
    std::cout << "Downloading index.json..." << std::endl;

    if (!download_file(INDEX_URL, INDEX_FILE)) {
        std::cerr << "Failed to download index.json" << std::endl;
        return 1;
    }

    std::ifstream json_file(INDEX_FILE);
    if (!json_file.is_open()) {
        std::cerr << "Error: Could not open index.json" << std::endl;
        return 1;
    }

    json json_data;
    try {
        json_file >> json_data;
    } catch (const json::parse_error &e) {
        std::cerr << "JSON Parsing Error: " << e.what() << std::endl;
        return 1;
    }
    json_file.close();

    std::vector<std::thread> threads;

    for (const auto &program : json_data) {
        if (!program.contains("name") || !program.contains("URL")) {
            continue;
        }

        std::string name = program["name"].get<std::string>();
        std::string url = program["URL"].get<std::string>();
        std::string platform = program.value("platform", "unknown_platform");
        bool bounty = program.value("bounty", false);

        threads.emplace_back(process_program, name, url, platform, bounty);

        if (threads.size() >= std::thread::hardware_concurrency()) {
            for (auto &t : threads) t.join();
            threads.clear();
        }
    }

    for (auto &t : threads) {
        t.join();
    }

    fs::remove(INDEX_FILE);
    std::cout << "All programs downloaded, processed, and index.json removed successfully." << std::endl;

    return 0;
}
