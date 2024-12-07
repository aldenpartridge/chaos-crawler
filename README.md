# chaos-crawler

**chaos-crawler** is a powerful Bash script designed to automate the downloading, organizing, and processing of subdomain data for bug bounty programs from Project Discovery's [Chaos](https://chaos.projectdiscovery.io/) dataset. It streamlines the workflow for security researchers and bug bounty hunters by structuring data based on bug bounty platforms and bounty availability, unzipping relevant files, and processing text data for further analysis.

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

- **Automated Download:** Fetches subdomain data in `.zip` format from the Chaos dataset.
- **Organized Directory Structure:** Structures data by:
  - **Platform:** e.g., `hackerone`, `bugcrowd`, or `unknown_platform`.
  - **Bounty Status:** `bounty` or `no_bounty` based on whether the program offers a bounty.
  - **Program Directory:** Contains the program's zip file, unzipped contents, concatenated text files, and processed output.
- **Unzipping:** Automatically extracts downloaded zip files into their respective program directories.
- **Concatenation:** Combines all `.txt` files within a program directory into a single `placeholder.txt`.
- **Processing:** Processes `placeholder.txt` using the `chars` command (fallback to `wc -m` if `chars` is unavailable) and saves the output as a file named after the bug bounty program.
- **URL Validation:** Ensures that only well-formed URLs are processed and downloaded.
- **Customizable Base Directory:** Allows users to specify their preferred location for storing the data.
- **Filter Options:** Supports filtering by bounty status and bug bounty platform.
- **Dependency Checks:** Verifies the presence of required tools (`curl`, `jq`, `unzip`) before execution.
- **User-Friendly:** Provides clear output messages, error handling, and notifications upon completion.

---

## Prerequisites

Ensure you have the following tools installed on your system:

- **curl:** Command-line tool for transferring data with URLs.
- **jq:** Command-line JSON processor.
- **unzip:** Utility for unpacking `.zip` files.

### Installing Dependencies

**For Ubuntu/Debian:**

```bash
sudo apt-get update
sudo apt-get install curl jq unzip
```

**For macOS (using Homebrew):**

```bash
brew install curl jq unzip
```

---

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

---

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
  -d DIRECTORY              Specify the base directory for downloads (default: /home/youruser/subdomains)
  -b, --bounty              Include only programs that offer bounties
  -p, --platform PLATFORMS   Specify comma-separated platforms to include (e.g., hackerone,bugcrowd)
  -h, --help                Display this help message
```

---

## Example Directory Structure

After running the script, the directory structure will look like this:

```
/home/youruser/subdomains/
├── hackerone/
│   ├── bounty/
│   │   ├── program1/
│   │   │   ├── program1.zip
│   │   │   ├── extracted_file1.txt
│   │   │   ├── extracted_file2.txt
│   │   │   ├── placeholder.txt
│   │   │   └── program1 (processed output)
│   │   └── program2/
│   │       ├── program2.zip
│   │       └── ...
│   └── no_bounty/
│       ├── program3/
│       │   ├── program3.zip
│       │   └── ...
│       └── ...
├── bugcrowd/
│   ├── bounty/
│   │   └── program4/
│   │       ├── program4.zip
│   │       └── ...
│   └── no_bounty/
│       ├── program5/
│       │   ├── program5.zip
│       │   └── ...
│       └── ...
└── unknown_platform/
    ├── bounty/
    │   ├── program6/
    │   │   ├── program6.zip
    │   │   └── ...
    │   └── ...
    └── no_bounty/
        ├── program7/
        │   ├── program7.zip
        │   └── ...
        └── ...
```

- **Platform Directories:** Programs are organized under their respective platforms (`hackerone`, `bugcrowd`, etc.). Programs without a specified platform are placed under `unknown_platform`.
- **Bounty Status:** Each platform directory contains `bounty` and `no_bounty` subdirectories.
- **Program Directories:** Each program has its own directory containing:
  - The downloaded `.zip` file.
  - Extracted `.txt` files.
  - `placeholder.txt` (concatenated `.txt` files).
  - Processed output file named after the program.

---

## Acknowledgments

- [Project Discovery's Chaos Dataset](https://chaos.projectdiscovery.io/) for providing the subdomain data.
