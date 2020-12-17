# Some parts of this code is taken from github.com/fgalindo/jekyll-liquid-latex-plugin
# but with major rewrite [and, in fact, with considerable downgrade in the functionality].

#require "kramdown/converter"
require "fileutils"
require "digest"
require "erb"

# TODO: Try to typeset each of the formulas on its own page in one large document (one per
# a *.md file). At the end, try to create this document and include all the formulas into it.
# Finally, compile this document in such a way that each rendered formula be placed in its
# own *.png file. Such a scheme would allow the usage of the latex equation labeling, and,
# also, it would make it possible to compile a latex code faster.)
# But note that such a scheme needs a second pass emit a correct html code with actual sizes
# and [vertical] positions. But note, that such an approach is incompatible with the
# caching mechanism.

def generate_html(filename, full_filename, formula, inline, style, multi_mode)
    #title=CGI.escape(formula)
    #title=ERB::Util.url_encode(formula)
    #title=ERB::Util.html_escape(formula) # FIXME.
    absolute_path="/"+full_filename;

    result="<img src=\""+absolute_path+"\" style=\""+style+"\" class=\"latex\">"
    result="<br><center>"+result+"</center><br>" unless inline

    cache=File.new(filename+".html_cache", "w")
    cache.puts(result)
    cache.close

    return result
end

def render_latex(formula, inline, site, multi_mode)
    directory="eq"
    FileUtils.mkdir_p(directory) unless File.exists?(directory)

    basename=Digest::MD5.hexdigest(formula)
    filename=basename+".png"
    full_filename=File.join(directory, filename)
    multi_image=File.join(directory, basename+"*.png")
    cache=filename+".html_cache"
    # Do not generate the same formula again.
    return File.read(cache) if File.exists?(cache)

    if multi_mode
        latex_source="\\documentclass[preview,math,tikz,border=1pt]{standalone}\n"
    else
        latex_source="\\documentclass[preview,border=1pt]{standalone}\n"
    end
    latex_source<<"\\usepackage[T1,T2A]{fontenc}\n"
    latex_source<<"\\usepackage[utf8]{inputenc}\n"
    latex_source<<"\\usepackage{mathtext}\n"
    latex_source<<"\\usepackage{amsmath,amsfonts,amssymb,color,xcolor,stmaryrd}\n"
    latex_source<<"\\usepackage[matrix,arrow,curve,frame,arc]{xy}\n"
    latex_source<<"\\usepackage[english,russian]{babel}\n"
    #latex_source<<"\\usepackage{type1cm}\n"
    latex_source<<"\\usepackage{tikz}\n"
    latex_source<<"\\usepackage[european,emptydiode,americaninductor]{circuitikz}\n"

    #if !inline
    #    latex_source<<"\\usepackage{tikz}\n"
    #    #latex_source<<"\\usepackage[european,emptydiode,americaninductor]{circuitikz-0.4}\n"
    #    latex_source<<"\\usepackage[european,emptydiode,americaninductor]{circuitikz}\n"
    #else
    if inline
        latex_source<<"\\newsavebox\\xfrm\n"
        latex_source<<"\\sbox\\xfrm{"
        latex_source<<formula
        latex_source<<"}\n\\newwrite\\frmdims\n"
        latex_source<<"\\immediate\\openout\\frmdims=dimensions.tmp\n"
        latex_source<<"\\immediate\\write\\frmdims{depth: \\the\\dp\\xfrm}\n"
        latex_source<<"\\immediate\\write\\frmdims{height: \\the\\ht\\xfrm}\n"
        latex_source<<"\\immediate\\write\\frmdims{width: \\the\\wd\\xfrm}\n"
        latex_source<<"\\immediate\\closeout\\frmdims\n"
    end

    latex_source<<"\n\\begin{document}\n"
    if inline
        latex_source<<"\\usebox\\xfrm\n"
    else
        latex_source<<formula
    end
    latex_source<<"\\end{document}"

    #puts "[debug] <latex>"+latex_source+"</latex>"

    latex_document=File.new("temp-file.tex", "w")
    latex_document.puts(latex_source)
    latex_document.close
    #system("latex -interaction=nonstopmode temp-file.tex >/dev/null 2>&1")
    system("pdflatex -interaction=nonstopmode temp-file.tex >/dev/null 2>&1")
    #system("pdflatex -interaction=nonstopmode temp-file.tex")

    result="<pre>"+formula+"</pre>" # FIXME: Add escaping, maybe.
    #if File.exists?("temp-file.dvi")
    if File.exists?("temp-file.pdf")
        #system("dvips -E -q temp-file.dvi -o temp-file.eps >/dev/null 2>&1");
        #system("convert -density 120 -quality 90 -trim temp-file.eps "+full_filename+" >/dev/null 2>&1")
        system("convert -density 120 -trim temp-file.pdf "+full_filename+" >/dev/null 2>&1")
        if multi_mode
            Dir.glob(multi_image).each do |individual_image|
            end
        end
        if File.exists?(full_filename)
            static_file=Jekyll::StaticFile.new(site, site.source, directory, filename)
            site.static_files<<static_file
            FilesSingleton::register(static_file.path)

            if inline
                depth_pt="0pt"
                height_pt="0pt"
                width_pt="0pt"
                IO.foreach("dimensions.tmp") do |line|
                    if line =~ /^([a-z]*):\s+(\d*\.?\d+)[a-z]*$/
                        if $1 == "depth"
                            depth_pt=$2
                        elsif $1 == "height"
                            height_pt=$2
                        elsif $1 == "width"
                            width_pt=$2
                        end
                    end
                end
                height_pt_float=height_pt.to_f
                #width_pt_float=width_pt.to_f
                depth_pt_float=depth_pt.to_f
            end

            # Try to use ImageMagick's identify to get the height in pixels.
            system("identify -ping -format %h "+full_filename+" > height.tmp")
            height_pixels=File.read("height.tmp");

            if inline
                total_height_pt_float=height_pt_float+depth_pt_float
            end

            style="height: "+height_pixels+"px;"

            system("identify -ping -format %w "+full_filename+" > width.tmp")
            width_pixels=File.read("width.tmp");

            style=style+" width: "+width_pixels+"px;"

            if inline
                # For some reason the depth obtained from the latex
                # does not give a correct vertical position for a
                # image on an html-page. But nevertheless we can use
                # the proportionality between actual size of the image
                # and the reported dimensions (including the depth) to
                # convert from pt to px.

                depth_pixels=0
                if total_height_pt_float!=0
                    conversion_factor=(height_pixels.to_f)/total_height_pt_float
                    depth_pixels=(depth_pt_float*conversion_factor).round.to_i
                end

                depth=depth_pixels.to_s
                style=style+" vertical-align: -"+depth+"px;";
                #style=style+" vertical-align: -"+depth_pt+"pt;";
            end

            result=generate_html(filename, full_filename, formula, inline, style, multi_mode)
        else
            puts "debug: png file does not exist (for formula "+formula+")"
        end
    else
        puts "debug: pdf file was not generated (for formula "+formula+")"
    end

    if !multi_mode
        Dir.glob("temp-file.*").each do |f|
            File.delete(f)
        end
    end

    return result
