require 'oembed'

module Jekyll
  class OEmbedTag < Liquid::Tag
    def initialize(tag_name, content, tokens)
      super
      @content = content.strip
      @@cache ||= Jekyll::Cache.new("OEmbedTag")
      OEmbed::Providers.register_all
      OEmbed::Providers.register_fallback(OEmbed::ProviderDiscovery, OEmbed::Providers::Noembed)
    end

    def render(context)
      @@cache.getset(@content) do
        begin
          resource = OEmbed::Providers.get(@content)
          resource.html
        rescue StandardError => e
          Jekyll.logger.error("oEmbed:", "Could not extract oEmbed information from #{@content}: #{e}")
          ""
        end
      end
    end

    Liquid::Template.register_tag('oembed', self)
  end
end
