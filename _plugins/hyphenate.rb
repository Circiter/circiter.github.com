require "nokogiri"
require "text/hyphen"

# Based on jekyll-hyphenate_filter.

module Jekyll
    module HyphenateFilter
        class Hyphenator
            def initialize()
                @hyphenator=Text::Hyphen.new(language: "ru", left: 2, right: 2)
            end

            def hyphenate(content)
                fragment=Nokogiri::HTML::DocumentFragment.parse(content)
                fragment.css("p").each do |element|
                    element.traverse do |node|
                        node.content=hyphenate_text(node.to_s) if node.text?
                    end
                end
            end

            def hyphenate_text(text)
                words=text.split
                words.each do |word|
                    #regex=/#{Regexp.escape(word)}(?!\z)/
                    #regex=/#{word}(?!\z)/

                    # FIXME.
                    stripped_word=word.gsub(/[\(\)\[\],\.\?\!\\\/]/, "")
                    #stripped_word=word
                    #stripped_word["("]=""
                    #stripped_word[")"]=""

                    if Regexp.escape(stripped_word)==stripped_word
                        puts("word to hyphenate: "+stripped_word);
                        hyphenated_word=@hyphenator.visualize(stripped_word, "-")
                        #"&shy;")
                    #text.gsub!(/#{word}/, hyphenated_word)
                    #text.gsub!(regex, hyphenated_word)
                    #text.gsub!(/#{stripped_word}/, hyphenated_word)
                        #text.gsub!(stripped_word, hyphenated_word)
                    end
                    #while text[stripped_word]!="" do
                    #    text[stripped_word]="@"
                    #end
                    #while text["@"]!="" do
                    #    text["@"]=hyphenated_word
                    #end
                end
            end
        end

        def hyphenate(content)
            hyphenator=Hyphenator.new()
            hyphenator.hyphenate(content)
        end
    end
end

Liquid::Template.register_filter(Jekyll::HyphenateFilter)
