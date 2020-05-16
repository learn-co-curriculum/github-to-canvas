require 'redcarpet'
require 'rest-client'
require 'json'
require 'yaml'
require_relative './github_interface'

class CreateCanvasLesson

  def initialize(course, filepath, branch, name, type, dry_run)
    puts "Dry: #{dry_run}"
    @course = course
    @filepath = filepath
    @branch = branch
    @name = name.split(/[- _]/).map(&:capitalize).join(' ')
    @type = type
    @renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML, options={tables: true, autolink: true, fenced_code_blocks: true})
    @original_readme = File.read("#{filepath}/README.md")
    @dry_run = dry_run
    @response = {'page_id' => '<the canvas page id>', 'html_url' => '<the canvsas lesson URL>'} if dry_run
    if !@original_readme
      puts 'README.md not found in current directory. Exiting...'
      abort
    end
    create_canvas_lesson
  end

  def create_canvas_lesson
    get_updated_repo
    fix_local_images
    convert_to_html
    submit_to_canvas
    update_remote_repo
  end

  def get_updated_repo
    GithubInterface.git_co_branch(@filepath, @branch)
    GithubInterface.git_pull(@filepath, @branch)
  end

  def fix_local_images
    @raw_remote_url = set_raw_image_remote_url
    adjust_local_markdown_images
    adjust_local_html_images
  end

  def convert_to_html
    @new_readme = @renderer.render(@original_readme)
    write_to_html
  end

  def submit_to_canvas
    if @dry_run
      puts 'DRY RUN: Skipping push to Canvas'
    else
      @response = push_to_canvas
      if @response.code != 200
        puts "Canvas push failed. #{@response.code} status code returned "
      end
      @response = JSON.parse(@response.body)
    end
  end

  def update_remote_repo
    if @dry_run
      puts 'DRY RUN: Skipping push to GitHub'
      puts 'If this were live, the following hash would be converted into a .canvas dotfile:'
      puts handle_existing_canvas_dotfile
    else
      create_canvas_dotfile
      commit_canvas_dotfile
      GithubInterface.git_push(@filepath, @branch)
    end
  end
  
  def set_raw_image_remote_url
    remote = GithubInterface.git_remote(@filepath)
    remote.gsub!("git@github.com:","https://raw.githubusercontent.com/")
    remote.gsub!(/.git$/,"")
    remote.strip!
  end

  private
  
  def adjust_local_markdown_images
    @original_readme.gsub!(/\!\[.+\]\(.+\)/) {|image|
      if !image.match('amazonaws.com') && !image.match('https://') && !image.match('youtube')
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
      if !image.match('amazonaws.com') && !image.match('https://') && !image.match('youtube')
        img.gsub!(/\"/, "")
        img.gsub!(/src=/, '')
        img.strip!
      end
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

  def handle_existing_canvas_dotfile
    if File.file?(".canvas")
      canvas_data = YAML.load(File.read(".canvas"))
      canvas_data[:page_id] << @response['page_id'] if !canvas_data[:page_id].include? @response['page_id']
      canvas_data[:course_id] << @course.to_i if !canvas_data[:course_id].include? @course.to_i
      canvas_data[:canvas_url] << @response['html_url'] if !canvas_data[:canvas_url].include? @response['html_url']
    else
      canvas_data = {
        page_id: [@response['page_id']],
        course_id: [@course.to_i],
        canvas_url: [@response['html_url']]
      }
    end
    canvas_data
  end

  def create_canvas_dotfile
    File.write("#{@filepath}/.canvas", handle_existing_canvas_dotfile.to_yaml)
  end

  def commit_canvas_dotfile
    GithubInterface.git_add(@filepath, '.canvas')
    GithubInterface.git_commit(@filepath, 'AUTO: add .canvas file after migration')
  end
end