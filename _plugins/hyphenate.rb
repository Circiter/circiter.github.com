require "nokogiri"
require "text/hyphen"

# Based on jekyll-hyphenate_filter.

module Jekyll
    module HyphenateFilter
        class Hyphenator
            def initialize()
                @hyphenator=Text::Hyphen.new(:language=>"ru", :left=>2, :right=>2)
            end

            def hyphenate(content)
                fragment=Nokogiri::HTML::DocumentFragment.parse(content)
                #html=fragment.inner_html
                fragment.css("p").each do |element|
                    element.traverse do |node|
                        node.content=hyphenate_text(node.content) if node.text?
                    end
                end
                fragment.to_s
            end

            # FIXME: It doesn't hyphenate inside some of list items, header captions, etc.
            def hyphenate_text(text)
                my_text=text
                text.split(" ").map do |word|
                    # FIXME: Add some other punctuation characters (e.g. ellipses).
                    stripped_word=word.gsub(/[\(\)\[\],\.\?\!\\\/:\'\"<>\|0-9]/, "")
                    if Regexp.escape(stripped_word)==stripped_word
                        hyphenated_word=@hyphenator.visualize(stripped_word, "­")
                        #puts("substitution: \""+stripped_word+"\" -> \""+hyphenated_word.gsub("­", "-")+"\"");
                        # FIXME: &shy;=U+2011=&#8208;=non-breakable hyphen.
                        #puts("substitution: \""+stripped_word+"\" -> \""+hyphenated_word.gsub("\u2011", "-")+"\"");
                        my_text.gsub!(stripped_word, hyphenated_word)
                    end
                    word
                end
                return convert_quotes(my_text)
            end

            # FIXME: Does it break a code, preformatted text, etc?
            # FIXME: Consider to somehow insert this functionality
            # into smartypants mechanism.
            def convert_quotes(text)
                text.gsub!("<<", "&laquo;").gsub!(">>", "&raquo;")
            end

        end

        def hyphenate(content)
            hyphenator=Hyphenator.new()
            hyphenator.hyphenate(content)
        end
    end
end

Liquid::Template.register_filter(Jekyll::HyphenateFilter)
