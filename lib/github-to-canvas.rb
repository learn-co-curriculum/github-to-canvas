require_relative './github-to-canvas/create_canvas_lesson'
require_relative './github-to-canvas/update_canvas_lesson'
require_relative './github-to-canvas/repository_converter'
require_relative './github-to-canvas/github_interface'
require_relative './github-to-canvas/canvas_interface'
require_relative './github-to-canvas/canvas_dotfile'
require_relative './github-to-canvas/version'

class GithubToCanvas

  def initialize(mode:, 
                course:nil, 
                id:nil,
                filepath:Dir.pwd, 
                file_to_convert:'README.md',
                branch:'master',
                name:File.basename(Dir.getwd), 
                type:"page", 
                save_to_github:false, 
                fis_links:false,
                remove_header_and_footer:false,
                only_update_content: false),
                forkable: false

    if mode == 'version'
      puts VERSION
    end

    if mode == 'query'
      CanvasInterface.get_course_info(course, id)
    end

    if mode == 'remote'
      lesson_data = CanvasInterface.get_lesson_info(course, id)
      if !lesson_data[1]
        puts "No lesson with id #{id} was found in course #{course}."
      else
        pp lesson_data[0]
        puts "\nLesson Type: #{lesson_data[1]}"
      end
      
      
    end

    if mode == 'create'
      puts "github-to-canvas will now create a Canvas lesson based on the current repo"
      CreateCanvasLesson.new(course, filepath, file_to_convert, branch, name, type, save_to_github, fis_links, remove_header_and_footer, forkable)
    end

    if mode == 'align'
      puts "github-to-canvas will now align any existing Canvas lessons based on the current repo. NOTE: .canvas file must be present"
      UpdateCanvasLesson.new(course, filepath, file_to_convert, branch, name, type, save_to_github, fis_links, remove_header_and_footer, only_update_content, id, forkable)
    end
  end

end