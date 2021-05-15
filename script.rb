# frozen_string_literal: true

Bundler.require

require 'open-uri'

class Unexpected < StandardError; end

# Please note that there are many naive parts

DOMAIN      = 'https://note.digital.go.jp'
SITEMAP_URL = "#{DOMAIN}/sitemap.xml.gz"
TARGET      = 'docs'
USER_AGENT  = ENV.fetch('CRAWLER_USER_AGENT')

sio  = OpenURI.open_uri(SITEMAP_URL)
gz   = Zlib::GzipReader.new(sio)
xml  = gz.read
doc  = REXML::Document.new(xml)
locs = REXML::XPath.match(doc, "/urlset/url/loc").map(&:text)

locs.each do |loc|
  path = loc.dup
  raise Unexpected unless path.start_with?(DOMAIN)
  path.delete_prefix!(DOMAIN)
  case path
  when /\.html\z/
    # noop
  when /\.htm\z/
    path.gsub!(/\.htm\z/, '.html')
  when /\/\z/
    path << 'index.html'
  else
    path << '/index.html'
  end

  path.prepend(TARGET)

  Pathname(path).dirname.mkpath
  options = { "User-Agent" => USER_AGENT }
  sio = OpenURI.open_uri(loc, options)
  File.binwrite(path, sio.read)
end
