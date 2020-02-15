require "fileutils"

# FIXME: Jekyll::Converters
module Jekyll
module Converters
    class TeXToHTMLConverter < Converter
        def matches(extension)
            extension.downcase =~ /^\.tex$/
        end

        def output_ext(extension)
            ".html"
        end

        def convert(content)
            result="empty"
            source="\\documentclass{article}\n"
            source<<"\\usepackage[T1]{fontenc}\n"
            source<<"\\usepackage[utf8]{inputenc}\n"
            source<<"\\usepackage[english,russian]{babel}\n"
            source<<"\\usepackage{amsmath, amssymb}\n"
            source<<"\\begin{document}\n"
            source<<content
            source<<"\\end{document}"

            texfile=File.new("temp-file.tex", "w")
            texfile.puts(source)
            texfile.close
            system("pdflatex -interaction=nonstopmode temp-file.tex")
            if File.exists?("temp-file.pdf")
                system("pdftohtml temp-file.pdf temp-file.html")
                if !File.exists?("temp-file.html")
                    f=File.new("temp-file.html", "w")
                    f.puts("<html><body><div style="color: green">hello world</div></body></html>")
                    f.close
                end
                if File.exists?("temp-file.html")
                    result=File.read("temp-file.html")
                else
                    result="temp-file.html does not exist"
                end
            else
                result="temp-file.pdf does not exist"
            end
            Dir.glob("temp-file.*").each do |f|
                File.delete(f)
            end
            result
        end
    end
end
end
