require 'rubygems'
require 'andand'
require 'nokogiri'
require 'www/mechanize'

# monkeypatch for old version of libxml
class WWW::Mechanize::Util
  def self.from_native_charset(s, code)
    return s unless s && code
    if Mechanize.html_parser == Nokogiri::HTML
      Iconv.iconv(code.to_s, "UTF-8", s).join("")
    else
      s
    end
  end
end

class DDIWebService
  attr_accessor :username, :password, :session

  def initialize(username,password)
    @username, @password = username, password
  end

  def login!
    @session = WWW::Mechanize.new
    # url with id must be to some attempted resources in order to succeed on fake redirect
    url = "http://www.wizards.com/dndinsider/compendium/login.aspx?page=item&id=7258"
    page = @session.get(url)
    form = page.forms[0]
    form.action = url
    form['email'] = username
    form['password'] = password
    form.click_button
  end
  
  def fakeout!
    @session = :ignore
  end

  def get(url, selector = nil)
    return nil if @session == :ignore
    @session.get(url).andand.parser
  end
  
  def get_detail(url)
    page = self.get(url)    
    return url if page.nil?
    page.css('div#detail').andand.first
  end
  
end