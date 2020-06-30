# GitHub to Canvas Gem

## Introduction

The `github-to-canvas` gem is designed to aid in integrating GitHub and the
Canvas LMS. This gem takes a GitHub repository's `README.md` file, converts it
to HTML, and pushes it to Canvas using the Canvas API. The gem also has the ability
to updates a repository to include a `.canvas` file containing Canvas specific
information.

With  the `.canvas` file in place, this gem can be used to continuously align
content between GitHub and Canvas using the GitHub repository as the single
source of truth.

This gem is built for use internally at [Flatiron School][], so some features may be
specific to Flatiron School branding and needs. Access to the
[Canvas LMS API][] and the ability to add pages and assignments to a Canvas
course are required. Write access to the GitHub repository being converted is
also required for committing `.canvas` files.

## Installation

`gem install github-to-canvas`

## Setup

### Generate Canvas API Key

In order to access the Canvas API, you must first generate an API key. Go to
your Canvas Account Settings and under **Approved Integrations**, create a
**New Access Token**. You will need to store this API key as an `ENV` variable
called `CANVAS_API_KEY`. 

If you are using Zsh, the following command will add your new key to the top of `~/.zshrc`:

```sh
echo "$(export 'CANVAS_API_KEY=your-new-API-key-here' | cat - ~/.zshrc)" > ~/.zshrc
```

If you are using Bash, use this command instead:

```sh
echo "$(export 'CANVAS_API_KEY=your-new-API-key-here' | cat - ~/.bash_profile)" > ~/.bash_profile
```

> If you aren't sure which you use, run `echo $SHELL`

### Add Canvas API Base Path

The exact Canvas API path is specific to where you Canvas LMS is located. For example,
Flatiron School's base path is `https://learning.flatironschool.com/api/v1`. Add this path
as an `ENV` variable like the API key. **Do not add a `/` at the end after `/api/v1`.**

```sh
echo "$(export 'CANVAS_API_PATH=<your-base-api-path>' | cat  - ~/.zshrc)" > ~/.zshrc
```

Or for Bash:

```sh
echo "$(export 'CANVAS_API_PATH=<your-base-api-path>' | cat  - ~/.bash_profile)" > ~/.bash_profile
```

After both the API key and path are added to `~/.zshrc`, run `source ~/.zshrc` (`source ~/.bash_profile` for Bash)
to make them available in your current terminal. You can verify these variables
are present by running `ENV` and finding them in the output list.

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

### Saving `.canvas` to GitHub

Using `--save-to-github` will create a `.canvas` YAML file in the local repo and attempt to commit
and push it to the remote repository. This file contains the course id, the newly
created page id, and the Canvas URL to the lesson for future reference. 

If you create multiple Canvas lessons from the same repository, each lesson's
Canvas data will be stored in the `.canvas` file.

### Update an Existing Canvas Lesson

To update an existing Canvas lesson using a local repository, **a `.canvas` file
must be present in the repo**, as it contains the lesson information for the
Canvas API.

1. Clone down and/or change directory into the repository you'd like to update
2. Run `github-to-canvas --align` from inside the local repo

`github-to-canvas` will get the course id and page/assignment id from the
`.canvas` file and update the associated Canvas lesson. If there are multiple
Canvas lessons included in the `.canvas` file, each lesson will be updated (i.e.
you have the same lesson in two courses created from one repository).

### Options

This gem provides to the following options:

* `-c, --create-lesson COURSE` - Creates a new Canvas lesson, converting the local repository's README.md to HTML. Adds .canvas file to remote repository
* `-a, --align` - Updates a canvas lesson based on the local repository's README.md
* `-n, --name NAME` - Sets the name of the new Canvas lesson to be created. If no name is given, repository folder name is used
* `-t, --type TYPE` - Sets the type of Canvas lesson to be created (page, assignment or discussion). If no type, type decided based on repository structure
* `-f, --file FILE` - Looks for and uses a markdown file in the currentt folder as source for conversion. Default file is README.md
* `-b, --branch BRANCH` - Sets the repository branch used for lesson creation
* `-s, --save-to-github` - Creates a local .canvas file and attempts to commit and push it to the GitHub repository
* `-l, --fis-links` - Adds additional Flatiron School HTML after markdown conversion           
* `-r, --remove-header-and-footer` - Removes top lesson header and any Learn.co specific footer links before converting to HTML             
* `-o, --only-content` - For align functionality only - updates the HTML content of a lesson without changing the name
* `-h, --help` - Outputs examples commands and all options
                   

## Examples of Valid Images This Gem Can Convert

Inline Markdown:

![example in-line image](https://curriculum-content.s3.amazonaws.com/fewpjs/fewpjs-fetch-lab/Image_25_AsynchronousJavaScript.png)

HTML:

<p align="center">
  <img src="https://curriculum-content.s3.amazonaws.com/fewpjs/fewpjs-fetch-lab/Image_25_AsynchronousJavaScript.png" width="500">
</p>

[Canvas LMS API]: https://canvas.instructure.com/doc/api/index.html
[Flatiron School]: https://flatironschool.com/
