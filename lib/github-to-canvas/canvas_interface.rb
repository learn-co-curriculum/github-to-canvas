require 'json'
require 'rest-client'
require 'yaml'
class CanvasInterface

  def self.create_course(course_info)
    # POST /api/v1/accounts/:account_id/courses
    url = "#{ENV['CANVAS_API_PATH']}/accounts/1/courses"
    payload = {
      'course[name]' => course_info[:name],
      'course[course_code]' => course_info[:course_code]
    }
    response = RestClient.post(url, payload, self.headers)
    JSON.parse(response)
  end

  def self.create_module(course_id, module_info)
    # POST /api/v1/courses/:course_id/modules
    url = "#{ENV['CANVAS_API_PATH']}/courses/#{course_id}/modules"
    payload = {
      'module[name]' => module_info[:name]
    }
    response = RestClient.post(url, payload, headers={
      "Authorization" => "Bearer #{ENV['CANVAS_API_KEY']}"
    })
    JSON.parse(response)
  end

  def self.create_lesson(options, name, html)
    if options[:type] == 'discussion'
      url = "#{ENV['CANVAS_API_PATH']}/courses/#{options[:course_id]}/#{options[:type]}_topics"
    else
      url = "#{ENV['CANVAS_API_PATH']}/courses/#{options[:course_id]}/#{options[:type]}s"
    end
    payload = self.build_payload(options, name, html)
    begin
      response = RestClient.post(url, payload, self.headers)
    rescue
      puts "Something went wrong while pushing lesson #{options[:id]} to course #{options[:course_id]}"
      abort
    end
    if ![200, 201].include? response.code
      puts "Canvas push failed. #{response.code} status code returned "
      abort
    end
    JSON.parse(response.body)
  end

  def self.add_to_module(course_id, module_info, lesson_info)
    # POST /api/v1/courses/:course_id/modules/:module_id/items
    url = "#{ENV['CANVAS_API_PATH']}/courses/#{course_id}/modules/#{module_info["id"]}/items"
    
    if lesson_info["type"] == "Page" || lesson_info["type"] == "page"
      payload = {
        'module_item[title]' => lesson_info["title"],
        'module_item[type]' => lesson_info["type"].capitalize,
        'module_item[indent]' => 0,
        'module_item[page_url]' => lesson_info["id"],
        'module_item[completion_requirement][type]' => 'must_view'
      }
    elsif lesson_info["type"] == "Quiz"
      puts "Quiz needs to be added manually - #{lesson_info['title']} - lesson_info["
    else
      
      payload = {
        'module_item[title]' => lesson_info["title"],
        'module_item[type]' => lesson_info["type"].capitalize,
        'module_item[indent]' => 1,
        'module_item[content_id]' =>  lesson_info["id"],
        'module_item[completion_requirement][type]' => 'must_submit'
      }
    end
    begin
      response = RestClient.post(url, payload, self.headers)
    rescue
      puts "Something went wrong while adding lesson #{lesson_info["id"]} to module #{module_info["id"]} in course #{course_id}" if lesson_info["type"] == "Assignment"
      puts "Something went wrong while adding lesson #{lesson_info["page_url"]} to module #{module_info["id"]} in course #{course_id}" if lesson_info["type"] == "Page"
      abort
    end
    response
    
  end

  def self.update_existing_lesson(options, name, html)
    if options[:type] == "discussion"
      url = "#{ENV['CANVAS_API_PATH']}/courses/#{options[:course_id]}/#{options[:type]}_topics/#{options[:id]}"
    else
      url = "#{ENV['CANVAS_API_PATH']}/courses/#{options[:course_id]}/#{options[:type]}s/#{options[:id]}"
    end
    payload = self.build_payload(options, name, html)
    
    begin
      headers = self.headers
      if options[:type] == 'page' || options[:type] == 'Page'
        response = RestClient.get(url, headers)
        lesson_info = JSON.parse(response)
        lesson_info = lesson_info[0] if lesson_info.kind_of?(Array)
        url = url.sub(/[^\/]+$/, lesson_info["page_id"].to_s)
      end
      response = RestClient.put(url, payload, headers)
    rescue Exception => e
      puts "Something went wrong while pushing lesson #{options[:id]} to course #{options[:course_id]}"
      puts "Make sure you are working on lessons that are not locked"
      raise e
      abort
    end
    JSON.parse(response.body)
  end

  def self.update_all_related_lessons(options, name, html)
    # Read the local .canvas file if --id <ID> is not used. Otherwise, use provided ID (--course <COURSE> also required)
    if !options[:id]
      canvas_data = CanvasDotfile.read_canvas_data
      response = nil
      canvas_data[:lessons] = canvas_data[:lessons].map { |lesson|
        response = self.update_existing_lesson(lesson, name, html)
        options[:id] = lesson[:id]
        options[:course_id] = lesson[:course_id]
        options[:type] = lesson[:type]
        
      }
      RepositoryInterface.local_repo_post_submission(options, response)
      puts "Canvas lesson updated. Lesson available at #{response['html_url']}"
    else
      # If an ID (and course) are provided, they are used instead of the .canvas file
      # Gets the current lesson's type (page or assignment)

      options[:type] = self.get_lesson_info(options[:course_id], options[:id])[1]

      # Implements update on Canvas
      response = self.update_existing_lesson(options, name, html)
      RepositoryInterface.local_repo_post_submission(options, response)
      puts "Canvas lesson updated. Lesson available at #{response['html_url']}"
    end

  end

  def self.get_lesson_info(course, id)

    lesson_types = ["quizzes", "assignments", "pages", "discussion_topics"]
    lesson_type_urls = []
    lesson_types.each do |type|
      lesson_type_urls << "#{ENV['CANVAS_API_PATH']}/courses/#{course}/#{type}/#{id}"
    end

    type = nil
    info = ""
    lesson_type_urls.each do |url|
      begin
        
        response = RestClient.get(url, headers={
          "Authorization" => "Bearer #{ENV['CANVAS_API_KEY']}"
        })
        if [200, 201].include? response.code
          info = JSON.parse(response.body)
          type = lesson_types.find {|type| url.match?("#{type}")}
          type.delete_suffix!('zes')
          type.delete_suffix!('s')
          puts "\nA Canvas #{type} was found in course #{course} with the id #{id}"
          break
        end
      rescue
      end
    end
    
    
    [info, type]
  end


  def self.get_course_info(course, id)
    if id
      lesson_data = self.get_lesson_info(course, id)
      pp lesson_data[0]
      pp "\nLesson Type: #{lesson_data[1]}"
      return
    end

    url = "#{ENV['CANVAS_API_PATH']}/courses/#{course}"
    response = RestClient.get(url, self.headers)
    course_data = JSON.parse(response)

    # /api/v1/courses/:course_id/modules
    course_info = {
      name: course_data['name'],
      id: course_data['id'],
      modules: []
    }

    begin
        index = 1

        while !!index
          url = "#{ENV['CANVAS_API_PATH']}/courses/#{course}/modules?page=#{index}&per_page=20"
          index += 1
          
          response = RestClient.get(url, self.headers)
          modules = JSON.parse(response.body)
          
          if ([200, 201].include? response.code) && (!modules.empty?)
            course_info[:modules] = course_info[:modules] + modules
          else
            index = nil
          end
        end
        
        course_info[:modules] = course_info[:modules].map do |mod|
          new_mod = {
            id: mod['id'],
            name: mod['name'],
            lessons: []
          }
          index = 1
          while !!index
            url = "#{ENV['CANVAS_API_PATH']}/courses/#{course}/modules/#{mod['id']}/items?page=#{index}&per_page=20"
            index += 1
            response = RestClient.get(url, self.headers)
            lessons = JSON.parse(response.body)
            lessons = lessons.map do |lesson|
              if lesson["type"] == "ExternalUrl"
                next
              end
              lesson = lesson.slice("id","title","name","indent","type","html_url","page_url","url","completion_requirement", "published")
              lesson["repository"] = ""
              lesson['id'] = lesson['url'].gsub(/^(.*[\\\/])/,'')
              lesson
            end
            if ([200, 201].include? response.code) && (!lessons.empty?)
              new_mod[:lessons] = new_mod[:lessons] + lessons
            else
              index = nil
            end
            
          end
          new_mod
        end
        
        puts course_info.to_yaml
      
    rescue
      puts "Something went wrong while getting info about course #{course}"
      abort
    end
  end

  def self.map_course_info(options)
    course_info = YAML.load(File.read("#{Dir.pwd}/#{options[:file_to_convert]}"))
    course_info[:modules] = course_info[:modules].map do |mod|
      mod[:lessons] = mod[:lessons].map do |lesson|

        url = lesson["url"]
        response = RestClient.get(url, headers={
          "Authorization" => "Bearer #{ENV['CANVAS_API_KEY']}"
        })
        begin
          lesson_data = JSON.parse(response)
          contents = lesson_data["body"] if lesson["type"] == "Page"
          contents = lesson_data["message"] if lesson["type"] == "Discussion"
          contents = lesson_data["description"] if lesson["type"] == "Assignment" || lesson["type"] == "Quiz"
          if contents.nil?
            repo = ""
          else
            if contents[/data-repo=\"(.*?)"/]
              repo = contents[/data-repo=\"(.*?)"/]
              repo = repo.slice(11..-2)
            elsif contents[/class=\"fis-git-link\" href=\"(.*?)"/]
              repo = contents[/class=\"fis-git-link\" href=\"(.*?)"/]
              repo = repo.slice(27..-2)
            else
              repo = ""
            end
          end
        rescue
          puts 'Error while mapping course info.'
          abort
        end
        
        if repo != nil && repo != ""
          if repo.include?('https://github.com/learn-co-curriculum/')
            lesson["repository"] = repo
          else
            lesson["repository"] = "https://github.com/learn-co-curriculum/" + repo
          end
          puts lesson["repository"] if options[:urls_only]
          puts "#{lesson["repository"]}, #{lesson["title"]}, #{mod[:name]}, #{lesson["type"].downcase}, , #{lesson["id"]}, #{course_info[:id]}" if options[:csv]
        end
        sleep(1)
        lesson
      end
      mod
    end
    puts course_info.to_yaml if !options[:urls_only]
  end

  def self.csv(file_to_convert)
    course_info = YAML.load(File.read("#{Dir.pwd}/#{file_to_convert}"))
    course_info[:modules] = course_info[:modules].map do |mod|
      mod[:lessons] = mod[:lessons].map do |lesson|

        url = lesson["url"]
        response = RestClient.get(url, headers={
          "Authorization" => "Bearer #{ENV['CANVAS_API_KEY']}"
        })
        begin
          lesson_data = JSON.parse(response)
          contents = lesson_data["body"] if lesson["type"] == "Page"
          contents = lesson_data["message"] if lesson["type"] == "Discussion"
          contents = lesson_data["description"] if lesson["type"] == "Assignment" || lesson["type"] == "Quiz"
          if contents.nil?
            repo = ""
          else
            if contents[/data-repo=\"(.*?)"/]
              repo = contents[/data-repo=\"(.*?)"/]
              repo = repo.slice(11..-2)
            elsif contents[/class=\"fis-git-link\" href=\"(.*?)"/]
              repo = contents[/class=\"fis-git-link\" href=\"(.*?)"/]
              repo = repo.slice(27..-2)
            else
              repo = ""
            end
          end
        rescue
          puts 'Error while mapping course info.'
          abort
        end
        
        if repo != nil && repo != ""
          if repo.include?('https://github.com/learn-co-curriculum/')
            lesson["repository"] = repo
          else
            lesson["repository"] = "https://github.com/learn-co-curriculum/" + repo
          end
        end
        sleep(1)
        lesson
      end
      mod
    end
    puts course_info.to_yaml
  end

  def self.copy_lesson(options)
    types = ["page", "assignment", "quiz", "discussion"]
    url = options[:filepath]
    type = types.find {|type| url.match(type)}
    options[:type] = type
    if !url.include?(ENV['CANVAS_API_PATH'])
      url = url.sub(/^.*\/\/.*?\//,"#{ENV['CANVAS_API_PATH']}/")
    end

    response = RestClient.get(url, headers={
      "Authorization" => "Bearer #{ENV['CANVAS_API_KEY']}"
    })

    lesson_info = JSON.parse(response)
    lesson_info = lesson_info.slice("title",
                                    "name",
                                    "description",
                                    "body",
                                    "message",
                                    "shuffle_answers",
                                    "allowed_attempts",
                                    "question_count"
                                    )
    if options[:type] == "page"
      self.update_existing_lesson(options, lesson_info["title"], lesson_info["body"])
    else
      self.update_existing_lesson(options, lesson_info["name"], lesson_info["description"])
    end
    
    
  end

  def self.build_payload(options, name, html)
    if options[:only_update_content]
      if options[:type] == "assignment"
        payload = {
          'assignment[description]' => html
        }
      elsif options[:type] == "discussion"
        payload = {
          'message' => html
        }
      else
        payload = {
          'wiki_page[body]' => html
        }
      end
    else
      if options[:type] == "assignment"
        payload = {
          'assignment[name]' => name,
          'assignment[description]' => html,
          'assignment[submission_types][]' => "online_url",
          'assignment[grading_type]' => 'pass_fail',
          'assignment[points_possible]' => 1
        }
      elsif options[:type] == "discussion"
        payload = {
          'title' => name,
          'message' => html
        }
      else
        payload = {
          'wiki_page[title]' => name,
          'wiki_page[body]' => html,
          'wiki_page[editing_roles]' => "teachers" 
        }
      end
    end
  end

  def self.read_lesson(url)
    types = ["page", "assignment", "quiz", "discussion"]
    type = types.find {|type| url.match(type)}
    if !url.include?(ENV['CANVAS_API_PATH'])
      url = url.sub(/^.*\/\/.*?\//,"#{ENV['CANVAS_API_PATH']}/")
    end

    response = RestClient.get(url, headers={
      "Authorization" => "Bearer #{ENV['CANVAS_API_KEY']}"
    })
    lesson_info = JSON.parse(response)
    lesson_info = lesson_info.slice("title",
                                    "name",
                                    "description",
                                    "body",
                                    "message",
                                    "shuffle_answers",
                                    "allowed_attempts",
                                    "question_count"
                                    )
    lesson_info["type"] = type.capitalize
    if lesson_info["type"] == "Quiz"
      url = url + "/questions"
      response = RestClient.get(url, headers={
        "Authorization" => "Bearer #{ENV['CANVAS_API_KEY']}"
      })
      lesson_info["questions"] = JSON.parse(response)
      lesson_info["questions"] = lesson_info["questions"].map do |question|
        question.slice("id",
                      "position",
                      "question_name",
                      "question_type",
                      "question_text",
                      "points_possible",
                      "correct_comments_html",
                      "incorrect_comments_html",
                      "neutral_comments_html",
                      "answers"
                      )
      end
    end
    lesson_info.to_yaml
  end

  def self.create_lesson_from_remote(course_id, module_id, lesson_type, raw_url, yaml_file)
    url = "#{ENV['CANVAS_API_PATH']}/courses/#{course_id}/modules/#{module_id}/items"
    if yaml_file
      data = YAML.load(File.read("#{Dir.pwd}/#{yaml_file}"))
      payload = {
        'module_item[type]' => data["type"],
        'module_item[title]' => data["title"]
      }
    else

    end
    
  
  end

  def self.headers
    {
      "Authorization" => "Bearer #{ENV['CANVAS_API_KEY']}"
    }
  end

  # def self.create_quiz_from_remote(course_id, module_id, lesson_type, raw_url)
  #   url = "#{ENV['CANVAS_API_PATH']}/courses/#{course_id}/quizzes"
  #   payload = {
  #     'quiz[title]' => 
  #   }
  #   /api/v1/courses/:course_id/quizzes
  #   data = YAML.load(File.read("#{Dir.pwd}/#{yaml_file}"))
  #   payload = {
  #     'module_item[type]' => data["type"],
  #     'module_item[title]' => data["title"]
  #   }
  # end
end