class Power
  attr_accessor :name, :kind, :url, :weapon_name, :attack_bonus, :vs_defense, :damage_roll, :damage_type
  
  def initialize(h={})
    [:name, :kind, :url, :weapon_name, :attack_bonus, :vs_defense, :damage_roll, :damage_type].each do |sym|      
      self.send("#{sym.to_s}=", h[sym]) if h[sym]
    end
  end
  
  def stats_string
    if self.attack_bonus
      "[%s] +%s vs %s; %s %s damage" % [self.weapon_name, self.attack_bonus, self.vs_defense, self.damage_type, self.damage_type]
    end
  end
  
  def self.second_wind(options = {})
    if options[:dwarf]
      Power.new(:name => "Second Wind", :kind => "Encounter Minor Action")
    else
      Power.new(:name => "Second Wind", :kind => "Encounter Standard Action")
    end
  end
  
  def self.action_point
    Power.new(:name => "Action Point", :kind => "Encounter Free Action")
  end
end