module RemoteCss
  class Client
    require 'open-uri'

    attr_accessor :url

    def initialize(options)
      validate_options!(options)
      @url = options[:url]
    end

    def css
      doc = Nokogiri::HTML(open(@url))
      inline_styles = doc.css("style").map{|s| s.text }
      remote_styles = doc.css("link[rel='stylesheet'][href]").map{|c| open(URI.join(@url, c.attr("href"))).read }
      [inline_styles, remote_styles].join("\n")
    end

    private
    def validate_options!(options)
      raise ":url is required" unless options.has_key?(:url)
    end
  end
end
