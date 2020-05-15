require 'redcarpet'
require 'rest-client'
require 'json'
require 'yaml'
require 'byebug'

class CreateCanvasLesson

  def initialize(course, filepath, branch, name, type)
    @course = course
    @filepath = filepath
    @branch = branch
    @name = name.split(/[ -]/).map(&:capitalize).join(' ')
    @type = type
    @renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML, options={tables: true, autolink: true, fenced_code_blocks: true})
    @original_readme = File.read("#{filepath}/README.md")
    if !@original_readme
      puts 'README.md not found in current directory. Exiting...'
      abort
    end
    create_canvas_lesson
  end

  def create_canvas_lesson
    git_co_branch
    git_pull
    @raw_remote_url = set_raw_image_remote_url
    adjust_local_markdown_images
    adjust_local_html_images
    @new_readme = @renderer.render(@original_readme)
    write_to_html
    @response = push_to_canvas
    if @response.code != 200
      puts "Canvas push failed. #{@response.code} status code returned "
    end
    @response = JSON.parse(@response.body)
    create_canvas_dotfile
    commit_canvas_dotfile
    git_push
  end

  def cd_into_and(command)
    cmd = "cd #{@filepath} && #{command}"
    puts cmd
    `#{cmd}`
  end

  def git_co_branch
    cmd = "git co #{@branch}"
    branch = cd_into_and(cmd)
    if branch.to_s.strip.empty?
      puts "#{b@ranch} branch not found. Exiting..."
      abort
    end
  end

  def git_pull
    if @branch != 'master'
      cmd = "git pull #{@branch}"
    else
      cmd =  "git pull"
    end
    puts "git pulling latest version of #{@branch}"
    cd_into_and(cmd)
  end

  def git_remote
    cmd = "git config --get remote.origin.url"
    cd_into_and(cmd)
  end

  def git_add(file)
    cmd = "git add #{file}"
    puts "git adding #{file}"
    cd_into_and(cmd)
  end

  def git_commit(message)
    cmd = "git commit -m '#{message}'"
    puts "git commit: '#{message}'"
    cd_into_and(cmd)
  end

  def git_push
    cmd = "git push"
    puts "git pushing #{@branch}"
    cd_into_and(cmd)
  end
  
  def set_raw_image_remote_url
    remote = git_remote
    remote.gsub!("git@github.com:","https://raw.githubusercontent.com/")
    remote.gsub!(/.git$/,"")
    remote.strip!
  end

  def adjust_local_markdown_images
    @original_readme.gsub!(/\!\[.+\]\(.+\)/) {|image|
      if !image.match('amazonaws.com') && !image.match('https://')
        image.gsub!(/\(.+\)/) { |path|
          path.delete_prefix!("(")
          path.delete_suffix!(")")
          "(" + remote + "/#{@branch}/" + path + ")"
        }
      end
      image
    }
  end

  def adjust_local_html_images
    @original_readme.gsub!(/src=\"[\s\S]*?" /) { |img|
      img.gsub!(/\"/, "")
      img.gsub!(/src=/, '')
      img.strip!
      'src="' + @raw_remote_url + '/master/' + img + '"'
    }
  end

  def write_to_html
    File.write("#{@filepath}/README.html", @new_readme)
  end

  def push_to_canvas
    url = "#{ENV['CANVAS_API_PATH']}/courses/#{@course}/#{@type}s"
    if @type == "assignment"
      payload = {
        'assignment[name]' => @name,
        'assignment[description]' => @new_readme
      }
    else
      payload = {
        'wiki_page[title]' => @name,
        'wiki_page[body]' => @new_readme,
        'wiki_page[editing_roles]' => "teachers" 
      }
    end

    RestClient.post(url, payload, headers={
      "Authorization" => "Bearer #{ENV['CANVAS_API_KEY']}"
    })
  end

  def create_canvas_dotfile
    canvas_data = {
      page_id: @response['page_id'],
      course_id: @course.to_i,
      canvas_url: @response['html_url']
    }
    File.write("#{@filepath}/.canvas", canvas_data.to_yaml)
  end

  def commit_canvas_dotfile
    git_add('.canvas')
    git_commit('AUTO: add .canvas file after migration')
  end
end