require 'rubygems'
require 'andand'
require 'nokogiri'
# require 'dnd/modify_nokigiri'

require 'dnd/ddi_webservice'
require 'dnd/power'

class DNDMonster
  attr_accessor :doc, :detail
  attr_accessor :name, :kind, :stats, :extra_stats
  attr_accessor :powers

  def initialize(fn=nil)
    if fn
      @doc = Nokogiri::XML(File.open(fn))
      @detail = @doc.css('div#detail').andand.first
      raise "error" unless @detail
      
      within_h1 = detail.css('h1').children()
      @name = within_h1.select{|x| x.text?}.first.text.strip
      @kind = [within_h1.css('span.type').text, within_h1.css('span.level').text].join(" ").strip 
      
      @stats = detail.css('p.flavor').first.inner_html
      @extra_stats = detail.css('p.flavor').last.inner_html           
      
      @powers = []
      
      p1s = detail.css('p.flavor.alt')
      p2s = detail.css('p.flavorIndent')
      0.upto(p1s.size) do |i|
        p1 = p1s[i]
        p2 = p2s[i]
        next unless p1 && p2
        
        p = Power.new
        p.name = p1.css('b').first.text
        p.kind = p1.css('b').first.next().text.strip
        p.description = p2.text.strip
        attack_matches = p.description.match(/\+([0-9]+) +vs +(AC|Fortitude|Reflex|Will)?/)
        p.attack_bonus = attack_matches.andand[1].andand.strip
        p.vs_defense = attack_matches.andand[2].andand.strip
        damage_matches = p.description.match(/([0-9]+d[0-9]+\+[0-9]+)( .*)? damage/)
        p.damage_roll = damage_matches.andand[1].andand.strip
        p.damage_type = damage_matches.andand[2].andand.strip
        @powers << p
      end
    end
  end
  
  def to_html
    <<-CARD
    <h1 class="monster"> #{self.name} <span class=smaller>(#{self.kind})</span></h1>
    #{self.stats}
    #{self.extra_stats}
    #{self.to_powers_html}
    CARD
  end
  
  def to_powers_html
    self.powers.map do |p|
      <<-POWER
      <p class="flavor">
        <b>#{p.name} #{p.kind}</b>
        <br/>
        <span>
        #{p.description}
        </span>
        <br/>
        <span>
        #{p.attack_bonus && "+#{p.attack_bonus}#{p.vs_defense ? " vs #{p.vs_defense}" : nil}"}
        #{p.damage_roll && "#{p.damage_roll}#{p.damage_type ? " #{p.damage_type}" : nil} damage"}
        </span>
      </p>
      POWER
    end.join("\n")
  end
end