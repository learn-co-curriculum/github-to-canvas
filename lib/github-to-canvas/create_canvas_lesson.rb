class CreateCanvasLesson

  def initialize(course, filepath, file_to_convert, branch, name, type, save_to_github, fis_links, remove_header_and_footer)
    name = name.split(/[- _]/).map(&:capitalize).join(' ')
    begin
      markdown = File.read("#{filepath}/#{file_to_convert}")
    rescue
      puts "#{file_to_convert} not found in current directory. Exiting..."
      abort
    end
    create_canvas_lesson(markdown, course, filepath, branch, name, type, save_to_github, fis_links, remove_header_and_footer)
  end

  def create_canvas_lesson(markdown, course, filepath, branch, name, type, save_to_github, fis_links, remove_header_and_footer)
    GithubInterface.get_updated_repo(filepath, branch)
    new_html = RepositoryConverter.convert(filepath, markdown, branch, remove_header_and_footer)
    if fis_links
      new_html = RepositoryConverter.add_fis_links(filepath, new_html)
    end
    response = CanvasInterface.submit_to_canvas(course, type, name, new_html)
    if save_to_github
      puts 'Creating .canvas file'
      CanvasDotfile.update_or_create(filepath, response, course, type)
      puts 'Commiting .canvas file'
      CanvasDotfile.commit_canvas_dotfile(filepath)
      puts 'Pushing .canvas file'
      GithubInterface.git_push(filepath, branch)
    end
    puts "Canvas lesson created. Lesson available at #{response['html_url']}."
  end

end