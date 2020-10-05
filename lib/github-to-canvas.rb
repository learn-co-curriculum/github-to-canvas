require 'byebug'
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
      CanvasInterface.map_course_info(options[:file_to_convert])
    when 'canvas_read'
      puts CanvasInterface.read_lesson(options[:filepath])
    when 'github_read'
      markdown = GithubInterface.read_remote(options[:filepath])
      puts RepositoryConverter.convert_to_html(markdown)
    when 'create' # used with a local repo
      html = RepositoryConverter.local_file_conversion(options)
      name = RepositoryInterface.get_name(options[:filepath], html)
      html = RepositoryConverter.adjust_converted_html(options, html)
      response = CanvasInterface.create_lesson(options, name, html)
      RepositoryInterface.local_repo_post_submission(options, response)
      puts "Canvas lesson created. Lesson available at #{response['html_url']}"
    when 'align' # used with a local repo
      html = RepositoryConverter.local_file_conversion(options)
      name = RepositoryInterface.get_name(options[:filepath], html)
      html = RepositoryConverter.adjust_converted_html(options, html)
      CanvasInterface.update_all_related_lessons(options, name, html)
      
    when 'github_create'
      html = RepositoryConverter.remote_file_conversion(options)
      name = RepositoryInterface.get_name(options[:filepath], html)
      html = RepositoryConverter.adjust_converted_html(options, html)
      
      response = CanvasInterface.create_lesson(options, name, html)
      
      puts "Canvas lesson created. Lesson available at #{response['html_url']}"
    when 'github_align'
      html = RepositoryConverter.remote_file_conversion(options)
      name = RepositoryInterface.get_name(options[:filepath], html)
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
    else
      puts VERSION
    end
  end
  
end