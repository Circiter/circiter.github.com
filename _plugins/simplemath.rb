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

                    #puts "generating tex document for formula: "+formula
                    latex_source="\\documentclass[10pt]{article}\n"
                    latex_source<<"\\usepackage[utf8]{inputenc}\n"
                    latex_source<<"\\usepackage[T2A,T1]{fontenc}\n"
                    latex_source<<"\\usepackage{amsmath,amsfonts,amssymb,color,xcolor}\n"
                    latex_source<<"\\usepackage[english, russian]{babel}\n"
                    latex_source<<"\\usepackage{type1cm}\n"
                    latex_source<<"\\newsavebox\\frm\n"
                    latex_source<<"\\sbox\\frm{"
                    #equation_bracket=(display_mode==:block)?"$$":"$"
                    equation_bracket="$"
                    if display_mode==:block
                        equation_bracket="$$"
                    end
                    formula_in_brackets=equation_bracket+formula+equation_bracket
                    latex_source<<formula_in_brackets
                    latex_source<<"}\n\\newwrite\\frmdims\n"
                    latex_source<<"\\immediate\\openout\\frmdims=dimensions.tmp\n"
                    latex_source<<"\\immediate\\write\\frmdims{depth: \\the\\dp\\frm}\n"
                    latex_source<<"\\immediate\\write\\frmdims{height: \\the\\ht\\frm}\n"
                    latex_source<<"\\immediate\\closeout\\frmdims\n"
                    latex_source<<"\n\\begin{document}\\pagestyle{empty}\\usebox\\frm\\end{document}"
                    filename=Digest::MD5.hexdigest(formula_in_brackets)+".png"
                    full_filename=File.join(directory, filename)

                    latex_document=File.new("temp-file.tex", "w")
                    latex_document.puts(latex_source)
                    latex_document.close
                    #puts "trying to compile latex document..."
                    system("latex -interaction=nonstopmode temp-file.tex >/dev/null 2>&1")

                    result=formula_in_brackets
                    if File.exists?("temp-file.dvi")
                        #puts "converting dvi to png..."
                        #system("dvipng -q* -T tight temp-file.dvi -o "+full_filename);
                        system("dvips -E temp-file.dvi -o temp-file.eps >/dev/null 2>&1");
                        system("convert -density 150 temp-file.eps "+full_filename+" >/dev/null 2>&1")
                        if File.exists?(full_filename)
                            #system("convert "+full_filename+"-fuzz 2% -transparent white "+full_filename)
                            #convert test.png -background 'rgba(0,0,0,0)' test1.png
                            #site=Jekyll.sites[0]
                            site=@@my_site
                            puts("site.source="+site.source)
                            static_file=Jekyll::StaticFile.new(site, site.source, directory, filename)
                            @@my_generated_files<<static_file
                            site.static_files<<static_file
                            #puts "finalizing"

                            depth_pt="0pt"
                            height_pt="10pt"
                            IO.foreach("dimensions.tmp") do |line|
                                if line =~ /^([a-z]*):\s+(\d*\.?\d+)[a-z]*$/
                                    if $1 == "depth"
                                        depth_pt=$2
                                    elsif $1 == "height"
                                        height_pt=$2
                                    end
                                end
                            end
                            height_pt_float=height_pt.to_f
                            depth_pt_float=depth_pt.to_f

                            # For some reason the depth obtained from the latex
                            # does not give a correct vertical position for a
                            # image on an html-page. But nevertheless we can use
                            # the proportionality between actual size of the image
                            # and the reported dimensions (including the depth) to
                            # convert from pt to px.

                            # Try to use ImageMagick's identify to get the height in pixels.
                            system("identify -ping -format %h "+full_filename+" > height.tmp")
                            height_pixels=File.read("height.tmp");

                            conversion_factor=(height_pixels.to_f)/height_pt_float
                            depth_pixels=(depth_pt_float*conversion_factor).round.to_i

                            depth=depth_pixels.to_s

                            #style="margin-bottom: -"+depth+"px;"
                            style="height: "+height_pixels+"px; vertical-align: -"+depth+"px;";
                            #result="<img src=\"/"+full_filename+"\" title=\""+formula+"\" style=\""+style+"\" class=\"inline\" />"
                            # TODO: Add escapement of formula (to use as the title attribute).
                            if display_mode==:block
                                result=converter.format_as_block_html("img",
                                    {"src"=>"/"+full_filename, "title"=>formula, "border"=>0,
                                    "class"=>"inline", "style"=>style}, "", 0);
                            else
                                result=converter.format_as_span_html("img",
                                    {"src"=>"/"+full_filename, "title"=>formula, "border"=>0,
                                    "class"=>"inline", "style"=>style}, "");
                            end
                            #puts "ok"
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
    end
end

Kramdown::Converter.add_math_engine(:simplemath, Kramdown::Converter::MathEngine::SimpleMath)

class Jekyll::Site
    alias :super_write :write
    def write
        super_write # FIXME: Why super() doesn't work?
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
    Kramdown::Converter::MathEngine::SimpleMath::my_init(site)
end

def fix_math(content)
    # FIXME: Try to insert &#8288; (word-joiner) after @@@@
    # if the following character is not space.
    # FIXME: gsub(/\(\$\//, "(@@@@@\/").
    return content
        .gsub(/\$\$/, "@@@@").gsub(/ \$/, " @@@@").gsub(/\$ /, "@@@@ ").gsub(/\$\./, "@@@@@.")
        .gsub(/\$\?/, "@@@@@?").gsub(/\$,/, "@@@@@,").gsub(/\$:/, "@@@@@:").gsub(/\$-/, "@@@@@-")
        .gsub(/\(\$\//, "(@@@@@\/").gsub(/\$\)/, "@@@@@)").gsub(/^\$/, "@@@@").gsub(/\$$/, "@@@@")
        .gsub(/@@@@@/, "$$\&#8288;").gsub(/@@@@/, "$$")
end

Jekyll::Hooks.register(:pages, :pre_render) do |target, payload|
    if target.ext==".md"&&target.basename=="about"||target.basename=="index"
        target.content=fix_math(target.content)
    end
end

Jekyll::Hooks.register(:blog_posts, :pre_render) do |target, payload|
    if target.data["ext"]==".md"
        target.content="zzzzzzzz"+fix_math(target.content)
    end
end
