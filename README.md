# chaos-crawler

**chaos-crawler** is a shell script that automates the downloading of subdomain data for bug bounty programs from Project Discovery's [Chaos](https://chaos.projectdiscovery.io/) dataset. It organizes the data into a structured directory hierarchy, making it easier for security researchers and bug bounty hunters to access and analyze subdomain information for various programs.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
  - [Basic Usage](#basic-usage)
  - [Custom Base Directory](#custom-base-directory)
  - [Help](#help)
- [Example Directory Structure](#example-directory-structure)
- [Contributing](#contributing)
- [Disclaimer](#disclaimer)
- [Acknowledgments](#acknowledgments)

---

## Features

- **Automated Download**: Fetches the latest `index.json` from the Chaos dataset and downloads subdomain zip files for all listed programs.
- **Organized Directory Structure**: Creates a separate folder for each program under a specified base directory, storing the respective subdomain zip files.
- **Customizable Base Directory**: Allows users to specify their preferred base directory for storing the downloaded data.
- **Dependency Checks**: Verifies the presence of required tools (`curl`, `jq`) before execution and prompts the user if they are missing.
- **User-Friendly**: Provides helpful usage instructions and error messages to guide users through the process.

## Prerequisites

Ensure you have the following tools installed:

- **curl**: Command-line tool for transferring data with URLs.
- **jq**: Command-line JSON processor.

### Installing Dependencies

**For Ubuntu/Debian:**

```bash
sudo apt-get update
sudo apt-get install curl jq
```

**For macOS (using Homebrew):**

```bash
brew install curl jq
```

## Installation

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/aldenpartridge/chaos-crawler.git
   cd chaos-crawler
   ```

2. **Make the Script Executable:**

   ```bash
   chmod +x chaos-crawler.sh
   ```

## Usage

### Basic Usage

Run the script with the default base directory (your home directory):

```bash
./chaos-crawler.sh
```

### Custom Base Directory

Specify a custom base directory using the `-d` or `--directory` option:

```bash
./chaos-crawler.sh -d /path/to/your/directory
```

### Help

Display the help message:

```bash
./chaos-crawler.sh -h
```

**Output:**

```
Usage: chaos-crawler.sh [-d DIRECTORY]

Options:
  -d DIRECTORY   Specify the base directory for downloads (default: /home/youruser)
  -h, --help     Display this help message
```

## Example Directory Structure

After running the script, the directory structure will look like this:

```
/home/youruser/
├── netflix/
│   └── netflix.zip
├── apple/
│   └── apple.zip
└── microsoft/
    └── microsoft.zip
```

Each program's directory contains a zip file with its subdomains.

## Contributing

Contributions are welcome! Please follow these steps:

1. **Fork the Repository**

2. **Create a Feature Branch**

   ```bash
   git checkout -b feature/YourFeature
   ```

3. **Commit Your Changes**

   ```bash
   git commit -am 'Add a new feature'
   ```

4. **Push to the Branch**

   ```bash
   git push origin feature/YourFeature
   ```

5. **Open a Pull Request**

Feel free to open an [issue](https://github.com/aldenpartridge/chaos-crawler/issues) for suggestions or bug reports.

## Disclaimer

This script is provided "as is", without warranty of any kind. Use it at your own risk. The author is not responsible for any damage or legal issues caused by the use of this script.

## Acknowledgments

- [Project Discovery's Chaos Dataset](https://chaos.projectdiscovery.io/) for providing the subdomain data.
