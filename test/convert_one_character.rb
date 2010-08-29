$:.unshift("#{File.dirname(__FILE__)}/../lib")

require 'dnd'

@ddi = DDIWebService.new(:user, :pass)
@ddi.fakeout!

plain_css = File.read("includes/mine.css")
template_name = 'templates/color-ddi.tmpl'
tmpl = File.read(template_name).sub('STYLE', plain_css)
Dir["test/OtherVjorn.dnd4e"].each do |fn|
  puts "Processing: #{fn}"
  c = DNDCharacter.new(fn)
  c.ddi_webservice = @ddi unless @ddi.session == :ignore  
  str = ""
  str += c.to_character_card
  str += c.to_features_card
  str += c.to_skill_card
  str += c.to_power_cards(:dice_js => true)
  str += c.to_item_cards
  str = tmpl.sub('CONTENT', str)
  new_fn = fn.sub('.dnd4e', '.html')
  File.open(new_fn, 'w'){|f| f << str}
  puts "Output: #{new_fn}"
end

puts "Done."