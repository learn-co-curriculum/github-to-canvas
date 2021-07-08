require 'redcarpet'
class CustomRender < Redcarpet::Render::HTML
  def block_code(code, lang)
    "<pre>" \
      "<code>#{multi_line(code)}</code>" \
    "</pre>"
  end

  def multi_line(code)
    code.gsub(/\n(?=[^.])/, "<br />")
  end
end

class RepositoryConverter
  def self.local_file_conversion(options)
    # GithubInterface.get_updated_repo(options[:filepath], options[:branch])
    markdown = RepositoryInterface.read_local_file(options[:filepath], options[:file_to_convert])
    raw_remote_url = self.set_raw_image_remote_url(options[:filepath])
    markdown = self.escape_existing_html(markdown) if options[:contains_html]
    markdown = self.fix_local_images(options, markdown, raw_remote_url)
    html = self.convert_to_html(markdown)
    # self.fix_local_html_links(options, html, options[:filepath])
  end

  def self.remote_file_conversion(options)
    markdown = GithubInterface.read_remote(options[:filepath])
    raw_remote_url = self.set_raw_image_remote_url(options[:filepath])
    if options[:contains_html]
      begin
        markdown = self.escape_existing_html(markdown)
      rescue
        puts "Error reading remote markdown"
        abort
      end
    end
    if (!options[:branch])
      options[:branch] = 'master'
    end
    markdown = self.fix_local_images(options, markdown, raw_remote_url)
    html = self.convert_to_html(markdown)
    # self.fix_local_html_links(options, html, options[:filepath])
  end

  def self.convert_to_html(markdown)
    renderer = CustomRender.new(escape_html: true, prettify: true, hard_wrap: true)
    redcarpet = Redcarpet::Markdown.new(CustomRender, options={tables: true, autolink: true, fenced_code_blocks: true, disable_indented_code_blocks: true})
    html = redcarpet.render(markdown)
    puts "Markdown converted to HTML"
    self.remove_line_breaks(html)
  end

  def self.adjust_converted_html(options, html)
    if options[:remove_header_and_footer]
      html = self.remove_header_and_footer(html)
    end
    
    if options[:fis_links] || options[:git_links]
      html = self.add_fis_links(options, html)
    end

    if options[:contains_html]
      html = self.fix_escaped_inline_html_code(html)
    end
    html
  end

  def self.fix_escaped_inline_html_code(html)
    
    html
  end

  def self.escape_existing_html(markdown)
    markdown = markdown.gsub(/```(\n|.)*?```/) { |code|
      # all code blocks
      code = code.gsub("<", "&lt;")
      code = code.gsub(">", "&gt;")
    }
    markdown
  end

  def self.remove_header_and_footer(html)
    new_html = self.remove_html_header(html)
    # new_html = self.remove_footer(new_html)
    new_html
  end

  def self.remove_header(readme)
    readme = readme.gsub(/^# .+?\n\n/,"")
    readme.gsub(/^# .+?\n/,"")
  end

  def self.remove_footer(readme)
    readme.gsub(/<p class='util--hide'(.+?)<\/p>/,"")
    readme.gsub(/<p data-visibility='hidden'(.+?)<\/p>/,"")
    readme.gsub(/<p>&lt\;p data-visibility=&#39\;hidden&#39(.+?)<\/p>/,"")
    readme.gsub(/<p>&lt\;p class=&#39;util--hide&#39\;(.+?)<\/p>/,"")
  end

  def self.remove_html_header(html)
    html.gsub(/<h1>.*?<\/h1>/,"")
  end

  def self.fix_local_html_links(options, html, filepath)
    # fixes relative hyperlinks by appending the github path to the file
    filepath_base = filepath.match(/https:\/\/github.com\/.*?\/.*?\//).to_s
    filepath_base = self.get_github_base_url(filepath)
    html.gsub!(/a href="(?!(http|#)).*?"/) {|local_link|
      local_link[8..-2]
    }
  end

  def self.fix_local_images(options, markdown, raw_remote_url)
    # fixes markdown images with relative links by appending the raw githubusercontent path to the file
    self.adjust_local_markdown_images(markdown, raw_remote_url, options[:branch])
    self.adjust_local_html_images(markdown, raw_remote_url, options[:branch])
    markdown
  end

  def self.get_github_base_url(filepath)
    remote = GithubInterface.git_remote(filepath)
    remote.gsub!("git@github.com:","https://github.com/")
    remote.gsub!(/.git$/,"")
    remote.strip! 
  end


  def self.set_raw_image_remote_url(filepath)
    if filepath.include? 'https://github.com/'
      remote = filepath
    else
      remote = GithubInterface.git_remote(filepath)
    end
    raw_remote = remote.gsub("git@github.com:","https://raw.githubusercontent.com/")
    raw_remote = raw_remote.gsub("https://github.com/","https://raw.githubusercontent.com/")
    raw_remote = raw_remote.gsub(/\/blob\/master\/.*$/,"")
    raw_remote = raw_remote.gsub(/\/blob\/main\/.*$/,"")
    raw_remote = raw_remote.gsub(/.git$/,"")
    raw_remote.strip
  end

  def self.get_repo_url(filepath)
    remote = GithubInterface.git_remote(filepath)
    remote.gsub!("git@github.com:","https://github.com/")
    remote.gsub!(/.git$/,"")
    remote.strip!
  end

  def self.adjust_local_markdown_images(readme, raw_remote_url, branch)
    readme.gsub(/\!\[.+\]\(.+\)/) {|image_markdown|
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

  def self.adjust_local_html_images(readme, raw_remote_url, branch)
    readme.gsub(/src=(\'|\")[\s\S]*?(\'|\")/) { |image_source|
      
      if !image_source.match?('amazonaws.com') && !image_source.match?('https://') && !image_source.match?('http://') && !image_source.match?('youtube') && !image_source.match(/src=(\'|\")(?=<%)/)
        image_source = image_source.gsub(/(\'|\")/, "")
        image_source = image_source.gsub(/src=/, '')
        image_source = image_source.strip

        begin
          'src="' + raw_remote_url + '/' + branch + '/' + image_source + '"'
        rescue
          puts "Error adjust HTML images - check images in Canvas"
        end
      else
        image_source
      end
    }
  end

  def self.remove_line_breaks(html)
    html.gsub("\n",' ')
  end

  

  def self.get_repo_info(filepath)
    if !filepath.match?('https://github.com')
      repo_path = self.get_repo_url(filepath)
    else
      repo_path = filepath
    end

    {
      repo_path: repo_path,
      repo_name: repo_path.split('/')[4],
      repo_org: repo_path.split('/')[3]
    }
  end
  
  def self.add_fis_links(options, html)
    repo_info = self.get_repo_info(options[:filepath])
    html = html.sub(/<div id="git-data-element.*<header class="fis-header.*<\/header>/,'') # remove existing fis header
    header = self.create_github_link_header(repo_info[:repo_path], options)
    data_element = self.create_data_element(repo_info[:repo_org], repo_info[:repo_name], options[:aaq], options[:prework])
    data_element + header + html
  end

  def self.create_github_link_header(repo_path, options)
    # add link to associated repository
    github_repo_link = "<a class='fis-git-link' href='#{repo_path}' target='_blank' rel='noopener'><img id='repo-img' title='Open GitHub Repo' alt='GitHub Repo' /></a>"
    
    # add link to new issue form
    github_issue_link = "<a class='fis-git-link' href='#{repo_path}/issues/new' target='_blank' rel='noopener'><img id='issue-img' title='Create New Issue' alt='Create New Issue' /></a>"
    
    # add link to fork (forking handled by separate Flatiron server, generation of link handled via custom Canvas JS theme file)

    if (options[:forkable])
      github_fork_link = "<a class='fis-fork-link' id='fork-link' href='#{repo_path}/fork' target='_blank' rel='noopener'><img id='fork-img' title='Fork This Assignment' alt='Fork This Assignment' /></a>"
      "<header class='fis-header' style='visibility: hidden;'>#{github_fork_link}#{github_repo_link}#{github_issue_link}</header>"
    elsif options[:git_links]
      "<header class='fis-header'>#{github_repo_link}#{github_issue_link}</header>"
    else
      "<header class='fis-header' style='visibility: hidden;'>#{github_repo_link}#{github_issue_link}</header>"
    end
  end

  def self.create_data_element(repo_org, repo_name, aaq, prework)
    "<div id='git-data-element' #{prework ? "data-prework='true'" : ""} #{aaq ? "data-aaq='enabled'" : ""} data-org='#{repo_org}' data-repo='#{repo_name}'></div>"
  end

  
end