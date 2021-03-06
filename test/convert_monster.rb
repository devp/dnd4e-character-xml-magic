BASE_DIR = "#{File.dirname(__FILE__)}/.."
$:.unshift("#{BASE_DIR}/lib")
require 'dnd'

# experimentation for now

template_name = "#{BASE_DIR}/templates/color-ddi.tmpl"
path_to_includes = '../includes' # works for local viewing
tmpl = File.read(template_name).gsub('PATH_TO_INCLUDES', path_to_includes)

Dir["#{BASE_DIR}/test/*.monster"].each do |fn|

  puts "Processing #{fn}"
  puts

  monster = DNDMonster.new(fn)
  
  # simple output
  
  puts monster.name
  puts monster.kind
  puts monster.stats
  puts monster.extra_stats
  
  # monster.powers.each do |p|
  #   puts p.name
  #   puts "  #{p.description}"
  #   puts "  +#{p.attack_bonus}#{p.vs_defense ? " vs #{p.vs_defense}" : nil}" if p.attack_bonus
  #   puts "  #{p.damage_roll}#{p.damage_type ? " #{p.damage_type}" : nil} damage" if p.damage_roll
  # end
  # 
  # puts "=========="
  
  # create html
  
  str = monster.to_html
  str = tmpl.sub('CONTENT', str)
  new_fn = fn.sub('.monster', '.monster.html')
  File.open(new_fn, 'w'){|f| f << str}
  puts "Output: #{new_fn}"
  
  # create csv
  
  new_fn = fn.sub('.monster','.monster.csv')
  str = monster.powers.map do |p|
    "%s,%s,%s,%s,%s" % [
      p.name, p.attack_bonus, p.vs_defense,
      p.damage_roll, p.damage_type
    ]
  end.join("\n")
  File.open(new_fn, 'w'){|f| f << str}
  puts "Output: #{new_fn}"

end