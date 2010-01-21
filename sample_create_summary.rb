require 'ddi_webservice'
require 'character'

str = ""
Dir["*.dnd4e"].each do |fn|
  puts "Processing: #{fn}"
  c = DNDCharacter.new(fn)
  str += c.to_character_card
end
str = File.read('output-template.tmpl').sub('CONTENT', str)
File.open('dnd_party.html','w'){|f| f << str}
puts "Output to dnd_party.html"