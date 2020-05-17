require 'yaml'
require 'byebug'
class CanvasDotfile

  def self.update_or_create(filepath, response, course, type)
    if File.file?(".canvas")
      if type == "assignment"
        canvas_data = self.update_assignment_data(response, course)
      else
        canvas_data = self.update_page_data(response, course)
      end
    else
      if type == "assignment"
        canvas_data = self.create_assignment_data(response, course)
      else
        canvas_data = self.create_page_data(response, course)
      end
    end
    self.create_canvas_dotfile(filepath, canvas_data)
  end

  def self.create_canvas_dotfile(filepath, canvas_data)
    File.write("#{filepath}/.canvas", canvas_data.to_yaml)
  end

  def self.commit_canvas_dotfile(filepath)
    GithubInterface.git_add(filepath, '.canvas')
    GithubInterface.git_commit(filepath, 'AUTO: add .canvas file after migration')
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
        id: [response['id']],
        course_id: [course.to_i],
        canvas_url: [response['html_url']],
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
          id: [response['id']],
          course_id: [course.to_i],
          canvas_url: [response['html_url']],
          type: type
        }
      ]
    }
  end

  def self.update_page_data(response, course, type)
    canvas_data = YAML.load(File.read(".canvas"))
    if canvas_data[:lessons].none? { |lesson| lesson[:page_id] == response['page_id'] && lesson[:course_id] == course.to_i && lesson[:canvas_url] == response['html_url']}
      lesson_data = {
        page_id: [response['page_id']],
        course_id: [course.to_i],
        canvas_url: [response['html_url']],
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
          page_id: [response['page_id']],
          course_id: [course.to_i],
          canvas_url: [response['html_url']],
          type: type
        }
      ]
    }
  end
end

# 
#       
#     else
#       