require 'redcarpet'
class RepositoryConverter

  def self.convert(filepath, readme, branch, remove_header_and_footer)
    if remove_header_and_footer
      readme = self.remove_header(readme)
      readme = self.remove_footer(readme)
    end
    self.fix_local_images(filepath, readme, branch)
    self.convert_to_html(filepath, readme)
  end

  def self.remove_header(readme)
    readme.gsub!(/^# .+?\n\n/,"")
    readme.gsub(/^# .+?\n/,"")
  end

  def self.remove_footer(readme)
    readme.gsub(/<p (.+?)<\/p>/,"")
  end

  def self.fix_local_images(filepath, readme, branch)
    raw_remote_url = self.set_raw_image_remote_url(filepath)
    self.adjust_local_markdown_images(readme, raw_remote_url, branch)
    self.adjust_local_html_images(readme, raw_remote_url)
  end

  def self.set_raw_image_remote_url(filepath)
    remote = GithubInterface.git_remote(filepath)
    remote.gsub!("git@github.com:","https://raw.githubusercontent.com/")
    remote.gsub!("https://github.com/","https://raw.githubusercontent.com/")
    remote.gsub!(/.git$/,"")
    remote.strip!
  end

  def self.get_repo_url(filepath)
    remote = GithubInterface.git_remote(filepath)
    remote.gsub!("git@github.com:","https://github.com/")
    remote.gsub!(/.git$/,"")
    remote.strip!
  end

  def self.adjust_local_markdown_images(readme, raw_remote_url, branch)
    readme.gsub!(/\!\[.+\]\(.+\)/) {|image_markdown|
      if !image_markdown.match?('amazonaws.com') && !image_markdown.match?('https://') && !image_markdown.match?('http://') && !image_markdown.match?('youtube')
        image_markdown.gsub!(/\(.+\)/) { |path|
          path.delete_prefix!("(")
          path.delete_suffix!(")")
          "(" + raw_remote_url + "/#{branch}/" + path + ")"
        }
      end
      image_markdown
    }
  end

  def self.adjust_local_html_images(readme, raw_remote_url)
    readme.gsub!(/src=(\'|\")[\s\S]*?(\'|\")/) { |image_source|
      if !image_source.match?('amazonaws.com') && !image_source.match?('https://') && !image_source.match?('http://') && !image_source.match?('youtube')
        image_source.gsub!(/(\'|\")/, "")
        image_source.gsub!(/src=/, '')
        image_source.strip!
        'src="' + raw_remote_url + '/master/' + image_source + '"'
      else
        image_source
      end
    }
  end

  def self.convert_to_html(filepath, readme)
    redcarpet = Redcarpet::Markdown.new(Redcarpet::Render::HTML, options={tables: true, autolink: true, fenced_code_blocks: true})
    # File.write("#{filepath}/README.html", redcarpet.render(readme))
    redcarpet.render(readme)
  end

  def self.add_fis_links(filepath, readme, forkable)
    repo_path = self.get_repo_url(filepath)
    repo_name = repo_path.split('/')[-1]
    repo_org = repo_path.split('/')[-2]

    header = self.create_github_link_header(repo_path, forkable)
    data_element = self.create_data_element(repo_org, repo_name)
    data_element + header + readme
  end

  def self.create_github_link_header(repo_path, forkable)
    # add link to associated repository
    github_repo_link = "<a class='fis-git-link' href='#{repo_path}' target='_blank' rel='noopener'><img id='repo-img' title='Open GitHub Repo' alt='GitHub Repo' /></a>"
    
    # add link to new issue form
    github_issue_link = "<a class='fis-git-link' href='#{repo_path}/issues/new' target='_blank' rel='noopener'><img id='issue-img' title='Create New Issue' alt='Create New Issue' /></a>"
    
    # add link to fork (forking handled by separate Flatiron server, generation of link handled via custom Canvas JS theme file)
    if (forkable)
      github_fork_link = "<a class='fis-fork-link' id='fork-link' href='#' target='_blank' rel='noopener'><img id='fork-img' title='Fork This Assignment' alt='Fork This Assignment' /></a>"
      "<header class='fis-header' style='visibility: hidden;'>#{github_fork_link}#{github_repo_link}#{github_issue_link}</header>"
    else
      "<header class='fis-header' style='visibility: hidden;'>#{github_repo_link}#{github_issue_link}</header>"
    end
  end

  def self.create_data_element(repo_org, repo_name)
    "<div id='git-data-element' data-org='#{repo_org}' data-repo='#{repo_name}'></div>"
  end

end