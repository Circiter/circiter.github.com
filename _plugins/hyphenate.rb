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
                        #node.content=hyphenate_text(node.to_s) if node.text?
                        node.content=hyphenate_text(node.content) if node.text?
                    end
                end
                fragment.to_s
            end

            # FIXME: It doesn't hyphenate inside list items, header captions, etc.
            def hyphenate_text(text)
                my_text=text

                #i=text.length
                #trailing_spaces=""
                #while (i>=0)&&(text[i]==" ")
                #    trailing_spaces=trailing_spaces+" "
                #    i=i-1
                #end

                words=text.split(" ").map do |word|
                    # FIXME: Add some other punctuation characters (e.g. ellipses).
                    stripped_word=word.gsub(/[\(\)\[\],\.\?\!\\\/:\'\"<>\|0-9]/, "")
                    hyphenated_word=stripped_word
                    if Regexp.escape(stripped_word)==stripped_word
                        # FIXME: Replace non-breakable hyphen (&shy;) by its code (U+2011=&#8208;?).
                        hyphenated_word=@hyphenator.visualize(stripped_word, "­")
                        puts("substitution: \""+sripped_word+"\" -> \""+hyphenated_word+"\"");
                        my_text.gsub!(stripped_word, hyphenated_word)
                    end
                    word
                    #hyphenated_word
                end
                #return words.join(" ")+trailing_spaces
                return my_text
            end
        end

        def hyphenate(content)
            hyphenator=Hyphenator.new()
            hyphenator.hyphenate(content)
        end
    end
end

Liquid::Template.register_filter(Jekyll::HyphenateFilter)
