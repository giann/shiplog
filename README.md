# ⚓ Shiplog
A journal keeping cli tool

<p align="center">
    <img src="https://raw.githubusercontent.com/giann/shiplog/master/screen.png" alt="Shiplog">
</p>

## Installation

```bash
luarocks install shiplog
```

## Usage

### Options:
- `-h`, `--help`: Show this help message and exit.

### Commands:
- `init`, `i`: Init shiplog database and git repository
- `add`, `a`: Write a log entry
- `modify`, `mod`, `m`: Modify a log entry
- `delete`, `del`, `d`: Delete an entry
- `list`, `ls`, `l`: List log entries
- `view`, `v`: View an entry
- `git`: Forward git commands to shiplog's repository

You can have a detailed help for each command with the `--help` option.

## Features

- [X] Write log entries
- [X] Tag entries
- [ ] Interactive mode with sirocco
- [ ] Add location and other attributes to entries
- [ ] Filter entries
    + [X] by tags
    + [ ] by attributes
    + [ ] by location
- [ ] [Encrypt/Decrypt entries with gpg key](https://www.sqlite.org/see/doc/release/www/readme.wiki)
- [X] Sync over git repository
- [ ] User defined attributes

## Requirements

- SQLite3
- git