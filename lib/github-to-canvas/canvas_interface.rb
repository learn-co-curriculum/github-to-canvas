require 'json'
require 'rest-client'
require 'byebug'
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
    url = "#{ENV['CANVAS_API_PATH']}/courses/#{course_id}/#{type}s"
    payload = self.build_payload(type, name, new_readme)

    RestClient.post(url, payload, headers={
      "Authorization" => "Bearer #{ENV['CANVAS_API_KEY']}"
    })
  end

  def self.update_existing_lesson(course_id, id, type, name, new_readme, dry_run)
    url = "#{ENV['CANVAS_API_PATH']}/courses/#{course_id}/#{type}s/#{id}"
    payload = self.build_payload(type, name, new_readme)
    RestClient.put(url, payload, headers={
      "Authorization" => "Bearer #{ENV['CANVAS_API_KEY']}"
    })
  end

  def self.build_payload(type, name, new_readme)
    if type == "assignment"
      payload = {
        'assignment[name]' => name,
        'assignment[description]' => new_readme
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