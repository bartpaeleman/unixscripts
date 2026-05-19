# Web Project Scaffolder

A simple shell script to generate a standard directory structure for new web development projects. Compatible with Linux and QNAP Shell.

## Usage

```bash
./scaffold.sh
```

## Features

- **Interactive Setup**: Asks for project name and installation path.
- **Standard Structure**: Creates organized folders for CSS, JS, Images, and PHP includes.
- **Boilerplate Code**: Generates starter `index.php`, `style.css`, `app.js`, and `config.php`.
- **Git Ready**: Includes a basic `.gitignore` file.
- **Auto-Documentation**: Integrates a Python script to generate a tailored `README.md` for the new project.

## Generated Structure

```
project-name/
├── assets/
│   ├── css/
│   │   └── style.css
│   ├── js/
│   │   └── app.js
│   └── img/
├── config/
│   └── config.php
├── includes/
├── index.php
├── README.md (Optional)
└── .gitignore
```

## Requirements

- Bash shell (Linux, or QNAP)
- Python 3 (for README generation)
