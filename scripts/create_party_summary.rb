BASE_DIR = "#{File.dirname(__FILE__)}/.."
$:.unshift("#{BASE_DIR}/lib")
require 'dnd'

template_name = "#{BASE_DIR}/templates/color-ddi.tmpl"
path_to_includes = '../../includes' # works for local viewing
tmpl = File.read(template_name).gsub('PATH_TO_INCLUDES', path_to_includes)

str = ""
Dir["#{BASE_DIR}/scripts/input/*.dnd4e"].each do |fn|
  puts "Processing: #{fn}"
  c = DNDCharacter.new(fn)
  str += c.to_character_card
end

str = tmpl.sub('CONTENT', str)
new_fn = "#{BASE_DIR}/scripts/output/dnd_party.html"
File.open(new_fn,'w'){|f| f << str}
puts "Output to #{new_fn}"

puts "Done."