# sorta csv; used for my own purposes

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

Dir["#{BASE_DIR}/scripts/input/*.dnd4e"].each do |fn|
  puts "Processing: #{fn}"

  c = DNDCharacter.new(fn)
  powers = []
  c.powers.each do |p|
    powers << "\"%s\",%s,%s,%s,%s" % [
      p.name, p.attack_bonus, p.vs_defense,
      p.damage_roll, p.damage_type
    ]
  end
  powers = powers.join("\n")

  new_fn = fn.sub('input','output').sub('.dnd4e', '.csv')
  File.open(new_fn, 'w'){|f| f << powers}
  puts "Output: #{new_fn}"
end

puts "Done."