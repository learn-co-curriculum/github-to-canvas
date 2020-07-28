class CreateCanvasLesson

  def initialize(course, filepath, file_to_convert, branch, name, type, save_to_github, fis_links, remove_header_and_footer, forkable)
    # name = name.split(/[- _]/).map(&:capitalize).join(' ')
    begin
      markdown = File.read("#{filepath}/#{file_to_convert}")
    rescue
      puts "#{file_to_convert} not found in current directory. Exiting..."
      abort
    end
    create_canvas_lesson(markdown, course, filepath, branch, name, type, save_to_github, fis_links, remove_header_and_footer, forkable)
  end

  def create_canvas_lesson(markdown, course, filepath, branch, name, type, save_to_github, fis_links, remove_header_and_footer, forkable)
    GithubInterface.get_updated_repo(filepath, branch)
    new_html = RepositoryConverter.convert(filepath, markdown, branch, remove_header_and_footer)
    if fis_links
      new_html = RepositoryConverter.add_fis_links(filepath, new_html, forkable)
    end
    response = CanvasInterface.submit_to_canvas(course, type, name, new_html)
    
    puts 'Creating .canvas file'
    CanvasDotfile.update_or_create(filepath, response, course, type) 

    puts "Canvas lesson created. Lesson available at #{response['html_url']}."

    # If --save option is used, the .canvas file gets committed and pushed to the remote repo
    if save_to_github
      puts 'Adding .canvas file'
      GithubInterface.git_add(filepath, '.canvas')
      puts 'Commiting .canvas file'
      GithubInterface.git_commit(filepath, 'AUTO: add .canvas file after migration')
      puts 'Pushing .canvas file'
      GithubInterface.git_push(filepath, branch)
    end
  end

end