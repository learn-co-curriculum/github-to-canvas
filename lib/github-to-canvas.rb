require_relative './github-to-canvas/create-canvas-lesson'
require_relative './github-to-canvas/version'

class GithubToCanvas

  def initialize(mode:, course:, filepath:Dir.pwd, branch:'master', name:File.basename(Dir.getwd), type:"page")
    if mode == 'version'
      puts VERSION
      return
    end

    if mode == 'create'
      puts "github-to-canvas will now create a Canvas lesson based on the current repo"
      CreateCanvasLesson.new(course, filepath, branch, name, type)
    end
  end

end