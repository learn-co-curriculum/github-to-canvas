require 'redcarpet'

class RepositoryConverter

  def self.convert(filepath, readme, branch)
    self.fix_local_images(filepath, readme, branch)
    self.convert_to_html(filepath, readme)
  end

  def self.fix_local_images(filepath, readme, branch)
    raw_remote_url = self.set_raw_image_remote_url(filepath)
    self.adjust_local_markdown_images(readme, raw_remote_url, branch)
    self.adjust_local_html_images(readme, raw_remote_url)
  end

  def self.set_raw_image_remote_url(filepath)
    remote = GithubInterface.git_remote(filepath)
    remote.gsub!("git@github.com:","https://raw.githubusercontent.com/")
    remote.gsub!(/.git$/,"")
    remote.strip!
  end

  def self.adjust_local_markdown_images(readme, raw_remote_url, branch)
    readme.gsub!(/\!\[.+\]\(.+\)/) {|image|
      if !image.match('amazonaws.com') && !image.match('https://') && !image.match('youtube')
        image.gsub!(/\(.+\)/) { |path|
          path.delete_prefix!("(")
          path.delete_suffix!(")")
          "(" + remote + "/#{branch}/" + path + ")"
        }
      end
      image
    }
  end

  def self.adjust_local_html_images(readme, raw_remote_url)
    readme.gsub!(/src=\"[\s\S]*?" /) { |img|
      if !image.match('amazonaws.com') && !image.match('https://') && !image.match('youtube')
        img.gsub!(/\"/, "")
        img.gsub!(/src=/, '')
        img.strip!
      end
      'src="' + raw_remote_url + '/master/' + img + '"'
    }
  end

  def self.convert_to_html(filepath, readme)
    redcarpet = Redcarpet::Markdown.new(Redcarpet::Render::HTML, options={tables: true, autolink: true, fenced_code_blocks: true})
    # File.write("#{filepath}/README.html", redcarpet.render(readme))
    redcarpet.render(readme)
  end

end