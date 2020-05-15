# GitHub to Canvas Gem

## Introduction

The `github-to-canvas` gem is designed to enable GitHub to Canvas LMS
integration. This gem is designed to take a GitHub repository's `README.md`
file, convert it to HTML, and push it to Canvas. The gem also updates the
repository to include a `.canvas` file containing Canvas specific information.

With  the `.canvas` file in place, this gem can be used to continuously align
content between GitHub and Canvas.

This gem is built for use internally at [Flatiron School][]. Access to the
[Canvas LMS API][] and the ability to add pages and assignments to a Canvas
course are required.

## Installation

`gem install github-to-canvas`

## Setup

### Generate Canvas API Key

In order to access the Canvas API, you must first generate an API key. Go to
your Canvas Account Settings and under **Approved Integrations**, create a
**New Access Token**. You will need to store this API key as an `ENV` variable
called `CANVAS_API_KEY`. Use the following command to add your new key to
`~/.zshrc`:

```sh
echo "$(echo 'CANVAS_API_KEY=<your-new-API-key-here>' | cat  - ~/.zshrc)" > ~/.zshrc
```

> **Note:** The command above assumes you are using Zsh. Change the dotfile if
> you are using something else like Bash.

### Add Canvas API Base Path

The exact Canvas API path is specific to where you Canvas LMS is located. For example,
Flatiron School's base path is `https://learning.flatironschool.com/api/v1`. Add this path
as an `ENV` variable like the API key. **Do not add a `/` at the end after `/api/v1`.**

```sh
echo "$(echo 'CANVAS_API_PATH=<your-base-api-path>' | cat  - ~/.zshrc)" > ~/.zshrc
```

After both the API key and path are added to `~/.zshrc`, run `source ~/.zshrc`
to make them available in your current terminal. You can verify these variables
are present by running `ENV`.

## Usage

To migrate a GitHub `README.md` file to Canvas, at minimum, you will need to know the
Canvas course id you are going to add to. This id can be found in the URL of the course.

1. clone down the repository to a local folder and change directory into it.
2. Run `github-to-canvas --create <your-course-id>`

If everything is set up properly, `github-to-canvas` will create a Canvas lesson
using `master` branch `README.md` and the name of the current folder. By
default, if the repository contains folders, an **assignment** will be created.
Otherwise, a **page** will be created.

After a successful lesson creation, `github-to-canvas` will use the API response
to build a `.canvas` YAML file. This file contains the course id, the newly created
page id, and the Canvas URL to the lesson for future reference.

### Options

You can override the default behaviors with the following arguments:

* `--name NAME` uses the provided name instead of the repository's folder name
* `--branch BRANCH` uses the provided git branch instead of `master`  
* `--type TYPE` will accept either `'page'` or `'assignment'` and create the
  appropriate Canvas lesson type instead of relying on the repository's
  directory structure

[Canvas LMS API]: https://canvas.instructure.com/doc/api/index.html
[Flatiron School]: https://flatironschool.com/