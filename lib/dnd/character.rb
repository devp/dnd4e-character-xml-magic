require 'rubygems'
require 'andand'
require 'nokogiri'

# monkey patch to save me some time here
# FIXME: this is mean and wrong
class ::Nokogiri::XML::Element
  def css_clean_first(selector)
    css(selector).andand.first.andand.content.andand.strip
  end
  
  def css_clean_all(selector)
    css(selector).map{|x| x.andand.content.andand.strip}
  end
end

require 'dnd/ddi_webservice'
require 'dnd/power'

class DNDCharacter
  attr_accessor :doc
  attr_accessor :name, :job, :level, :xp, :gp, :gear
  attr_accessor :hp, :surges, :initiative, :speed, :ac, :fortitude, :reflex, :will, :passive_perception, :passive_insight
  attr_accessor :power_points, :rituals, :backgrounds
  attr_accessor :str, :dex, :con, :wis, :int, :chr
  attr_accessor :str_mod, :dex_mod, :con_mod, :wis_mod, :int_mod, :chr_mod
  attr_accessor :magic_items, :powers, :skills, :features
  attr_accessor :ddi_webservice
    
  def initialize(fn=nil)
    if fn
      @doc = Nokogiri::XML(File.open(fn))
      @name = doc.search('name').first.content.strip
      dnd_class = doc.search('RulesElement[type="Class"]').first.attributes['name'].value
      dnd_race = doc.search('RulesElement[type="Race"]').first.attributes['name'].value
      @job = "#{dnd_race} #{dnd_class}"
      @level = doc.search('Level').first.content.strip
      @xp = doc.search('Experience').first.content.strip
      @gp = doc.search('CarriedMoney').first.content.strip
      
      @hp = get_value_as_stat_or_alias("Hit Points")
      @surges = get_value_as_stat_or_alias("Healing Surges")
      
      @initiative = get_value_as_stat_or_alias("Initiative")
      @speed = get_value_as_stat_or_alias("Speed")
      
      @ac = get_value_as_stat_or_alias("Armor Class")
      @fortitude = get_value_as_stat_or_alias("Fortitude")
      @reflex = get_value_as_stat_or_alias("Reflex")
      @will = get_value_as_stat_or_alias("Will") 
      
      @passive_perception = get_value_as_stat_or_alias("Passive Perception")
      @passive_insight = get_value_as_stat_or_alias("Passive Insight")
      
      @power_points = get_value_as_stat_or_alias("Power Points", :force_nil_to => 0)
      @rituals = doc.css('loot[count="1"] RulesElement[type="Ritual"]').map{|r| r.attributes["name"].value}.uniq
      @gear = doc.css('loot[count="1"] RulesElement[type="Gear"]').map{|r| r.attributes["name"].value}.uniq  
      @backgrounds = doc.css('RulesElement[type="Background"]').map{|r| r.attributes["name"].value}.uniq
      
      @str = get_value_as_stat_or_alias("Strength")
      @con = get_value_as_stat_or_alias("Constitution")
      @dex = get_value_as_stat_or_alias("Dexterity")
      @int = get_value_as_stat_or_alias("Intelligence")
      @wis = get_value_as_stat_or_alias("Wisdom")
      @chr = get_value_as_stat_or_alias("Charisma")
      @str_mod = get_value_as_stat_or_alias(["Strength modifier", "Strength Modifier"])
      @con_mod = get_value_as_stat_or_alias(["Constitution modifier", "Constitution Modifier"])
      @dex_mod = get_value_as_stat_or_alias(["Dexterity modifier", "Dexterity Modifier"])
      @int_mod = get_value_as_stat_or_alias(["Intelligence modifier", "Intelligence Modifier"])
      @wis_mod = get_value_as_stat_or_alias(["Wisdom modifier", "Wisdom Modifier"])
      @chr_mod = get_value_as_stat_or_alias(["Charisma modifier", "Charisma Modifier"])
      
      #first make a list of possible skills:
      @skills = {}
      skill_list = doc.css('Stat, alias').select{ |el|
        el.attributes['name'].andand.value =~ / Trained/
      }.map{ |el|
        el.attributes['name'].value.split(" ").first
      }
      skill_list.each do |skill|
        @skills[skill] = get_value_as_stat_or_alias(skill)
      end
      
      @features = {}
      doc.css('RulesElement').each do |el|
        if el.attributes['type'].value =~ /Feat/
          name = el.attributes['name'].value
          desc = el.css_clean_first('specific[name="Short Description"]')
          @features[name] = desc if (desc || @features[name].nil?)
        end
      end
      
      @magic_items = []
      doc.css('loot[count!="0"] RulesElement[type="Magic Item"]').map{|i|
        [i.attributes["name"].value, i.attributes["url"].value]
      }.uniq.each do |item|
        @magic_items << {:name => item[0], :url => item[1]}
      end
      
      @powers = []
      doc.css('Power').reject{|r|
        r.attributes['name'].value =~ /Movement Technique/ # blah monks
      }.each do |el|
        power = Power.new
        power.name = el.attributes['name'].value
        power.kind = el.css_clean_all('specific').join(" ")

        weapon = el.css('Weapon').sort_by{|w| w.css_clean_first('AttackBonus').to_i}.last # best weapon
        if weapon
          unless weapon.css_clean_first('AttackStat') == 'Unknown'
            power.weapon_name = weapon.attributes['name'].value
            power.attack_bonus = weapon.css_clean_first('AttackBonus')
            power.vs_defense = weapon.css_clean_first('Defense')
          end
          unless weapon.css_clean_first('Damage').strip == "" || weapon.css_clean_first('Damage').nil?
            power.damage_roll = weapon.css_clean_first('Damage')
            power.damage_type = weapon.css_clean_all('DamageType').join(" ")
          end
        end

        # sometimes multiple elements exist
        rules_urls = doc.css('RulesElement[name="'+power.name+'"]').map{|x| x.attributes['url'].andand.value}
        rules_urls += el.css('RulesElement').map{|x| x.attributes['url'].andand.value}
        power.url = rules_urls.compact.uniq.first
        
        @powers << power
      end
      
    end
  end
  
  def get_value_as_stat_or_alias(names, options = {})
    unless names.is_a?(Array)
      names = [names]
    end

    el = nil
    names.each do |name|
      el ||= doc.search("Stat[name=\"#{name}\"]").first
      el ||= doc.search("Stat[name=\"#{name.downcase}\"]").first
      el ||= doc.search("alias[name=\"#{name}\"]").first.andand.parent
      el ||= doc.search("alias[name=\"#{name.downcase}\"]").first.andand.parent
    end
    if el.nil? && options[:force_nil_to]
      return options[:force_nil_to]
    end
    return nil unless el
    el.attributes['value'].value.to_i
  end
  
  def mod_to_str(mod)
    if mod > 0
      "+#{mod}"
    else
      mod.to_s
    end
  end
  
  def to_character_card
    <<-CARD
    <h1 class="player name"> #{self.name} <span class=smaller>(#{self.job}; Level #{self.level})</span></h1>
    <p class="flavor">
    <b>Initiative</b> +#{self.initiative}
    <b>Senses</b> Passive Perception #{self.passive_perception}; Passive Insight #{self.passive_insight}
    <b>Speed</b> #{self.speed}
    <br/>
    <b>AC</b> #{self.ac}; <b>Fortitude</b> #{self.fortitude}, <b>Reflex</b> #{self.reflex}, <b>Will</b> #{self.will}<br/>
    <b>HP</b> #{self.hp}
    <em>Bloodied</em> #{self.hp / 2}
    <b>Surges/Day</b> #{self.surges}
    <em>Surge Value</em> #{self.hp / 4}
    #{ " <b>Power Points</b> #{self.power_points} " unless self.power_points.zero? }
    <br/>
    <b>STR</b> #{self.str} (#{mod_to_str self.str_mod})
    <b>CON</b> #{self.con} (#{mod_to_str self.con_mod})
    <b>DEX</b> #{self.dex} (#{mod_to_str self.dex_mod})
    <b>WIS</b> #{self.wis} (#{mod_to_str self.wis_mod})
    <b>INT</b> #{self.int} (#{mod_to_str self.int_mod})
    <b>CHR</b> #{self.chr} (#{mod_to_str self.chr_mod})
    </p>
    <p></p>
    CARD
  end
  
  def to_skill_card
    <<-CARD
    <h1 class="player"> Skills </h1>
    <p class="flavor">
    #{self.skills.keys.sort.map{|name| "<b>%s</b> (%s)" % [name, skills[name]]}.join(" ")}
    </p>
    <p></p>
    CARD
  end
  
  def to_features_card
    <<-CARD
    <h1 class="player"> Features and Feats </h1>
    <p class="flavor">
    <b>XP</b> #{self.xp}
    <b>GP</b> #{self.gp}
    #{ " <b>Gear</b> #{self.gear.join(", ")} " unless self.gear.empty? }
    #{self.features.map{|sk| "<b>%s</b> %s<br/>" % sk}.join(" ")}
    #{ " <b>Rituals</b> #{self.rituals.join(", ")} " unless self.rituals.empty? }
    #{ " <b>Backgrounds</b> #{self.backgrounds.join(", ")} " unless self.backgrounds.empty? }
    </p>
    <p></p>
    CARD
  end
      
  def to_item_cards
    magic_items.map do |p|
      h1 = "<h1 class='magicitem'>#{p[:name]}</h1>"

      if p[:url] && @ddi_webservice
        make_shorter_card_html(h1, p[:url])
      else
        h1 + ("<a href=\"%s\">%s</a>" % [p[:url], p[:url]])
      end
    end.join("<br/>")
  end

  def to_power_cards(options={})
    options.merge!(:action_point => false, :second_wind => false, :dice_js => true)

    powers_with_ap_and_wind = powers    
    powers_with_ap_and_wind << Power.second_wind(:dwarf => (@job =~ /dwarf/i)) if options[:second_wind]
    powers_with_ap_and_wind << Power.action_point if options[:action_point]
    
    powers_with_ap_and_wind.map do |p|
      if p.kind =~ /daily/i
        h1class = 'dailypower'
      elsif p.kind =~ /encounter/i
        h1class = 'encounterpower'
      else
        h1class = 'atwillpower'
      end
      
      power_stats = []
      power_stats << "[%s] +%s vs %s" % [p.weapon_name, p.attack_bonus, p.vs_defense] if p.attack_bonus
      power_stats << "%s %s damage" % [p.damage_roll, p.damage_type] if p.damage_roll
      power_stats = power_stats.join("; ")
      dice_js = if options[:dice_js] && p.attack_bonus
        "<button onclick='attack_roll(this)' attackBonus='#{p.attack_bonus}' vsDefense = '#{p.vs_defense}' damageRoll='#{p.damage_roll}' damageType='#{p.damage_type}'><b>Roll Attack!</b></button><button onclick='attack_reset(this)'>reset</button><textarea class=result></textarea>"
      end

      h1 = "<h1 class='#{h1class}'>#{p.name} <span class=smaller>(#{p.kind}) #{power_stats}</span>#{dice_js}</h1>"

      if p.name =~ /(Melee|Ranged) Basic Attack/
        if h1 =~ /Unarmed.*1d4/
          nil
        else
          h1
        end
      elsif (p.url && @ddi_webservice)
        augment_psionic_power_card(make_shorter_card_html(h1, p.url))
      else
        h1 + "<a href=\"%s\">%s</a>" % [p.url, p.url]
      end
    end.join("<br/>")
  end
  
  def make_shorter_card_html(h1, url)
    el = @ddi_webservice.get_detail(url)
    el.css('h1').first.replace( Nokogiri::HTML.fragment(h1) )
    el.css("p.flavor:first").first.andand.remove
    el.css('p').select{|x| x.inner_html =~ /^Published/}.first.andand.remove
    # el.css('br').each{|br| br.replace(" ")}
    el.inner_html
  end
  
  def augment_psionic_power_card(card_html)
    card_html.gsub(/Augment ([0-9]+)/, " <b>Augment \\1</b> ")
  end
end
