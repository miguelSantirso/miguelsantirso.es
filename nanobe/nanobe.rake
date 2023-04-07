require 'date'
require 'erb'
require 'fileutils'
require 'pathname'
require 'yaml'

# Configure these tasks in rakefile.rb

desc "Refreshes HTML from files in #{$source}"
task :refresh => [:html_refresh, :static_refresh]

desc "Refreshes HTML in #{$output} from templates in #{$source}"
task :html_refresh => [:html_refresh_internal]

desc "Copies the files in #{$static} to #{$output}"
task :static_refresh do
  FileUtils.mkdir_p $output, :verbose => false
  FileUtils.cp_r(Dir.glob("#{$static}/*"), $output)
end

desc "Deploys the public web folder to a server"
task :deploy => [:refresh] do
  port = ask_for_int("Port for SSH?", 22)
  %x(rsync -rlvtgD --chmod=Du=rwx,Dg=rx,Do=rx,Fu=rw,Fg=r,Fo=r --exclude-from deploy_exclude_list.txt -e 'ssh -p #{port}' #{$output}/ #{$remote_user}@#{$remote_hostname}:#{$remote_web_folder})
end


def compile_erb (erb, data, html)
  FileUtils.mkdir_p(File.dirname(html), :verbose => false)

  data = NanobeErbBridge.new(data)
  output_str = data.render_erb(erb)
  File.write(html, output_str)
end


def convert_markdown_blocks yml_str
  # description: |
  # This is a markdown paragraph
  # without proper tabulation
  # ||||
  #
  # Will be converted to:
  #
  # description: |
  #     This is a markdown paragraph
  #     without proper tabulation

  yml_str.gsub!(/: \|\r?\n([\s\S]*?)\n(\|{2,})/) do |l|
    # Use the ending mark (||||) to know how much we need to indent the block
    matches = [$1, $2]
    matches[1].gsub!('|', ' ')
    # Prepend the required indentation to the start of all lines
    ": |\n#{matches[0].gsub(/^/, matches[1])}"
  end
  return yml_str
end


def load_yml yml_path
  yml_str = File.read(yml_path).force_encoding("UTF-8")
  yml_str = convert_markdown_blocks(yml_str)
  return YAML.load(yml_str, permitted_classes: [Date])
end


def template_path root_path, file_path, given_filename
  path = '' << (given_filename.start_with?('/') ? root_path : File.dirname(file_path))
  path << '/' unless path.end_with?('/')
  path << given_filename << '.erb'
end


# In this case ising rake's automatic file dependencies
# was more complex than the manual alternative
task :html_refresh_internal do
  FileList.new("#{$source}/**/*.yml").each do |yml_file|
    yml = load_yml(yml_file)

    sources = [yml_file]
    erb = ''

    nb_path_keys = ['nb_layout', 'nb_template']
    nb_path_keys.each do |pk|
      next unless yml.key?(pk)
      erb = yml[pk] = template_path($source, yml_file, yml[pk])
      sources << erb
    end

    next if erb == ''

    html = yml_file.gsub('.yml', '.html') # source/index.yml -> source/index.html
    html[$source] = $output # source/index.html -> output/index.html

    if !file_isuptodate?(html, sources) then
      puts "erb #{File.basename(yml_file)} + #{File.basename(erb)} = #{File.basename(html)}"
      compile_erb(erb, yml, html)
    end
  end
end
