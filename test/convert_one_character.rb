BASE_DIR = "#{File.dirname(__FILE__)}/.."
$:.unshift("#{BASE_DIR}/lib")

require 'dnd'

@ddi = DDIWebService.new(:user, :pass)
@ddi.fakeout!

plain_css = File.read("#{BASE_DIR}/includes/mine.css")
template_name = "#{BASE_DIR}/templates/color-ddi.tmpl"
tmpl = File.read(template_name).sub('STYLE', plain_css)
Dir["#{BASE_DIR}/test/*.dnd4e"].each do |fn|
  new_fn = fn.sub('.dnd4e', '.html')
  puts "rm #{new_fn}"
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