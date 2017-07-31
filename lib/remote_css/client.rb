module RemoteCss
  class Client
    require 'open-uri'

    attr_accessor :url

    def initialize(options={})
      validate_options!(options)
      @options = options
      @options[:minify] = true unless @options.has_key?(:minify)
      @options[:verbose] = false unless @options.has_key?(:verbose)
    end

    def css
      verbose("Reading HTML")
      doc = Nokogiri::HTML(@options[:body] || open(@options[:url]))
      verbose("Reading inline styles")
      styles = []
      inline_styles = doc.css("style").map{|s| styles << {:source => :inline, :style => s.text.strip} }
      threads = []
      remote_styles = doc.css("link[rel='stylesheet'][href]").each do |c|
        url = URI.join(@options[:url], c.attr("href")).to_s
        if url[0..1] == "//"
          url = "http:#{url}"
        end
        verbose("Loading #{url}")
        threads << Thread.new do
          styles << {:source => url, :style => open(url).read.strip}
        end
      end

      threads.each { |thr| thr.join }
      verbose "Loaded all styles, generating string"
      style = styles.map{|s| "/* #{s[:source]} */\n\n#{s[:style]}" }.join("\n\n")

      if @options[:minify]
        verbose "Minifying"
        CSSminify.compress(style)
      else
        style
      end

    end

    private
    def validate_options!(options)
      raise ":url or :body is required" unless options.has_key?(:url) || options.has_key?(:body)
    end

    def verbose(text)
      puts text if @options[:verbose]
    end
  end
end
