require_relative './github-to-canvas/create-canvas-lesson'
require_relative './github-to-canvas/version'
require_relative './github-to-canvas/github_interface'

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
  end

end