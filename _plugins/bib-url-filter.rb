require "jekyll/scholar"
require "uri"

#module MarkdownFilter
module Jekyll
    class Scholar
        class BibURLFilter < BibTeX::Filter
            def apply(value)
                #value.to_s.gsub(URI.regexp(["http", "https", "ftp"])) { |c|
                #    "<a href=\"#{$&}\">#{$&}</a>"}
                string=value.to_s
                string="x"+string+"x"
                return string
            end
        end
    end
end
