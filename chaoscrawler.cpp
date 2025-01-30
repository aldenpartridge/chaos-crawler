#include <iostream>
#include <fstream>
#include <sstream>
#include <filesystem>
#include <vector>
#include <thread>
#include <queue>
#include <mutex>
#include <regex>
#include <curl/curl.h>
#include <cstdlib>
#include <zip.h>
#include <nlohmann/json.hpp>

using namespace std;
namespace fs = filesystem;
using json = nlohmann::json;

const string BASE_DIR = string(getenv("HOME")) + "/subdomains";
const string INDEX_URL = "https://chaos-data.projectdiscovery.io/index.json";
const string INDEX_FILE = "/tmp/index.json";

mutex queue_mutex;
queue<string> task_queue;

size_t write_data(void *ptr, size_t size, size_t nmemb, FILE *stream) {
    return fwrite(ptr, size, nmemb, stream);
}

bool download_file(const string &url, const string &output_path) {
    CURL *curl;
    FILE *fp;
    CURLcode res;

    curl = curl_easy_init();
    if (!curl) return false;

    fp = fopen(output_path.c_str(), "wb");
    curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_data);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, fp);
    res = curl_easy_perform(curl);
    curl_easy_cleanup(curl);
    fclose(fp);

    return (res == CURLE_OK);
}

bool validate_url(const string &url) {
    const regex url_regex(R"((https?:\/\/)?(([a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9])\.)+[a-zA-Z]{2,6}(:[0-9]{1,5})?(\/.*)?)");
    return regex_match(url, url_regex);
}

string sanitize_name(const string &name) {
    string sanitized_name = name;
    for (char &c : sanitized_name) {
        if (!isalnum(c) && c != '-' && c != '_') c = '_';
    }
    return sanitized_name;
}

bool unzip_file(const string &zip_path, const string &extract_path) {
    int err = 0;
    zip *archive = zip_open(zip_path.c_str(), ZIP_RDONLY, &err);
    if (!archive) return false;

    for (zip_int64_t i = 0; i < zip_get_num_entries(archive, 0); i++) {
        const char *filename = zip_get_name(archive, i, 0);
        string file_path = extract_path + "/" + filename;

        struct zip_file *zfile = zip_fopen_index(archive, i, 0);
        if (!zfile) continue;

        ofstream out(file_path, ios::binary);
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

void create_directory(const string &path) {
    if (!fs::exists(path)) fs::create_directories(path);
}

void process_program(const string &name, const string &url, const string &platform, bool bounty) {
    string sanitized_name = sanitize_name(name);
    string sanitized_platform = sanitize_name(platform.empty() ? "unknown_platform" : platform);
    string bounty_dir = bounty ? "bounty" : "no_bounty";

    string program_dir = BASE_DIR + "/" + sanitized_platform + "/" + bounty_dir + "/" + sanitized_name;
    create_directory(program_dir);

    string zip_path = program_dir + "/" + sanitized_name + ".zip";

    if (!validate_url(url)) return;

    cout << "Downloading " << name << "..." << endl;
    if (!download_file(url, zip_path)) return;

    cout << "Unzipping " << name << "..." << endl;
    if (!unzip_file(zip_path, program_dir)) return;

    cout << "Processing complete for " << name << endl;
}

void worker_thread() {
    while (true) {
        string task;

        {
            lock_guard<mutex> lock(queue_mutex);
            if (task_queue.empty()) return;
            task = task_queue.front();
            task_queue.pop();
        }

        json program = json::parse(task);
        string name = program["name"];
        string url = program["URL"];
        string platform = program.value("platform", "unknown_platform");
        bool bounty = program.value("bounty", false);

        process_program(name, url, platform, bounty);
    }
}

int main(int argc, char *argv[]) {
    cout << "Downloading index.json..." << endl;

    if (!download_file(INDEX_URL, INDEX_FILE)) return 1;

    ifstream json_file(INDEX_FILE);
    if (!json_file.is_open()) return 1;

    json json_data;
    try {
        json_file >> json_data;
    } catch (const json::parse_error &e) {
        return 1;
    }
    json_file.close();

    for (const auto &program : json_data) {
        if (!program.contains("name") || !program.contains("URL")) continue;
        task_queue.push(program.dump());
    }

    vector<thread> threads;
    size_t num_threads = thread::hardware_concurrency();
    for (size_t i = 0; i < num_threads; i++) threads.emplace_back(worker_thread);

    for (auto &t : threads) t.join();

    fs::remove(INDEX_FILE);
    cout << "All programs downloaded, processed, and index.json removed successfully." << endl;

    return 0;
}
