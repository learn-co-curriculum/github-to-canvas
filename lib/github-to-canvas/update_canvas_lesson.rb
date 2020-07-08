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
    GithubInterface.get_updated_repo(filepath, branch)
    new_html = RepositoryConverter.convert(filepath, markdown, branch, remove_header_and_footer)
    if fis_links
      new_html = RepositoryConverter.add_fis_links(filepath, new_html) # adds Flatiron School specific header and footer
    end
    if !id
      # If no assignment or page ID is provided, tries to get info from a .canvas file
      canvas_data = CanvasDotfile.read_canvas_data
      canvas_data[:lessons].each { |lesson|
        response = CanvasInterface.update_existing_lesson(lesson[:course_id], lesson[:id], lesson[:type], name, new_html, only_update_content)
        # puts "Canvas lesson created. Lesson available at #{response['html_url']}."
      }
    else
      # If an ID is provided, uses the ID instead of the .canvas file
      info = CanvasInterface.get_lesson_info(course, id)
      CanvasInterface.update_existing_lesson(course, id, info[1], name, new_html, only_update_content)
    end
  end

  

end