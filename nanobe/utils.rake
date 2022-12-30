require 'redcarpet'

# Used to communicate with the ERB templates
class NanobeErbBridge

  def initialize(hash)
    hash.each do |key, value|
      instance_variable_set "@#{key}", value
    end
  end

  def get_binding
    binding
  end

  def md(text)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, extensions = {})
    markdown.render(text)
  end

  def p(path)
    pathname = Pathname.new("#{$source}/#{path}")
    layout_pathname = Pathname.new(File.dirname(@nb_layout))
    pathname.relative_path_from(layout_pathname)
  end

  def render_erb(path)
    content = File.read(File.expand_path(path)).force_encoding("UTF-8")
    t = ERB.new(content, trim_mode:'>')
    t.result(binding)
  end

end

def file_isuptodate?(new, old_list, options = nil)
  raise ArgumentError, 'file_isuptodate? does not accept any option' if options

  return false unless File.exist?(new)
  new_time = File.mtime(new)
  old_list.each do |old|
    if File.exist?(old)
      return false unless new_time > File.mtime(old)
    end
  end
  true
end

def ask_for_int(question, default)
  print("#{question} (default: #{default}) ")
  STDOUT.flush
  return Integer($stdin.gets) rescue default
end
