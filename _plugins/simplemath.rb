require "kramdown/converter"
require "fileutils"
require "digest"

#module Jekyll
#    module Site
#        def write
#            Kramdown::Converter::MathEngine::SimpleMath::init_globals(self)
#            source_files=[]
#            Kramdown::Converter::MathEngine::SimpleMath::generated_files.each do |f|
#                source_files<<f.path
#            end
#            to_remove=Dir.glob("eq/*.png")-source_files
#            to_remove.each do |f|
#                if File.exists?(f)
#                    File.unlink f
#                end
#            end
#        end
#    end
#end

module Kramdown
    module Converter
        module MathEngine
            module SimpleMath
                @@generated_files=[]
                def self.generated_files
                    @@generated_files
                end

                #directory="eq"

                def self.init_globals(site)
                    #if !File.exists(directory)
                    #    FileUtils.mkdir_p(directory)
                    #end
                end

                def self.call(converter, element, options)
                    display_mode=element.options[:category]
                    formula=element.value

                    directory="eq"
                    if !File.exists(directory)
                        FileUtils.mkdir_p(directory)
                    end

                    latex_source="\\documentclass{article}\n"
                    latex_document<<"\\usepackage{amsmath, amssymb}\n"
                    latex_source<<"\\begin{document}\n"
                    latex_source<<"\\pagestyle{empty}\n"
                    equation_bracket="$"
                    if display_mode==:block
                        equation_bracket="$$"
                    end
                    formula_in_brackets=equation_bracket+formula+equation_bracket
                    latex_source<<formula_in_brackets
                    latex_source<<"\n\end{document}"
                    filename=Digest::MD5.hexdigest(formula_in_brackets)+".png"

                    latex_document=File.new("temp-file.tex")
                    latex_document.puts(latex_source)
                    latex_document.close
                    system("latex -interaction=nonstopmode temp-file.tex")

                    result=formula_in_brackets
                    if File.exists?("temp-file.dvi")
                        system("dvipng -q* -T tight temp-file.dvi");
                        if File.exists?("temp-file.png")
                            full_filename=File.join(directory, filename)
                            # FIXME: Move the file.
                            system("mv temp-file.png "+full_filename)

                            static_file=Jekyll::StaticFile.new(site, site.source, directory, filename)
                            @@generated_files<<static_file
                            site.static_files<<static_file
                            result="<img src=\""+full_filename+"\" title=\""+formula+"\" />"
                        end
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
