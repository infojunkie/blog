require 'oembed'

module Jekyll
  class OEmbedTag < Liquid::Tag
    def initialize(tag_name, content, tokens)
      super
      @content = content
      OEmbed::Providers.register_all
      OEmbed::Providers.register_fallback(OEmbed::ProviderDiscovery, OEmbed::Providers::Noembed)
    end

    def render(context)
      begin
        resource = OEmbed::Providers.get(@content.strip)
        resource.html
      rescue StandardError => e
        Jekyll.logger.error("oEmbed:", "Could not extract oEmbed information from #{@content.strip}: #{e}")
        ""
      end
    end

    Liquid::Template.register_tag('oembed', self)
  end
end