end

#module Kramdown
#    module Converter
#        module MathEngine
#            module SimpleMath
#                #@@my_site=nil
#                #def self.my_init(site)
#                #    @@my_site=site
#                #end
#
#                def self.call(converter, element, options)
#                    return element.value
#                end
#            end
#        end
#    end
#end

#Kramdown::Converter.add_math_engine(:simplemath, ::Kramdown::Converter::MathEngine::SimpleMath)

module FilesSingleton
    @list=[]

    def self.register(filename)
        @list<<filename
    end

    def self.get_files()
        return @list
    end
end

class Jekyll::Site
    alias :super_write :write

    def write
        super_write
        source_files=FilesSingleton::get_files()
        puts "generated files:"
        source_files.each do |f|
            puts(f)
        end
        puts "Dir.glob(eq/*.png):"
        Dir.glob("eq/*.png").each do |f|
            puts(f)
        end
        to_remove=Dir.glob("eq/*.png")-source_files # FIXME.
        puts "to remove:"
        to_remove.each do |f|
            puts(f)
            if File.exists?(f)
                puts("removing "+f)
                #File.unlink(f)
            end
        end
        Dir.glob("*.html_cache").each do |f|
            File.delete(f)
        end
        puts "removing temporary files"
        Dir.glob("**/*.tmp").each do |f|
            puts("removing "+f)
            File.delete(f)
        end
    end
end

#Jekyll::Hooks.register(:site, :after_init) do |site|
#    Kramdown::Converter::MathEngine::SimpleMath::my_init(site)
#end

def fix_sizes(content)
   return content
end

def fix_math(content)
    # FIXME: Try to insert &#8288; (word-joiner) after formulas
    # if the following character is not space.

    mathfix=MathFix.new(content)
    return mathfix.fixup()
end


