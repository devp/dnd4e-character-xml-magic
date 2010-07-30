require 'rubygems'
require 'andand'
require 'nokogiri'
require 'ddi_webservice'

# monkey patch to save me some time here
class Nokogiri::XML::Element
  def css_clean_first(selector)
    css(selector).andand.first.andand.content.andand.strip
  end
  
  def css_clean_all(selector)
    css(selector).map{|x| x.andand.content.andand.strip}
  end
end

class DNDCharacter
  attr_accessor :doc
  attr_accessor :name, :job, :hp, :surges, :initiative, :speed, :ac, :fortitude, :reflex, :will, :passive_perception, :passive_insight
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
      
      @str = get_value_as_stat_or_alias("Strength")
      
      @con = get_value_as_stat_or_alias("Constitution")
      @dex = get_value_as_stat_or_alias("Dexterity")
      @int = get_value_as_stat_or_alias("Intelligence")
      @wis = get_value_as_stat_or_alias("Wisdom")
      @chr = get_value_as_stat_or_alias("Charisma")
      @str_mod = get_value_as_stat_or_alias("Strength modifier")
      @con_mod = get_value_as_stat_or_alias("Constitution modifier")
      @dex_mod = get_value_as_stat_or_alias("Dexterity modifier")
      @int_mod = get_value_as_stat_or_alias("Intelligence modifier")
      @wis_mod = get_value_as_stat_or_alias("Wisdom modifier")
      @chr_mod = get_value_as_stat_or_alias("Charisma modifier")
      
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
      doc.css('Power').each do |el|
        power_name = el.attributes['name'].value
        power_kind = el.css_clean_all('specific').join(" ")

        weapon = el.css('Weapon').sort_by{|w| w.css_clean_first('AttackBonus').to_i}.last # best weapon
        stats = if weapon
          "[%s] +%s vs %s; %s %s damage" % [weapon.attributes['name'].value, weapon.css_clean_first('AttackBonus'), weapon.css_clean_first('Defense'), weapon.css_clean_first('Damage'), weapon.css_clean_all('DamageType').join(" ")]
        else
          nil
        end

        # sometimes multiple elements exist
        rules_urls = doc.css('RulesElement[name="'+power_name+'"]').map{|x| x.attributes['url'].andand.value}
        rules_urls += el.css('RulesElement').map{|x| x.attributes['url'].andand.value}
        rules_url = rules_urls.compact.uniq.first

        @powers << {:name => power_name, :kind => power_kind, :url => rules_url, :stats => stats}
      end
      
    end
  end
  
  def get_value_as_stat_or_alias(name)
    el = doc.search("Stat[name=\"#{name}\"]").first
    el ||= doc.search("Stat[name=\"#{name.downcase}\"]").first
    el ||= doc.search("alias[name=\"#{name}\"]").first.parent
    el ||= doc.search("alias[name=\"#{name.downcase}\"]").first.parent
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
    <h1 class="player"> #{self.name} (#{self.job}) </h1>
    <p class="flavor">
    <b>Initiative</b> +#{self.initiative} &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
    <b>Senses</b> Passive Perception #{self.passive_perception}; Passive Insight #{self.passive_insight}
    <b>Speed</b> #{self.speed}
    <br/>
    <b>AC</b> #{self.ac}; <b>Fortitude</b> #{self.fortitude}, <b>Reflex</b> #{self.reflex}, <b>Will</b> #{self.will}<br/>
    <b>HP</b> #{self.hp}
    <em>Bloodied</em> #{self.hp / 2}
    <b>Surges/Day</b> #{self.surges}
    <em>Surge Value</em> #{self.hp / 4}
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
    #{self.features.map{|sk| "<b>%s</b> %s<br/>" % sk}.join(" ")}
    </p>
    <p></p>
    CARD
  end
      
  def to_item_cards
    magic_items.map do |p|
      h1 = "<h1 class='magicitem'>#{p[:name]}</h1>"

      if p[:url] && @ddi_webservice
        el = @ddi_webservice.get_detail(p[:url])
        el.css('h1').first.replace( Nokogiri::HTML.fragment(h1) )
        el.inner_html
      else
        h1 + ("<a href=\"%s\">%s</a>" % [p[:url], p[:url]])
      end
    end.join("<br/>")
  end

  def to_power_cards(options={})
    options.merge(:action_point => false, :second_wind => false)

    powers_with_ap_and_wind = powers
    if options[:second_wind]
      if @job =~ /dwarf/i
        powers_with_ap_and_wind << {:name => "Second Wind", :kind => "Encounter Minor Action", :stats => ""}
      else
        powers_with_ap_and_wind << {:name => "Second Wind", :kind => "Encounter Standard Action", :stats => ""}
      end
    end
    if options[:action_point]
      powers_with_ap_and_wind << {:name => "Action Point", :kind => "Encounter Free Action", :stats => ""}
    end
    
    powers_with_ap_and_wind.map do |p|
      if p[:kind] =~ /daily/i
        h1class = 'dailypower'
      elsif p[:kind] =~ /encounter/i
        h1class = 'encounterpower'
      else
        h1class = 'atwillpower'
      end      
      h1 = "<h1 class='#{h1class}'>#{p[:name]} <span class=smaller>(#{p[:kind]}) #{p[:stats]}</span></h1>"

      if p[:name] =~ /(Melee|Ranged) Basic Attack/
        h1
      elsif (p[:url] && @ddi_webservice)
        el = @ddi_webservice.get_detail(p[:url])
        el.css('h1').first.replace( Nokogiri::HTML.fragment(h1) )
        el.inner_html
      else
        h1 + "<a href=\"%s\">%s</a>" % [p[:url], p[:url]]
      end
    end.join("<br/>")
  end
end
