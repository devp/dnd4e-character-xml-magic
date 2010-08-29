BASE_DIR = "#{File.dirname(__FILE__)}/.."
$:.unshift("#{BASE_DIR}/lib")
require 'dnd'

@ddi = DDIWebService.new(:user, :pass)
@ddi.fakeout!

template_name = "#{BASE_DIR}/templates/color-ddi.tmpl"
path_to_includes = '../includes' # work for local viewing
tmpl = File.read(template_name).gsub('PATH_TO_INCLUDES', path_to_includes)

Dir["#{BASE_DIR}/test/*.dnd4e"].each do |fn|
  new_fn = fn.sub('.dnd4e', '.html')
  puts `rm #{new_fn}`

  puts "Processing: #{fn}"
  c = DNDCharacter.new(fn)
  c.ddi_webservice = @ddi unless @ddi.session == :ignore  
  str = ""
  str += c.to_character_card
  str += c.to_skill_card
  str += c.to_features_card
  str += c.to_power_cards(:dice_js => true)
  str += c.to_item_cards
  str = tmpl.sub('CONTENT', str)

  File.open(new_fn, 'w'){|f| f << str}
  puts "Output: #{new_fn}"
end

puts "Done."