# FIXME: There is a problem with an extra newline or paragraph
# after a $...$ formula at the end of a line.
# Is the \n after a {% tex %}...{% endtex %} block causes the
# insertion a new unwanted paragraph brake?
# TODO: Do not look inside ``` and liquid tags while processing
# escapes, quotes, and formula brackets ($, $$).
class MathFix
    def initialize(content)
        @content=content
        @position=-1
        @new_content=""
        @current_character=""
        @bracket=""
        @in_formula=false
        @xtag=""
        @in_span=false
        @in_regular_text=true
    end

    def next_character
        @position=@position+1
        return false if @position>=@content.length
        @current_character=@content[@position]
        return true
    end

    def add_character(character)
        # FIXME: Consider a larger class of character (not only the whitespace).
        close_span() if @xtag==""&&@in_regular_text&&is_white(character)
        @new_content=@new_content+character
    end

    def add_current_character()
        add_character(@current_character)
    end

    # FIXME: Is it correct for a formulas?
    def process_escaped()
        return false unless @current_character=="\\"
        @in_regular_text=false
        add_current_character()
        add_current_character() if next_character()
        next_character()
        @in_regular_text=true
        return true
    end

    #"<<" -> "«", ">>" -> "»"
    # FIXME: Deal with the case "$...<$".
    def process_quotes()
        return false unless (@current_character=="<"||@current_character==">")
        quote_character=@current_character
        if next_character()
            if @current_character==quote_character
                add_character(@current_character=="<"?"«":"»")
            else
                add_character(quote_character)
                add_character(@current_character)
            end
            next_character()
        else
            add_character(quote_character)
        end
        return true
    end

    def detect_bracket()
        return false unless @current_character=="$"
        @bracket="$"
        if next_character()&&@current_character=="$"
            @bracket="$$"
            next_character()
        end
        return true
    end

    def close_span()
        if @in_span&&!@in_formula
            @in_regular_text=false
            add_character("</span>");
            @in_regular_text=true
            @in_span=false
        end
    end

    def open_span()
        if !@in_span&&!@in_formula
            @in_regular_text=false
            add_character("<span class=\"nolinebreak\">")
            @in_regular_text=true
            @in_span=true
        end
    end

    def process_bracket()
        if !@in_formula
            if @bracket=="$$"
                close_span()
                @in_regular_text=false
                add_character("{% tex block %}")
            else
                open_span()
                @in_regular_text=false
                add_character("{% tex %}")
            end
        end
        add_character(@bracket)
        add_character("{% endtex %}") if @in_formula
        @in_formula=!@in_formula
        @in_regular_text=true if(!@in_formula)
    end

    def is_white(c)
        return (c==" "||c=="\n"||c=="\t")
    end

    def skip_white()
        while is_white(@current_character)
            add_current_character()
            break unless next_character()
        end
    end

    def match(fragment, exactly_here)
        skip_white()
        pos=@position
        while true
            return false if pos+fragment.length>=@content.length
            if fragment==@content[pos, fragment.length]
                add_character(@content[@position,pos+fragment.length-@position])
                @position=pos+fragment.length
                @current_character=@content[@position]
                return true
            end
            return false if exactly_here
            pos+=1
        end
    end

    def read_word()
        skip_white()
        word=""
        while !is_white(@current_character)
            word+=@current_character
            add_current_character()
            break unless next_character()
        end
        return word
    end

    # FIXME: What about e.g., "{% tex %}{% raw %}...{% endraw %}{% endtex %}"?
    def detect_liquid_tag(tags_to_ignore)
        @in_regular_text=true # FIXME.
        return unless match("{%", true)
        @in_regular_text=false
        word=read_word()
        match("%}", false)
        @in_regular_text=true

        if @xtag==""
            @xtag=word if tags_to_ignore.include?(word)
        else
            @xtag="" if word=="end"+@xtag
        end
    end

    # FIXME: The insertion of the <span> tags seems incompatible with
    # the "redcarpet" and the "kramdown" converters.
    # I'll test the "commonmark" next.
    def fixup()
        next_character()
        while @position<@content.length
            detect_liquid_tag ["tex", "raw", "highlight"]
            next if process_escaped() # FIXME: Is it correct inside formulas?
            #next if process_quotes()

            if !@in_formula&&@xtag==""&&process_quotes()
                next
            elsif @xtag==""&&detect_bracket()
                process_bracket()
                next
            else
                add_current_character()
                next_character()
            end
        end
        close_span()
        return @new_content
    end
end

Jekyll::Hooks.register(:pages, :pre_render) do |target, payload|
    if target.ext==".md"&&(target.basename=="about"||target.basename=="index")
        target.content=fix_math(target.content)
    end
end

Jekyll::Hooks.register(:blog_posts, :pre_render) do |target, payload|
    if target.data["ext"]==".md"
        target.content=fix_math(target.content)
    end
end

Jekyll::Hooks.register(:pages, :post_render) do |target, payload|
    if target.ext==".md"&&(target.basename=="about"||target.basename=="index")
        target.content=fix_sizes(target.content)
    end
end

Jekyll::Hooks.register(:blog_posts, :post_render) do |target, payload|
    if target.data["ext"]==".md"
        target.content=fix_sizes(target.content)
    end
end

module Jekyll
    module Tags
        class LatexBlock < Liquid::Block
            include Liquid::StandardFilters

            def initialize(tag_name, text, tokens)
                super
                @inline=true
                text.gsub("  ", " ").split(" ").each do |x|
                    @inline=false if x=="block"
                end
            end

            def render(context)
                latex_source=super
                site=context.registers[:site]
                return render_latex(latex_source, @inline, site, false)
            end

        end
    end
end

Liquid::Template.register_tag("tex", Jekyll::Tags::LatexBlock)
