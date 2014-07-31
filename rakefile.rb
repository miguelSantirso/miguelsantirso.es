
require 'mustache'
require 'highline/import'
require 'yaml'

$source = './source'
$static = './htdocs_static'
$output = './htdocs'

$remote_web_folder = '/home/miguelsantirso/miguelsantirso.es'
$remote_hostname = 'pncil.com'
$remote_user = 'miguelsantirso'


desc "Refreshes both HTML and CSS from files in #{$source}"
task :refresh => [:html_refresh, :css_refresh]

desc "Refreshes HTML in #{$output} from templates in #{$source}"
task :html_refresh

desc "Refreshes CSS in #{$output} from SCSS in #{$source}"
task :css_refresh


desc "Deploys the public web folder to a server"
task :deploy => [:refresh] do
  
  mkdir_p $output, :verbose => false
  FileUtils.cp_r(Dir.glob("#{$static}/*"), $output)
  
  %x(rsync -r -a -v --exclude-from deploy_exclude_list.txt -e ssh #{$output}/ #{$remote_user}@#{$remote_hostname}:#{$remote_web_folder})
end



# Dynamically build the html -> [mustache, yml] dependecies
FileList.new("#{$source}/*.mustache").each do |mustache|
  
  yml = mustache.gsub('.mustache', '.yml') # source/index.mustache -> source/index.yml
  html = mustache.gsub('.mustache', '.html') # source/index.mustache -> source/index.html
  html[$source] = $output # source/index.html -> htdocs/index.html
  
  file html => [mustache, yml] do
    compile_mustache mustache, yml, html
  end
  
  task :html_refresh => html
end

# Dynamically build the css -> [scss] dependecies
FileList.new("#{$source}/*.scss").each do |scss|
  
  css = scss.gsub('.scss', '.css') # source/main.scss -> source/main.css
  css[$source] = $output # source/main.css -> htdocs/main.css
  
  file css => [scss] do
    compile_scss scss, css
  end
  
  task :css_refresh => css
end


private


def compile_mustache (mustache, yml, html)
  
  puts "mustache #{File.basename(yml)} #{File.basename(mustache)} > #{File.basename(html)}"
  mkdir_p File.dirname(html), :verbose => false
  
  data = YAML.load_file(yml)
  data['dynamic'] = {
    'age' => age_in_completed_years(Time.new(1986, 12, 2), Time.now()),
    'last_updated' => Time.now().strftime("%B %e, %Y")
  }
  
  File.write(html, Mustache.render(File.read(mustache), data))
  
end


def compile_scss (scss, css)
  
  puts "sass style.scss style.css"
  %x(sass #{scss} #{css} --scss --no-cache --style compressed)
  
end


def age_in_completed_years (bd, d)
    # Difference in years, less one if you have not had a birthday this year.
    a = d.year - bd.year
    a = a - 1 if (
         bd.month >  d.month or 
        (bd.month >= d.month and bd.day > d.day)
    )
    a
end
