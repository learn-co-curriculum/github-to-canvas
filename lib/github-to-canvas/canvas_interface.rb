require 'json'
require 'rest-client'
require 'yaml'
class CanvasInterface

  def self.get_lesson_info(course, id)

    lesson_types = ["quizzes", "assignments", "pages", "discussion_topics"]
    lesson_type_urls = []
    lesson_types.each do |type|
      lesson_type_urls << "#{ENV['CANVAS_API_PATH']}/courses/#{course}/#{type}/#{id}"
    end

    type = nil
    info = ""
    byebug
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

    # /api/v1/courses/:course_id/modules
    course_info = {
      name: "",
      modules: []
    }

    begin
        index = 1

        while !!index
          url = "#{ENV['CANVAS_API_PATH']}/courses/#{course}/modules?page=#{index}&per_page=20"
          index += 1
          response = RestClient.get(url, headers={
            "Authorization" => "Bearer #{ENV['CANVAS_API_KEY']}"
          })
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
            response = RestClient.get(url, headers={
              "Authorization" => "Bearer #{ENV['CANVAS_API_KEY']}"
            })
            lessons = JSON.parse(response.body)
            lessons = lessons.map do |lesson|
              lesson["repository"] = ""
              lesson.slice("type","title","html_url","repository","url","indent")
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

  def self.map_course_info(file_to_convert)
    course_info = YAML.load(File.read("#{Dir.pwd}/#{file_to_convert}"))
    course_info[:modules] = course_info[:modules].map do |mod|
      mod[:lessons] = mod[:lessons].map do |lesson|

        url = lesson["url"]
        response = RestClient.get(url, headers={
            "Authorization" => "Bearer #{ENV['CANVAS_API_KEY']}"
          })
        begin
          lesson_data = JSON.parse(response)
          repo = lesson_data["body"] if lesson["type"] == "Page"
          repo = lesson_data["message"] if lesson["type"] == "Discussion"
          repo = lesson_data["description"] if lesson["type"] == "Assignment" || lesson["type"] == "Quiz"
          repo = repo[/data-repo=\"(.*?)"/]
        rescue
          byebug
        end
        
        if repo != nil && repo.include?("data-repo")
          lesson["repository"] = "https://github.com/learn-co-curriculum/" + repo.slice(11..-2)
        end
        sleep(1)
        lesson
      end
      mod
    end
    puts course_info.to_yaml
  end

  def self.submit_to_canvas(course_id, type, name, readme)
    response = self.push_to_canvas(course_id, type, name, readme)
    if ![200, 201].include? response.code
      puts "Canvas push failed. #{response.code} status code returned "
      abort
    end
    JSON.parse(response.body)
  end

  def self.push_to_canvas(course_id, type, name, new_readme)
    if type == 'discussion'
      url = "#{ENV['CANVAS_API_PATH']}/courses/#{course_id}/#{type}_topics"
    else
      url = "#{ENV['CANVAS_API_PATH']}/courses/#{course_id}/#{type}s"
    end
    payload = self.build_payload(type, name, new_readme, false)
    begin
      RestClient.post(url, payload, headers={
        "Authorization" => "Bearer #{ENV['CANVAS_API_KEY']}"
      })
    rescue
      puts "Something went wrong while pushing lesson #{id} to course #{course_id}"
      abort
    end
  end

  def self.update_existing_lesson(course_id, id, type, name, new_readme, only_update_content)
    if type == "discussion"
      url = "#{ENV['CANVAS_API_PATH']}/courses/#{course_id}/#{type}_topics/#{id}"
    else
      url = "#{ENV['CANVAS_API_PATH']}/courses/#{course_id}/#{type}s/#{id}"
    end
    payload = self.build_payload(type, name, new_readme, only_update_content)
    begin
      RestClient.put(url, payload, headers={
        "Authorization" => "Bearer #{ENV['CANVAS_API_KEY']}"
      })
    rescue
      puts "Something went wrong while pushing lesson #{id} to course #{course_id}"
      ""
    end
  end

  def self.build_payload(type, name, new_readme, only_update_content)
    if only_update_content
      if type == "assignment"
        payload = {
          'assignment[description]' => new_readme
        }
      elsif type == "discussion"
        payload = {
          'message' => new_readme
        }
      else
        payload = {
          'wiki_page[body]' => new_readme
        }
      end
    else
      if type == "assignment"
        payload = {
          'assignment[name]' => name,
          'assignment[description]' => new_readme
        }
      elsif type == "discussion"
        payload = {
          'title' => name,
          'message' => new_readme
        }
      else
        payload = {
          'wiki_page[title]' => name,
          'wiki_page[body]' => new_readme,
          'wiki_page[editing_roles]' => "teachers" 
        }
      end
    end
  end
end