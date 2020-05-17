require 'yaml'

class CanvasDotfile

  def self.update_or_create(filepath, response, course)
    if File.file?(".canvas")
      canvas_data = YAML.load(File.read(".canvas"))
      if canvas_data[:lessons].none? { |lesson| lesson[:page_id] == response['page_id'] && lesson[:course_id] == course.to_i && lesson[:canvas_url] == response['html_url']}
        lesson_data = {
          page_id: [response['page_id']],
          course_id: [course.to_i],
          canvas_url: [response['html_url']]
        }  
        canvas_data[:lessons] << lesson_data
      end
    else
      canvas_data = {
        lessons: [
          {
            page_id: [response['page_id']],
            course_id: [course.to_i],
            canvas_url: [response['html_url']]
          }
        ]
      }
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
end