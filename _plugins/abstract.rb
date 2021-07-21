module Jekyll
    module AbstractFilter
        def abstract_only(content)
            return content
        end
    end

    class AbstractBlock < Liquid::Block
        include Liquid::StandardFilters

        def initialize(tag_name, text, tokens)
            super
        end

        def render(context)
            source=super
            return source
            # return ''
        end
    end
end

Liquid::Template.register_filter(Jekyll::AbstractFilter)
Liquid::Template.register_tag("abstract", Jekyll::AbstractBlock)
