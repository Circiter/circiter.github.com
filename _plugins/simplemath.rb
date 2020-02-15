require "kramdown/converter"
require "fileutils"
require "digest"

# FIXME: module Kramdown::Converter::MathEngine::SimpleMath
module Kramdown
    module Converter
        module MathEngine
            module SimpleMath
                @@my_site=nil
                def self.my_init(site)
                    puts("SimpleMath::my_init(): site.source="+site.source)
                    @@my_site=site
                end

                @@my_generated_files=[]
                def self.generated_files
                    @@my_generated_files
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
                    #equation_bracket=(display_mode==:block)?"$$":"$"
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
                        #system("dvipng -q* -T tight temp-file.dvi -o "+full_filename);
                        system("dvips -E temp-file.dvi -o temp-file.eps");
                        system("convert temp-file.eps "+full_filename)
                        if File.exists?(full_filename)
                            #system("convert "+full_filename+"-fuzz 2% -transparent white "+full_filename)
                            #convert test.png -background 'rgba(0,0,0,0)' test1.png
                            site=Jekyll.sites[0] # FIXME.
                            #site=@@my_site
                            static_file=Jekyll::StaticFile.new(site, site.source, directory, filename)
                            @@my_generated_files<<static_file
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

        #add_math_engine(:simplemath, MathEngine::SimpleMath)
    end
end

Kramdown::Converter.add_math_engine(:simplemath, Kramdown::Converter::MathEngine::SimpleMath)

class Jekyll::Site
    alias :super_write :write
    def write
        super_write #FIXME: Try to replace this with :write
        source_files=[]
        puts "generated files:"
        Kramdown::Converter::MathEngine::SimpleMath::generated_files.each do |f|
            puts(f.path)
            source_files<<f.path
        end
        puts "files in eq/:"
        Dir.glob("eq/*.png").each do |f|
            puts(f)
        end
        to_remove=Dir.glob("eq/*.png")-source_files # FIXME.
        puts "to remove:"
        to_remove.each do |f|
            puts(f)
            if File.exists?(f)
                puts("removing "+f)
                File.unlink(f)
            end
        end
    end
end

Jekyll::Hooks.register(:site, :after_init) do |site|
    puts("jekyll hooks [site after_init]")
    Kramdown::Converter::MathEngine::SimpleMath::my_init(site)
end

#[:documents, :pages, :posts]
Jekyll::Hooks.register(:pages, :pre_render) do |target, payload|
    puts("page hook")
    if payload["layout"]=="page"||payload["layout]=="draft"
        puts("--- rendering page ---")
        puts("title="+payload["title"])
    end
    target.content=target.content
        .gsub(/\$\$/, "@@@@").gsub(/ \$/, " @@@@").gsub(/\$ /, "@@@@ ").gsub(/\$\./, "@@@@\.")
        .gsub(/\$\?/, "@@@@?").gsub(/\$,/, "@@@@,").gsub(/\$:/, "@@@@:").gsub(/\$-/, "@@@@-")
        .gsub(/\(\$\//, "(@@@@/").gsub(/\$\)/, "@@@@)").gsub(/^\$/, "@@@@").gsub(/\$$/, "@@@@")
        .gsub(/@@@@/, "\$\$")
end

Jekyll::Hooks.register(:documents, :pre_render) do |target, payload|
    puts("document hook");
    if payload["layout"]=="page"||payload["layout]=="draft"
        puts("--- rendering document ---")
        puts("title="+payload["title"])
    end
end

Jekyll::Hooks.register(:posts, :pre_render) do |target, payload|
    puts("post hook");
    if payload["layout"]=="page"||payload["layout]=="draft"
        puts("--- rendering post ---")
        puts("title="+payload["title"])
    end
end

Jekyll::Hooks.register(:blog_posts, :pre_render) do |target, payload|
    puts("blog_post hook");
    if payload["layout"]=="page"||payload["layout]=="draft"
        puts("--- rendering blog_post ---")
        puts("title="+payload["title"])
    end
end
