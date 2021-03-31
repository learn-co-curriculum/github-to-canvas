require 'json'
require 'rest-client'
class GithubInterface

  def self.cd_into_and(filepath, command)
    cmd = "cd #{filepath} && #{command}"
    puts cmd
    `#{cmd}`
  end

  def self.get_updated_repo(filepath, branch)
   self.git_co_branch(filepath, branch)
   self.git_pull(filepath, branch)
  end

  def self.get_current_branch(filepath)
    self.cd_into_and(filepath, "git rev-parse --abbrev-ref HEAD")
  end

  def self.git_co_branch(filepath, branch)
    self.cd_into_and(filepath, "git checkout #{branch}")
    current_branch = self.get_current_branch(filepath)
    puts "Current branch #{current_branch.strip}"
    if !current_branch.match(branch)
      puts "#{branch} branch not found. Exiting..."
      abort
    end
  end

  def self.git_pull(filepath, branch)
    self.cd_into_and(filepath, "git pull origin #{branch}")
  end

  def self.git_remote(filepath)
    self.cd_into_and(filepath, "git config --get remote.origin.url")
  end

  def self.git_add(filepath, file)
    self.cd_into_and(filepath, "git add #{file}")
  end

  def self.git_commit(filepath, message)
    self.cd_into_and(filepath, "git commit -m '#{message}'")
  end

  def self.git_push(filepath, branch)
    self.cd_into_and(filepath, "git push origin #{branch}")
  end

  def self.read_remote(url)
    if url.match(/https:\/\/github.com\//)
      url = url.sub(/https:\/\/github.com\//, 'https://raw.githubusercontent.com/')
      url = url.sub(/blob\//, '')
    end
    if !url.end_with?('.md')
      url_fallback = url + '/main/README.md'
      url = url + '/master/README.md'
    end
    begin
      response = RestClient.get(url)
    rescue
      begin
        response = RestClient.get(url_fallback)
        return response.body
      rescue
        puts 'Error reading ' + url
      end
    end
    response.body
  end

  def self.save_to_github(filepath, branch)
    puts 'Adding .canvas file'
    self.git_add(filepath, '.canvas')
    puts 'Commiting .canvas file'
    self.git_commit(filepath, 'AUTO: add .canvas file after migration')
    puts 'Pushing .canvas file'
    self.git_push(filepath, branch)
  end
  
end