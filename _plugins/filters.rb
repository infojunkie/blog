require 'nokogiri'

module Jekyll
  module InfojunkieFilters
    def unchangelogify(str)
      doc = Nokogiri::HTML(str)
      doc.xpath("//table[@class='changelog']").remove
      doc.to_html
    end
  end
end

Liquid::Template.register_filter(Jekyll::InfojunkieFilters)
