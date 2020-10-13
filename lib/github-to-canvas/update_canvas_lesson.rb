class UpdateCanvasLesson

  def initialize(course, filepath, file_to_convert, branch, name, type, save_to_github, fis_links, remove_header_and_footer, only_update_content, id, forkable)
    update_canvas_lesson(course, markdown, filepath, branch, name, type, save_to_github, fis_links, remove_header_and_footer, only_update_content, id, forkable)
  end

  def update_canvas_lesson(course, markdown, filepath, branch, name, type, save_to_github, fis_links, remove_header_and_footer, only_update_content, id, forkable)
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
    end
  end
  

end