require 'erb'
require 'yaml'
require 'kramdown'
require 'pathname'

$source = './source'
$static = './source_static'
$output = './output'

$remote_web_folder = '/var/www/miguelsantirso.es/public_html'
$remote_hostname = 'miguelsantirso.es'
$remote_user = 'miguel'


# Do not remove
Dir.glob("nanobe/*.rake").each { |r| import r }
