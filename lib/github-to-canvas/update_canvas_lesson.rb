class UpdateCanvasLesson

  def initialize(filepath, branch, name, type, dry_run, fis_links, remove_header_and_footer)
    name = name.split(/[- _]/).map(&:capitalize).join(' ')
    readme = File.read("#{filepath}/README.md")
    if !readme
      puts 'README.md not found in current directory. Exiting...'
      abort
    end
    update_canvas_lesson(readme, filepath, branch, name, type, dry_run, fis_links, remove_header_and_footer)
  end

  def update_canvas_lesson(readme, filepath, branch, name, type, dry_run, fis_links, remove_header_and_footer)
    GithubInterface.get_updated_repo(filepath, branch)
    new_readme = RepositoryConverter.convert(filepath, readme, branch, remove_header_and_footer)
    if fis_links
      new_readme = RepositoryConverter.add_fis_links(filepath, new_readme)
    end
    canvas_data = CanvasDotfile.read_canvas_data
    canvas_data[:lessons].each { |lesson|
      CanvasInterface.update_existing_lesson(lesson[:course_id], lesson[:id], lesson[:type], name, new_readme, dry_run)
    }
  end

  

end