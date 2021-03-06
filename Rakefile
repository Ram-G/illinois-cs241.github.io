# Including only the changed build task
require 'rake'
require 'jekyll'
require 'html-proofer'
require 'nokogiri'
require 'open-uri'
require 'json'
require 'optparse'
require 'jemoji'
require 'rake'
require 'pigments'
require 'htmlentities'
require_relative '_scripts/spell_check.rb'
require 'etc'
require 'yaml'
require 'fileutils'

is_travis = ENV['TRAVIS'] == 'true'
main_json_file = '_data/man.json'
coursebook_dir = '_coursebook'

$config = Jekyll.configuration({
:source => './',
:destination => './_site',
:timezone => 'America/Chicago',
:safe => false,
})

multitask default: [
  'pre_build:gen_man',
  'pre_build:gen_coursebook',
] do
  site = Jekyll::Site.new($config)
  Jekyll::Commands::Build.build site, $config
  cp './.travis.yml', './_site/.travis.yml'
  cp './CNAME', './_site/CNAME'
end

multitask serve: [
  'default',
] do
  site = Jekyll::Site.new($config)
  Jekyll::Commands::Serve.process $config
end


namespace :pre_build do
  desc 'Houses all pre build tasks'

  sections = [1, 2, 3, 4]
  base_uri = 'https://linux.die.net/man/'
  cache_time = 30 # days

  task :gen_man, [:file] do |_t, args|
    file = args[:file]
    if file.nil?
      file = main_json_file
      puts "Using default file #{file}"
    end

    # Man pages don't change that often
    if File.exist?(file) && ((File.mtime(file) <=> DateTime.now - cache_time) == 1)
      puts 'Using cached file'
      next
    end
    puts 'Updating file'

    urls = sections.map do |e|
      base_uri + e.to_s + '/'
    end
    output = {}
    urls.each do |url|
      page = Nokogiri::HTML(open(url))
      page.css('dt a').each do |link|
        output[link.inner_html] = url + link['href']
      end
    end

    file_opts = File::RDWR | File::CREAT
    File.open(file, file_opts, 0o644) do |f|
      f.truncate 0
      f.write(JSON.fast_generate(output))
      puts "Successfully wrote #{file}"
    end
  end

  def title_from_html(text)
    file_no_ext = File.basename(text, '.md')
    file_no_ext.tr('-', ' ')
  end

  def link_patterns(file, pattern_map)
    f = File.open(file, 'r')
    contents = f.read
    f.close
    new_contents = contents
    pattern_map.each do |link, pattern|
       new_contents = new_contents.gsub(pattern, link)
    end

    f = File.open(file, File::RDWR)
    f.seek(0)
    f.write(new_contents)
    f.close
  end

  def prepend(file, string)
    obj_file = Tempfile.new('')
    f = File.open(file, 'r')
    begin
      obj_file.write(string)
      obj_file.write(f.read)
      f.close
      obj_file.close
      FileUtils.cp(obj_file.path, file)
    ensure
      obj_file.unlink
    end
  end

  coursebook_dir = "_coursebook"
  task :gen_coursebook, [:folder] do |_t, args|
    folder = args[:folder]
    if folder.nil?
      folder = coursebook_dir
      puts "Using default Folder #{folder}"
    end

    system "cd #{coursebook_dir} && git clean -fq && git reset --hard HEAD"

    Dir.glob("#{coursebook_dir}/*md").each do |file|
      file_contents = File.read(file)
      matches = file_contents.match(/(.*)\n={3,}/)
      if matches
        page_title = matches.captures[0]
      else
        page_title = File.basename(file, '.md')
      end
      meta = {
        'layout' => 'doc',
        'title' => page_title,
        'toc' => false,
      }
      prepend(file, "#{meta.to_yaml}\n---\n\n")
    end
    FileUtils.mv("#{coursebook_dir}/Home.md", "#{coursebook_dir}/index.md")
  end
end

task :test_html do
  Dir.mktmpdir do |dir|
    to_copy = Dir.glob('_site/*html')
    to_copy += ['images', './images', '_site/js', '_site/css', '_site/resources', '_site/slides/']
    FileUtils.cp_r(to_copy, dir)
    options = {
      assume_extension: true,
      allow_hash_href: true,
      href_ignore: [
        '#',
        '?'
      ],
      http_status_ignore: [0],
      url_ignore: [/https:\/\/github.com\/angrave\/SystemProgramming\/wiki\//, /coursebook/],
      parallel: { in_processes: 3 }
    }
    HTMLProofer.check_directory(dir, options).run
  end
end

task :spell_check do
  md_files = Dir.glob('*.md')
  md_files += Dir.glob('_docs/*.md')

  open_dictionaries do |dicts|
    Parallel.map(md_files, in_threads: Etc.nprocessors) do |md_file|
      check_spelling(md_file, dicts)
    end
  end
end
