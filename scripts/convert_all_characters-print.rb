BASE_DIR = "#{File.dirname(__FILE__)}/.."
$:.unshift("#{BASE_DIR}/lib")
require 'dnd'

if ARGV.count == 2
  puts "Logging into DDI as #{ARGV[0]}..."
  puts
  @ddi = DDIWebService.new(ARGV[0], ARGV[1])
  @ddi.login!
else
  puts "To access actual DDI:"
  puts "dnd_convert.rb username password"
  puts
  @ddi = DDIWebService.new(nil, nil)
  @ddi.fakeout!
end

template_name = "#{BASE_DIR}/templates/print-bw.tmpl"
path_to_includes = '../../includes' # works for local viewing
tmpl = File.read(template_name).gsub('PATH_TO_INCLUDES', path_to_includes)

Dir["#{BASE_DIR}/scripts/input/*.dnd4e"].each do |fn|
  puts "Processing: #{fn}"

  c = DNDCharacter.new(fn)
  c.ddi_webservice = @ddi unless @ddi.session == :ignore  
  str = ""
  str += c.to_character_card
  str += c.to_features_card
  str += c.to_skill_card
  str += c.to_power_cards(:dice_js => false)
  str += c.to_item_cards
  str = tmpl.sub('CONTENT', str)

  new_fn = fn.sub('input','output').sub('.dnd4e', '.html')
  File.open(new_fn, 'w'){|f| f << str}
  puts "Output: #{new_fn}"
end

puts "Done."