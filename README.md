# lookback

A Bash utility to compare files and directories.

#### 📋 Description

`lookback` provides a fast way to verify data integrity and structural consistency. It supports:
* File comparison: checksums (xxHash and MD5)
* Directory comparison: filenames, file sizes, and optionally folder structure

#### 💻 Compatibility

* macOS (BSD)
* Linux (GNU)

#### 🛠 Dependencies

* [xxHash](https://github.com/Cyan4973/xxHash) for high-speed checksumming.

#### 🚀 Installation

1. Install [Homebrew](https://brew.sh/) (if not already installed):
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. Tap and install:
```
brew tap lucuma13/homebrew-dit
brew install lookback
```

#### 📖 Usage

`lookback [options] <source> <destination>`

Optional flags:<br>
`--version` : Print version<br>
`-h` : Print help menu<br>
`-v` : Verbose<br>
`-i` : Ignore folder structure<br>
`-y` : Side-by-side comparison<br>
`-s` : Save a list of files of the source directory (on the destination directory)<br>
`-H` : File comparison using specific hash function: xxHash-128 (default), md5<br>
`-X` : Show hidden AppleDouble files<br>

#### 🤝 Acknowledgments

A special thank you to Mohammad Ayyash for initiating me into the dark magic of Bash, and writing the first "molist" commands from which this utility evolved.
