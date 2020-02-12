require "kramdown/converter"
require "fileutils"
require "digest"

module Kramdown
    module Converter
        module MathEngine
            module SimpleMath
                @@generated_files=[]
                def self.generated_files
                    @@generated_files
                end

                def self.call(converter, element, options)
                    display_mode=element.options[:category]
                    formula=element.value

                    directory="eq"
                    if !File.exists?(directory)
                        FileUtils.mkdir_p(directory)
                    end

                    puts "generating tex document for formula: "+formula
                    latex_source="\\documentclass{article}\n"
                    latex_source<<"\\usepackage[T1]{fontenc}\n"
                    latex_source<<"\\usepackage[utf8]{inputenc}\n"
                    latex_source<<"\\usepackage{amsmath, amssymb}\n"
                    latex_source<<"\\usepackage[english]{babel}\n"
                    latex_source<<"\\begin{document}\n"
                    latex_source<<"\\pagestyle{empty}\n"
                    equation_bracket="$"
                    if display_mode==:block
                        equation_bracket="$$"
                    end
                    formula_in_brackets=equation_bracket+formula+equation_bracket
                    latex_source<<formula_in_brackets
                    latex_source<<"\n\\end{document}"
                    filename=Digest::MD5.hexdigest(formula_in_brackets)+".png"
                    full_filename=File.join(directory, filename)

                    latex_document=File.new("temp-file.tex", "w")
                    latex_document.puts(latex_source)
                    latex_document.close
                    puts "trying to compile latex document..."
                    system("latex -interaction=nonstopmode temp-file.tex")

                    result=formula_in_brackets
                    if File.exists?("temp-file.dvi")
                        puts "converting dvi to png..."
                        system("dvipng -q* -T tight temp-file.dvi -o "+full_filename);
                        if File.exists?(full_filename)
                            #puts "moving the png file..."
                            #File.rename("temp-file.png", full_filename)
                            #system("mv temp-file.png "+full_filename)

                            site=Jekyll.sites[0] # FIXME.
                            static_file=Jekyll::StaticFile.new(site, site.source, directory, filename)
                            @@generated_files<<static_file
                            site.static_files<<static_file
                            puts "finalizing"
                            result="<img src=\"/"+full_filename+"\" title=\""+formula+"\" />"
                            #if display_mode==:block
                            #    converter.format_as_block_html("img",
                            #        {"src"=>full_filename, "title"=>formula}, "");
                            #else
                            #    converter.format_as_block_html("img",
                            #        {"src"=>full_filename, "title"=>formula}, "");
                            #end
                            puts "ok"
                        else
                            puts "png file does not exist"
                        end
                    else
                        puts "dvi file was not generated"
                    end

                    Dir.glob("temp-file.*").each do |f|
                        File.delete(f)
                    end

                    result
                end
            end
        end
        add_math_engine(:simplemath, MathEngine::SimpleMath)
    end
end

module Jekyll
    class Site
        #alias :super_write :write
        def write
            :super
            #Kramdown::Converter::MathEngine::SimpleMath::init_globals(self)
            source_files=[]
            puts "generated files:"
            Kramdown::Converter::MathEngine::SimpleMath::generated_files.each do |f|
                puts f.path
                source_files<<f.path
            end
            to_remove=Dir.glob("eq/*.png")-source_files
            to_remove.each do |f|
                if File.exists?(f)
                    File.unlink f
                end
            end
        end
    end

end

Jekyll::Hooks.register :documents, :pre_render do |document, payload|
    document.content.gsub("before_substitute", "after_substitute")
end

