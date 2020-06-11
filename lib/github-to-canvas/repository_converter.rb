require 'redcarpet'
require 'byebug'
class RepositoryConverter

  def self.convert(filepath, readme, branch, remove_header)
    if remove_header
      self.remove_header(readme)
    end
    self.fix_local_images(filepath, readme, branch)
    self.convert_to_html(filepath, readme)
  end

  def self.remove_header(readme)
    readme.gsub!(/^#.+?\n\n/,"")
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
    readme.gsub!(/\!\[.+\]\(.+\)/) {|image|
      if !image.match('amazonaws.com') && !image.match('https://') && !image.match('youtube')
        image.gsub!(/\(.+\)/) { |path|
          path.delete_prefix!("(")
          path.delete_suffix!(")")
          "(" + raw_remote_url + "/#{branch}/" + path + ")"
        }
      end
      image
    }
  end

  def self.adjust_local_html_images(readme, raw_remote_url)
    readme.gsub!(/src=\"[\s\S]*?" /) { |img|
      if !img.match('amazonaws.com') && !img.match('https://') && !img.match('youtube')
        img.gsub!(/\"/, "")
        img.gsub!(/src=/, '')
        img.strip!
        'src="' + raw_remote_url + '/master/' + img + '"'
      else
        img
      end
    }
  end

  def self.convert_to_html(filepath, readme)
    redcarpet = Redcarpet::Markdown.new(Redcarpet::Render::HTML, options={tables: true, autolink: true, fenced_code_blocks: true})
    # File.write("#{filepath}/README.html", redcarpet.render(readme))
    redcarpet.render(readme)
  end

  def self.add_fis_links(filepath, readme)
    repo = self.get_repo_url(filepath)
    github_repo_link = "<a style='text-decoration: none;' href='#{repo}' target='_blank' rel='noopener'><img style='width: 40px; height: 40px; margin: 2px;' title='Open GitHub Repo' src='https://curriculum-content.s3.amazonaws.com/git-logo-gray.png' alt='Link to GitHub Repo' /></a>"
    github_issue_link = "<a style='text-decoration: none;' href='#{repo}/issues/new' target='_blank' rel='noopener'><img style='width: 40px; height: 40px; margin: 2px;' title='Create New Issue' src='https://curriculum-content.s3.amazonaws.com/flag-icon-gray.png' alt='Link to GitHub Repo Issue Form' /></a>"

    html = "<p style='margin: 0; padding: 0; position: absolute; right: 5px; top: 5px; margin: 0; padding: 0;'>#{github_repo_link}#{github_issue_link}</p>"
    
    readme + html
  end

end