require "fileutils"

module Jekyll
module Converters
    class TeXToHTMLConverter < Converter
        #safe true
        #priority :low

        def matches(extension)
            extension.downcase =~ /^\.tex$/ #/^(\.tex)||(\.latex)$/i
        end

        def output_ext(extension)
            ".html"
        end

        def convert(content)
            result=""
            source="\\documentclass{article}\n"
            #source<<"\\usepackage[T1]{fontenc}\n"
            source<<"\\usepackage[english,russian]{babel}\n"
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
                    f=File.new("temp-file.tex", "w")
                    f.puts("hello world")
                    f.close
                end
                if File.exists?("temp-file.html")
                    #htmlfile=File.open("temp-file.html", "r")
                    File.open("temp-file.html", "r") {|f| result=f.read}
                    #result=htmlfile.read
                    #htmlfile.close
                else
                    result="temp-file.html does not exist"
                end
            else
                result="temp-file.pdf does not exist"
            end
            Dir.glob("temp-file.*").each do |f|
                File.delete(f)
            end
            return result
        end
    end
end
end
