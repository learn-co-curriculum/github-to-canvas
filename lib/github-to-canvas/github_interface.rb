class GithubInterface

  def self.cd_into_and(filepath, command)
    cmd = "cd #{filepath} && #{command}"
    puts cmd
    `#{cmd}`
  end

  def self.git_co_branch(filepath, branch)
    branch = self.cd_into_and(filepath, "git co #{branch}")
    if branch.to_s.strip.empty?
      puts "#{branch} branch not found. Exiting..."
      abort
    end
  end

  def self.git_pull(filepath, branch)
    puts "git pulling latest version of #{branch}"
    self.cd_into_and(filepath, "git pull origin #{branch}")
  end

  def self.git_remote(filepath)
    puts "getting remote URL"
    self.cd_into_and(filepath, "git config --get remote.origin.url")
  end

  def self.git_add(filepath, file)
    puts "git adding #{file}"
    self.cd_into_and(filepath, "git add #{file}")
  end

  def self.git_commit(filepath, message)
    puts "git commit: '#{message}'"
    self.cd_into_and(filepath, "git commit -m '#{message}'")
  end

  def self.git_push(filepath, branch)
    puts "git pushing #{branch}"
    self.cd_into_and(filepath, "git push origin #{branch}")
  end
end