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
    readme.gsub(/^# .+?\n\n/,"")
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
    github_repo_link = "<a class='fis-git-link' href='#{repo}' target='_blank' rel='noopener'><img id='repo-img' title='Open GitHub Repo' alt='GitHub Repo' /></a>"
    github_issue_link = "<a class='fis-git-link' href='#{repo}/issues/new' target='_blank' rel='noopener'><img id='issue-img' title='Create New Issue' alt='Create New Issue' /></a>"
    thumbs_up_link = "<img id='thumbs-up' data-repository='#{repo.split('/')[-1]}' title='Thumbs up!' alt='thumbs up' />"
    thumbs_down_link = "<img id='thumbs-down' data-repository='#{repo.split('/')[-1]}' title='Thumbs down!' alt='thumbs down' />"
    feedback_link = "<h5>Have specific feedback? <a href='#{repo}/issues/new'>Tell us here!</a></h5>"
    header = "<header class='fis-header' style='visibility: hidden;'>#{github_repo_link}#{github_issue_link}</header>"
    footer = "<footer class='fis-footer' style='visibility: hidden;'><div class='fis-feedback'><h5>How do you feel about this lesson?</h5>#{thumbs_up_link}#{thumbs_down_link}</div>#{feedback_link}</footer>"
    header + readme + footer
  end

end