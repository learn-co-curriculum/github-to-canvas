class UpdateCanvasLesson

  def initialize(course, filepath, file_to_convert, branch, name, type, save_to_github, fis_links, remove_header_and_footer, only_update_content, id)
    name = name.split(/[- _]/).map(&:capitalize).join(' ')
    begin
      markdown = File.read("#{filepath}/#{file_to_convert}")
    rescue
      puts "#{file_to_convert} not found in current directory. Exiting..."
      abort
    end
    update_canvas_lesson(course, markdown, filepath, branch, name, type, save_to_github, fis_links, remove_header_and_footer, only_update_content, id)
  end

  def update_canvas_lesson(course, markdown, filepath, branch, name, type, save_to_github, fis_links, remove_header_and_footer, only_update_content, id)
    # Pulls any updates that exist on GitHub
    GithubInterface.get_updated_repo(filepath, branch)
    
    # Converts markdown to HTML
    # Default is README.md. --file <FILENAME> can be used to override default.
    new_html = RepositoryConverter.convert(filepath, markdown, branch, remove_header_and_footer)
    
    # adds Flatiron School specific header and footer
    if fis_links
      new_html = RepositoryConverter.add_fis_links(filepath, new_html) 
    end

    # Read the local .canvas file if --id <ID> is not used. Otherwise, use provided ID (--course <COURSE> also required)
    if !id
      canvas_data = CanvasDotfile.read_canvas_data
      canvas_data[:lessons] = canvas_data[:lessons].map { |lesson|
        response = CanvasInterface.update_existing_lesson(lesson[:course_id], lesson[:id], lesson[:type], name, new_html, only_update_content)
      }
    else
      # If an ID (and course) are provided, they are used instead of the .canvas file
      # Gets the current lesson's type (page or assignment)
      info = CanvasInterface.get_lesson_info(course, id)

      # Implements update on Canvas
      response = JSON.parse(CanvasInterface.update_existing_lesson(course, id, info[1], name, new_html, only_update_content))
      
      # Updates or creates a local .canvas file
      CanvasDotfile.update_or_create(filepath, response, course, info[1])
    end
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