require 'json'
require 'rest-client'

class CanvasInterface

  def self.submit_to_canvas(course_id, type, name, readme, dry_run = false)
    if dry_run
      puts 'DRY RUN: Skipping push to Canvas'
    else
      response = self.push_to_canvas(course_id, type, name, readme)
      if ![200, 201].include? response.code
        puts "Canvas push failed. #{response.code} status code returned "
        abort
      end
      JSON.parse(response.body)
    end
  end

  def self.push_to_canvas(course_id, type, name, new_readme)
    if type == 'discussion'
      url = "#{ENV['CANVAS_API_PATH']}/courses/#{course_id}/#{type}_topics"
    else
      url = "#{ENV['CANVAS_API_PATH']}/courses/#{course_id}/#{type}s"
    end
    payload = self.build_payload(type, name, new_readme)
    begin
      RestClient.post(url, payload, headers={
        "Authorization" => "Bearer #{ENV['CANVAS_API_KEY']}"
      })
    rescue
      puts "Something went wrong while pushing lesson #{id} to course #{course_id}"
    end
  end

  def self.update_existing_lesson(course_id, id, type, name, new_readme, dry_run)
    url = "#{ENV['CANVAS_API_PATH']}/courses/#{course_id}/#{type}s/#{id}"
    payload = self.build_payload(type, name, new_readme)
    begin
      RestClient.put(url, payload, headers={
        "Authorization" => "Bearer #{ENV['CANVAS_API_KEY']}"
      })
    rescue
      puts "Something went wrong while pushing lesson #{id} to course #{course_id}"
    end
  end

  def self.build_payload(type, name, new_readme)
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