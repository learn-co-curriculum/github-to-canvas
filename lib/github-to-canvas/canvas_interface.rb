require 'json'
require 'rest-client'
require 'byebug'
class CanvasInterface

  def self.submit_to_canvas(course, type, name, readme, dry_run = false)
    if dry_run
      puts 'DRY RUN: Skipping push to Canvas'
    else
      response = self.push_to_canvas(course, type, name, readme)
      if response.code != 200 || response.code != 201
        byebug
        puts "Canvas push failed. #{response.code} status code returned "
        abort
      end
      JSON.parse(response.body)
    end
  end

  def self.push_to_canvas(course, type, name, readme)
    url = "#{ENV['CANVAS_API_PATH']}/courses/#{course}/#{type}s"
    if type == "assignment"
      payload = {
        'assignment[name]' => name,
        'assignment[description]' => readme
      }
    else
      payload = {
        'wiki_page[title]' => name,
        'wiki_page[body]' => readme,
        'wiki_page[editing_roles]' => "teachers" 
      }
    end

    RestClient.post(url, payload, headers={
      "Authorization" => "Bearer #{ENV['CANVAS_API_KEY']}"
    })
  end

  def self.update_existing_lesson(course_id, page_id, type, name, new_readme, dry_run)
    url = "#{ENV['CANVAS_API_PATH']}/courses/#{course}/#{type}s/#{page_id}"
    RestClient.put(url, payload, headers={
      "Authorization" => "Bearer #{ENV['CANVAS_API_KEY']}"
    })
  end
end