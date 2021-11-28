require 'csv'
require_relative './github-to-canvas/create_canvas_lesson'
require_relative './github-to-canvas/update_canvas_lesson'
require_relative './github-to-canvas/canvas_dotfile'
require_relative './github-to-canvas/repository_interface'
require_relative './github-to-canvas/repository_converter'
require_relative './github-to-canvas/github_interface'
require_relative './github-to-canvas/canvas_interface'
require_relative './github-to-canvas/course_creation_interface'

require_relative './github-to-canvas/version'

require 'yaml'

class GithubToCanvas

  def initialize(options)
    case options[:mode]
    when 'version'
      puts VERSION
    when 'query'
      CanvasInterface.get_course_info(options[:course_id], options[:id])
    when 'map'
      CanvasInterface.map_course_info(options)
    when 'csv'
      CanvasInterface.csv(options[:file_to_convert]) # not working properly
    when 'canvas_read'
      puts CanvasInterface.read_lesson(options[:filepath])
    when 'canvas_copy'
      CanvasInterface.copy_lesson(options)
    when 'github_read'
      html = RepositoryConverter.remote_file_conversion(options)
      puts RepositoryConverter.adjust_converted_html(options, html)
    when 'create' # used with a local repo
      html = RepositoryConverter.local_file_conversion(options)
      name = RepositoryInterface.get_name(options[:filepath], html)
      html = RepositoryConverter.adjust_converted_html(options, html)
      response = CanvasInterface.create_lesson(options, name, html)
      RepositoryInterface.local_repo_post_submission(options, response)
      puts "Canvas lesson created. Lesson available at #{response['html_url']}"
    when 'align' # used with a local repo
      html = RepositoryConverter.local_file_conversion(options)
      name = options[:name] ? options[:name] : RepositoryInterface.get_name(options[:filepath], html)
      html = RepositoryConverter.adjust_converted_html(options, html)
      CanvasInterface.update_all_related_lessons(options, name, html)
      
    when 'github_create'
      if (!options[:branch])
        options[:branch] = 'master'
      end
      html = RepositoryConverter.remote_file_conversion(options)
      
      html = RepositoryConverter.adjust_converted_html(options, html)
      name = options[:name] ? options[:name] : RepositoryInterface.get_name(options[:filepath], html)
      puts name
      response = CanvasInterface.create_lesson(options, name, html)
      
      puts "Canvas lesson created. Lesson available at #{response['html_url']}"
    when 'github_align'
      if (!options[:branch])
        options[:branch] = 'master'
      end
      html = RepositoryConverter.remote_file_conversion(options)
      name = options[:name] ? options[:name] : RepositoryInterface.get_name(options[:filepath], html)
      
      html = RepositoryConverter.adjust_converted_html(options, html)
      response = CanvasInterface.update_existing_lesson(options, name, html)
      puts "Canvas lesson updated. Lesson available at #{response['html_url']}"
    when 'build_course'
      course_yaml = YAML.load(File.read(options[:file_to_convert]))
      # Create Course
      created_course_info = CanvasInterface.create_course(course_yaml)
      puts "Course created - #{created_course_info["id"]}"

      course_yaml[:modules].each { |module_info|
        # Create each module
        created_module_info = CanvasInterface.create_module(created_course_info["id"], module_info)
        puts "Module created - #{created_module_info['name']}"
        module_info[:lessons].each { |lesson|
          # Create each lesson
          options[:type] = lesson["type"].downcase
          options[:course_id] = created_course_info["id"]
          options[:filepath] = lesson["repository"]
          
          html = RepositoryConverter.remote_file_conversion(options)
          # Add each lesson to it's module
          html = RepositoryConverter.adjust_converted_html(options, html)
          created_lesson_info = CanvasInterface.create_lesson(options, lesson["title"], html) 
          lesson = lesson.merge(created_lesson_info)
          
          lesson["page_url"] = lesson["url"] if !lesson["page_url"]

          response = CanvasInterface.add_to_module(created_course_info["id"], created_module_info, lesson)
          
          puts "Lesson added to #{created_module_info['name']} - #{lesson['title']}"
          sleep(1)
        }
      }
    when 'add_to_course'
      course_yaml = YAML.load(File.read(options[:file_to_convert]))

      course_yaml[:modules].each { |module_info|
        # Create each module
        created_module_info = CanvasInterface.create_module(options[:course_id], module_info)
        puts "Module created - #{created_module_info['name']}"
        module_info[:lessons].each { |lesson|
          # Create each lesson

          options[:type] = lesson["type"].downcase
          options[:filepath] = lesson["repository"]
          html = RepositoryConverter.remote_file_conversion(options)
          # Add each lesson to it's module
          html = RepositoryConverter.adjust_converted_html(options, html)
          created_lesson_info = CanvasInterface.create_lesson(options, lesson["title"], html)
          lesson = lesson.merge(created_lesson_info)
          response = CanvasInterface.add_to_module(options[:course_id], created_module_info, lesson)
          
          puts "Lesson added to #{created_module_info['name']} - #{lesson['title']}"
          sleep(1)
        }
      }
    when 'add_to_course_local'
      course_yaml = YAML.load(File.read(options[:yaml_file_to_convert]))

      course_yaml[:modules].each { |module_info|
        # Create each module
        created_module_info = CanvasInterface.create_module(options[:course_id], module_info)
        puts "Module created - #{created_module_info['name']}"
        module_info[:lessons].each { |lesson|
          # Create each lesson

          options[:type] = lesson["type"].downcase
          # split relative path from repository tag in YAML into path and file to match downstream processing expectations
          options[:filepath] = File.dirname(lesson["repository"])
          options[:file_to_convert] = File.basename(lesson["repository"])
          html = RepositoryConverter.local_file_conversion(options)
          # Add each lesson to it's module
          html = RepositoryConverter.adjust_converted_html(options, html)
          created_lesson_info = CanvasInterface.create_lesson(options, lesson["title"], html)
          lesson = lesson.merge(created_lesson_info)
          response = CanvasInterface.add_to_module(options[:course_id], created_module_info, lesson)
          
          puts "Lesson added to #{created_module_info['name']} - #{lesson['title']}"
          sleep(1)
        }
      }
 
    when 'update_course_lessons'
      course_yaml = YAML.load(File.read(options[:file_to_convert]))
      options[:course_id] = course_yaml[:id]
      course_yaml[:modules].each { |module_info|
        puts "Updating #{module_info[:name]}"
        module_info[:lessons].each { |lesson|
          if lesson["repository"] == ""
            puts "No repository found for #{lesson['title']}"
            next
          end
          options[:id] = lesson['id']
          options[:type] = lesson["type"].downcase
          options[:filepath] = lesson["repository"]
          options[:branch] = 'master'
          html = RepositoryConverter.remote_file_conversion(options)
          
          html = RepositoryConverter.adjust_converted_html(options, html)
          created_lesson_info = CanvasInterface.update_existing_lesson(options, lesson["title"], html)
          lesson = lesson.merge(created_lesson_info)
          
          
          puts "Lesson updated - #{lesson['title']}"
          sleep(1)
        }
      }
    when 'clone_course'
      course_yaml = YAML.load(File.read(options[:file_to_convert]))
      new_dir = "#{course_yaml[:name].downcase.gsub(' ','-')}"
      cmd = "mkdir #{new_dir}"
      `#{cmd}`
      course_yaml[:modules].each { |module_info|
      puts "Cloning #{module_info[:name]}"
        module_info[:lessons].each { |lesson|
        if lesson["repository"] == ""
          puts "No repository found for #{lesson['title']}"
          next
        else
          cmd = "git clone #{lesson['repository']}"
          puts cmd
          GithubInterface.cd_into_and(new_dir, cmd)
        end
        }
      }
    when 'csv_build'
      if !options[:course_id]
        course_info = {
          name: "CSV Build Test",
          course_code: "CSV-TEST"
        }
        created_course_info = CanvasInterface.create_course(course_info)
        puts "Course created - #{created_course_info["id"]}"
        puts "Make sure to add yourself as a teacher to this course before continuing, then press Enter/Return"
        input = gets
        options[:course_id] = created_course_info["id"]
      else
        puts "Adding to course #{options[:course_id]}"
      end
      
      csv_data = CSV.read(options[:file_to_convert])
      created_module_info = {
        "id" => "",
        "name" => ""
      }
      
      csv_data.each { |lesson|
        # lesson[0] == repo
        # lesson[1] == name
        # lesson[2] == module
        # lesson[3] == type
        # lesson[4] == yes/no contains HTML
        module_info = {
          name: lesson[2]
        }
        if created_module_info["name"] != module_info[:name]
          created_module_info = CanvasInterface.create_module(options[:course_id], module_info)
          puts "New module created - #{created_module_info["id"]} - #{created_module_info["name"]}"
        end

        options[:filepath] = lesson[0]
        options[:name] = lesson[1]
        options[:type] = lesson[3]
        options[:branch] = "master" if !options[:branch]
        

        html = RepositoryConverter.remote_file_conversion(options)
        html = RepositoryConverter.adjust_converted_html(options, html)
        created_lesson_info = CanvasInterface.create_lesson(options, lesson[1], html)
        created_lesson_info["page_url"] = created_lesson_info["url"] if !created_lesson_info["page_url"]
        created_lesson_info["id"] = created_lesson_info["page_url"] if !created_lesson_info["id"]
        created_lesson_info["type"] = options[:type]
        puts "Creating lesson - #{options[:name]}"
        response = CanvasInterface.add_to_module(options[:course_id], created_module_info, created_lesson_info)
        
      }
    when 'csv_align'
      
      csv_data = CSV.read(options[:file_to_convert])
      created_module_info = {
        "id" => "",
        "name" => ""
      }
      
      csv_data.each { |lesson|
        # lesson[0] == repo
        # lesson[1] == name
        # lesson[2] == module
        # lesson[3] == type
        # lesson[4] == yes/no contains HTML
        # lesson[5] == lesson id
        # lesson[6] == course id

        module_info = {
          name: lesson[2]
        }

        options[:filepath] = lesson[0]
        options[:name] = lesson[1]
        options[:type] = lesson[3]
        options[:id] = lesson[5]
        options[:course_id] = lesson[6]
        options[:branch] = "master" if !options[:branch]
        

        html = RepositoryConverter.remote_file_conversion(options)
        html = RepositoryConverter.adjust_converted_html(options, html)
        updated_lesson_info = CanvasInterface.update_existing_lesson(options, lesson[1], html)
        updated_lesson_info["page_url"] = updated_lesson_info["url"] if !updated_lesson_info["page_url"]
        updated_lesson_info["id"] = updated_lesson_info["page_url"] if !updated_lesson_info["id"]
        updated_lesson_info["type"] = options[:type]
        puts "Updating lesson - #{options[:name]}"
        
      }
    else
      puts VERSION
    end
  end
  
end
