# NOTE: this is not autoloaded
# monkey patch to save me some time here
# FIXME: this is mean and wrong
class :: Nokogiri::XML::Element
  def css_clean_first(selector)
    css(selector).andand.first.andand.content.andand.strip
  end
  
  def css_clean_all(selector)
    css(selector).map{|x| x.andand.content.andand.strip}
  end
end