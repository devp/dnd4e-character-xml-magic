require 'ddi_webservice'
require 'character'

@ddi = DDIWebService.new(ENV['USERNAME'], ENV['PASSWORD'])
if ENV['USERNAME'].nil?
  puts "To access actual DDI:"
  puts "USERNAME=foo@bar.com PASSWORD=secret ruby dnd_convert.rb"
  puts
  @ddi.fakeout!
else
  puts "Logging into DDI as #{ENV['USERNAME']}..."
  puts
  @ddi.login!
end

puts "Loading *.dnd4e from this directory."

Dir["*.dnd4e"].each do |fn|
  puts "Processing: #{fn}"
  c = DNDCharacter.new(fn)
  c.ddi_webservice = @ddi unless @ddi.session == :ignore  
  str = ""
  str += c.to_character_card
  str += c.to_power_cards
  str += c.to_item_cards
  str += c.to_features_card
  str += c.to_skill_card
  str = File.read('output-template.tmpl').sub('CONTENT', str)
  new_fn = fn.sub('.dnd4e', '.html')
  File.open(new_fn, 'w'){|f| f << str}
  puts "Output: #{new_fn}"
end

puts "Done."