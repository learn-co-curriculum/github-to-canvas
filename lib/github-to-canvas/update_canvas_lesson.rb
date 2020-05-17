class UpdateCanvasLesson

  def initialize(filepath, branch, name, type, dry_run)
    name = name.split(/[- _]/).map(&:capitalize).join(' ')
    original_readme = File.read("#{filepath}/README.md")
    if !original_readme
      puts 'README.md not found in current directory. Exiting...'
      abort
    end
    update_canvas_lesson(course, filepath, branch, name, type, dry_run)
  end

  def update_canvas_lesson(readme, course, filepath, branch, name, type, dry_run)
    GithubInterface.get_updated_repo(filepath, branch)
    new_readme = RepositoryConverter.convert(filepath, readme, branch)
    canvas_data = CanvasDotfile.read_canvas_data
    canvas_data[:lessons].each { |lesson|
      CanvasInterface.update_existing_lesson(lesson[:course_id], lesson[:page_id],type, name, new_readme, dry_run)
    }
  end

  

end