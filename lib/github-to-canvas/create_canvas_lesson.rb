class CreateCanvasLesson

  def initialize(course, filepath, branch, name, type, dry_run)
    name = name.split(/[- _]/).map(&:capitalize).join(' ')
    original_readme = File.read("#{filepath}/README.md")
    if !original_readme
      puts 'README.md not found in current directory. Exiting...'
      abort
    end
    create_canvas_lesson(original_readme, course, filepath, branch, name, type, dry_run)
  end

  def create_canvas_lesson(readme, course, filepath, branch, name, type, dry_run)
    GithubInterface.get_updated_repo(filepath, branch)
    new_readme = RepositoryConverter.convert(filepath, readme, branch)
    response = CanvasInterface.submit_to_canvas(course, type, name, new_readme, dry_run)
    if dry_run
      puts 'DRY RUN: Skipping dotfile creation and push to GitHub'
    else
      CanvasDotfile.update_or_create(filepath, response, course)
      CanvasDotfile.commit_canvas_dotfile(filepath)
      GithubInterface.git_push(filepath, branch)
    end
  end

end