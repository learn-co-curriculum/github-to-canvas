# GitHub to Canvas Gem

## Introduction

The `github-to-canvas` gem is designed to enable GitHub to Canvas LMS
integration. This gem is designed to take a GitHub repository's `README.md`
file, convert it to HTML, and push it to Canvas. The gem also updates the
repository to include a `.canvas` file containing Canvas specific information.

With  the `.canvas` file in place, this gem can be used to continuously align
content between GitHub and Canvas using the GitHub repository as the single
source of truth.

This gem is built for use internally at [Flatiron School][]. Access to the
[Canvas LMS API][] and the ability to add pages and assignments to a Canvas
course are required. Write access to the GitHub repository being converted is
also required.

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
echo "$(export 'CANVAS_API_KEY=<your-new-API-key-here>' | cat  - ~/.zshrc)" > ~/.zshrc
```

> **Note:** The command above assumes you are using Zsh. Change the dotfile if
> you are using something else like Bash.

### Add Canvas API Base Path

The exact Canvas API path is specific to where you Canvas LMS is located. For example,
Flatiron School's base path is `https://learning.flatironschool.com/api/v1`. Add this path
as an `ENV` variable like the API key. **Do not add a `/` at the end after `/api/v1`.**

```sh
echo "$(export 'CANVAS_API_PATH=<your-base-api-path>' | cat  - ~/.zshrc)" > ~/.zshrc
```

After both the API key and path are added to `~/.zshrc`, run `source ~/.zshrc`
to make them available in your current terminal. You can verify these variables
are present by running `ENV`.

## Usage

### Create a Canvas Lesson

To create a Canvas lesson from a GitHub `README.md` file, at minimum, you will
need to know the Canvas course id you are going to add to. This id can be found
in the URL of the course.

Once you have the course id, you will need to do the following:

1. Clone down the repository you'd like to push to Canvas.
2. Change directory into the new local repository
3. Run `github-to-canvas --create <your-course-id>` from inside the local repo

If everything is set up properly, `github-to-canvas` will create a Canvas lesson
using `master` branch `README.md` and the name of the current folder. By
default, if the repository contains folders, an **assignment** will be created.
Otherwise, a **page** will be created.

After a successful lesson creation, `github-to-canvas` will use the API response
to build a `.canvas` YAML file. This file contains the course id, the newly
created page id, and the Canvas URL to the lesson for future reference. With the
newly created `.canvas` file, `github-to-canvas` will attempt to commit and push the
file up to the remote GitHub repository.

If you create multiple Canvas lessons from the same repository, each lesson's
Canvas data will be stored in the `.canvas` file.

> **Note:** If you don't have write access to the repository, the `.canvas` file
> will still be created locally.

### Update an existing Canvas Lesson

To update an existing Canvas lesson using a local repository, **a `.canvas` file
must be present in the repo**, as it contains the lesson information for the
Canvas API.

1. Clone down and/or change directory into the repository you'd like to update
2. Run `github-to-canvas --align <your-course-id>` from inside the local repo

`github-to-canvas` will get the course id and page/assignment id from the
`.canvas` file and update the associated Canvas lesson. If there are multiple
Canvas lessons included in the `.canvas` file, each lesson will be updated (i.e.
you have the same lesson in two courses created from one repository).

### Options

You can override the default behaviors with the following arguments:

* `--name NAME` uses the provided name instead of the repository's folder name
* `--branch BRANCH` uses the provided git branch instead of `master`  
* `--type TYPE` will accept either `'page'` or `'assignment'` and create the
  appropriate Canvas lesson type instead of relying on the repository's
  directory structure

[Canvas LMS API]: https://canvas.instructure.com/doc/api/index.html
[Flatiron School]: https://flatironschool.com/