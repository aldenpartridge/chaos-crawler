# chaos-crawler

**chaos-crawler** is a shell script that automates the downloading of subdomain data for bug bounty programs from Project Discovery's [Chaos](https://chaos.projectdiscovery.io/) dataset. It organizes the data into a structured directory hierarchy based on platform and bounty status, making it easier for security researchers and bug bounty hunters to access and analyze subdomain information.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
  - [Basic Usage](#basic-usage)
  - [Filter Options](#filter-options)
    - [Filter by Bounty Programs](#filter-by-bounty-programs)
    - [Filter by Platform](#filter-by-platform)
    - [Combine Filters](#combine-filters)
  - [Custom Base Directory](#custom-base-directory)
  - [Help](#help)
- [Example Directory Structure](#example-directory-structure)
- [Acknowledgments](#acknowledgments)

---

## Features

- **Automated Download**: Fetches the latest `index.json` from the Chaos dataset and downloads subdomain zip files for all listed programs.
- **Organized Directory Structure**: Creates a structured folder hierarchy under the base directory:
  - Platform (e.g., `hackerone`, `bugcrowd`)
    - `bounty` or `no_bounty` (based on whether the program offers a bounty)
      - Program directory containing the zip file
- **Customizable Base Directory**: Allows users to specify their preferred base directory for storing the downloaded data.
- **Filter Options**: Supports filtering by bounty status and platform.
- **Dependency Checks**: Verifies the presence of required tools (`curl`, `jq`) before execution.
- **User-Friendly**: Provides helpful usage instructions and error messages.

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

Run the script with the default base directory (`$HOME/subdomains`):

```bash
./chaos-crawler.sh
```

### Filter Options

#### Filter by Bounty Programs

Include only programs that offer bounties:

```bash
./chaos-crawler.sh -b
```

#### Filter by Platform

Include only programs from specific platforms:

```bash
./chaos-crawler.sh -p hackerone,bugcrowd
```

#### Combine Filters

Include only bounty programs from specific platforms:

```bash
./chaos-crawler.sh -b -p hackerone,bugcrowd
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
Usage: chaos-crawler.sh [options]

Options:
  -d DIRECTORY            Specify the base directory for downloads (default: /home/youruser/subdomains)
  -b, --bounty            Include only programs that offer bounties
  -p, --platform PLATFORMS Specify comma-separated platforms to include (e.g., hackerone,bugcrowd)
  -h, --help              Display this help message
```

## Example Directory Structure

After running the script, the directory structure will look like this:

```
/home/youruser/subdomains/
├── hackerone/
│   ├── bounty/
│   │   ├── program1/
│   │   │   └── program1.zip
│   │   └── program2/
│   │       └── program2.zip
│   └── no_bounty/
│       └── program3/
│           └── program3.zip
├── bugcrowd/
│   ├── bounty/
│   │   └── program4/
│   │       └── program4.zip
│   └── no_bounty/
│       └── program5/
│           └── program5.zip
└── unknown_platform/
    └── no_bounty/
        └── program6/
            └── program6.zip
```

- **Platform Directories**: Programs are organized under their respective platforms.
- **Bounty Status**: Each platform directory contains `bounty` and `no_bounty` subdirectories.
- **Program Directories**: Each program has its own directory containing the zip file.
## Acknowledgments

- [Project Discovery's Chaos Dataset](https://chaos.projectdiscovery.io/) for providing the subdomain data.
