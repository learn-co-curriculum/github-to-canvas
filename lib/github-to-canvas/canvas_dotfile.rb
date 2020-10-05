require 'yaml'
class CanvasDotfile

  def self.exists?
    File.file?(".canvas")
  end

  def self.update_or_create(options, response)
    if self.exists?
      if options[:type] == "assignment" || options[:type] == "discussion"
        canvas_data = self.update_assignment_data(response, options[:course_id], options[:type])
      else
        canvas_data = self.update_page_data(response, options[:course_id], options[:type])
      end
    else
      if options[:type] == "assignment" || options[:type] == "discussion"
        canvas_data = self.create_assignment_data(response, options[:course_id], options[:type])
      else
        canvas_data = self.create_page_data(response, options[:course_id], options[:type])
      end
    end
    self.create_canvas_dotfile(options[:filepath], canvas_data)
  end

  def self.create_canvas_dotfile(filepath, canvas_data)
    File.write("#{filepath}/.canvas", canvas_data.to_yaml)
  end

  def self.read_canvas_data
    if File.file?(".canvas")
       YAML.load(File.read(".canvas"))
    else
      puts 'ERROR: Align functionalty requires .canvas file to be present'
      abort
    end
  end

  def self.update_assignment_data(response, course, type)
    canvas_data = YAML.load(File.read(".canvas"))
    if canvas_data[:lessons].none? { |lesson| lesson[:id] == response['id'] && lesson[:course_id] == course.to_i && lesson[:canvas_url] == response['html_url']}
      lesson_data = {
        id: response['id'],
        course_id: course.to_i,
        canvas_url: response['html_url'],
        type: type
      }  
      canvas_data[:lessons] << lesson_data
    end
    canvas_data
  end

  def self.create_assignment_data(response, course, type)
    {
      lessons: [
        {
          id: response['id'],
          course_id: course.to_i,
          canvas_url: response['html_url'],
          type: type
        }
      ]
    }
  end

  def self.update_page_data(response, course, type)
    canvas_data = YAML.load(File.read(".canvas"))
    if canvas_data[:lessons].none? { |lesson| lesson[:id] == response['page_id'] && lesson[:course_id] == course.to_i && lesson[:canvas_url] == response['html_url']}
      lesson_data = {
        id: response['page_id'],
        course_id: course.to_i,
        canvas_url: response['html_url'],
        type: type
      }  
      canvas_data[:lessons] << lesson_data
    end
    canvas_data
  end

  def self.create_page_data(response, course, type)
    {
      lessons: [
        {
          id: response['page_id'],
          course_id: course.to_i,
          canvas_url: response['html_url'],
          type: type
        }
      ]
    }
  end
end
