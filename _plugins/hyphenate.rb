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
                        node.content=hyphenate_text(node.to_s) if node.text?
                    end
                end
                fragment.to_s
            end

            # FIXME: It doesn't hyphenate inside list items, header captions, etc.
            def hyphenate_text(text)
                my_text=text
                words=my_text.split(" ").map do |word|
                    # FIXME: Add some other punctuation characters (e.g. ellipses).
                    hyphenated_word=stripped_word=word.gsub(/[\(\)\[\],\.\?\!\\\/:\'\"0-9]/, "")
                    if Regexp.escape(stripped_word)==stripped_word
                        # FIXME: Replace non-breakable hyphen (&shy;) by its code (U+2011=&#8208;?).
                        hyphenated_word=@hyphenator.visualize(stripped_word, "­")
                    end
                    my_text.gsub!(stripped_word, hyphenated_word)
                end#.join(" ")
                #my_text
                return text
                #words.each do |word|
                    #regex=/#{Regexp.escape(word)}(?!\z)/
                    #regex=/#{word}(?!\z)/

                    # FIXME.
                    #stripped_word=word.gsub(/[\(\)\[\],\.\?\!\\\/]/, "")
                    #stripped_word=word
                    #stripped_word["("]=""
                    #stripped_word[")"]=""

                    #if Regexp.escape(stripped_word)==stripped_word
                    #    puts("word to hyphenate: "+stripped_word);
                    #    hyphenated_word=@hyphenator.visualize(stripped_word, "-")
                        #"&shy;")
                    #text.gsub!(/#{word}/, hyphenated_word)
                    #text.gsub!(regex, hyphenated_word)
                    #text.gsub!(/#{stripped_word}/, hyphenated_word)
                        #text.gsub!(stripped_word, hyphenated_word)
                    #end
                    #while text[stripped_word]!="" do
                    #    text[stripped_word]="@"
                    #end
                    #while text["@"]!="" do
                    #    text["@"]=hyphenated_word
                    #end
                #end
            end
        end

        def hyphenate(content)
            hyphenator=Hyphenator.new()
            hyphenator.hyphenate(content)
        end
    end
end

Liquid::Template.register_filter(Jekyll::HyphenateFilter)
