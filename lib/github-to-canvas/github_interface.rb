require 'byebug'
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
end