require_relative './github-to-canvas/create_canvas_lesson'
require_relative './github-to-canvas/update_canvas_lesson'
require_relative './github-to-canvas/repository_converter'
require_relative './github-to-canvas/github_interface'
require_relative './github-to-canvas/canvas_interface'
require_relative './github-to-canvas/canvas_dotfile'
require_relative './github-to-canvas/version'


class GithubToCanvas

  def initialize(mode:, course:, filepath:Dir.pwd, branch:'master', name:File.basename(Dir.getwd), type:"page", dry:false)
    if mode == 'version'
      puts VERSION
      return
    end

    if mode == 'create'
      puts "github-to-canvas will now create a Canvas lesson based on the current repo"
      CreateCanvasLesson.new(course, filepath, branch, name, type, dry)
    end

    if mode == 'align'
      puts "github-to-canvas will now align any existing Canvas lessons based on the current repo. NOTE: .canvas file must be present"
      UpdateCanvasLesson.new(filepath, branch, name, type, dry)
    end
  end

end