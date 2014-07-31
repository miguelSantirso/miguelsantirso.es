
require 'mustache'
require 'highline/import'
require 'yaml'

$source = './source'
$output = './htdocs'

desc "Refreshes HTML in #{$output} from templates in #{$source}"
task :html_refresh


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


def age_in_completed_years (bd, d)
    # Difference in years, less one if you have not had a birthday this year.
    a = d.year - bd.year
    a = a - 1 if (
         bd.month >  d.month or 
        (bd.month >= d.month and bd.day > d.day)
    )
    a
end
