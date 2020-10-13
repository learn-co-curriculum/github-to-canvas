class RepositoryInterface

  def self.local_repo_post_submission(options, response)
    # Updates or creates a local .canvas file
    CanvasDotfile.update_or_create(options, response) 

    # If --save option is used, the .canvas file gets committed and pushed to the remote repo
    if options[:save_to_github]
      self.save_to_github(options[:filepath], options[:branch])
    end
  end

  def self.get_name(filepath, html)
    repo_info = RepositoryConverter.get_repo_info(filepath)
    name = html[/<h1>.*<\/h1>/]
    if name
      name = name.sub('<h1>','').sub('</h1>','') 
    else
      name = repo_info[:repo_name].split(/[- _]/).map(&:capitalize).join(' ')
    end
    name
  end

  def self.read_local_file(filepath, file_to_convert)
    begin
      markdown = File.read("#{filepath}/#{file_to_convert}")
    rescue
      puts "#{file_to_convert} not found in current directory. Exiting..."
      abort
    end
    markdown
  end
end