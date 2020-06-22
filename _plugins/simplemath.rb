# Some parts of this code is taken from github.com/fgalindo/jekyll-liquid-latex-plugin
# but with major rewrite [and, in fact, with considerable downgrade in the functionality].

require "kramdown/converter"
require "fileutils"
require "digest"
require "erb"

def generate_html(filename, full_filename, formula, is_formula, inline, style, converter)
    #title=CGI.escape(formula)
    #title=ERB::Util.url_encode(formula)
    title=ERB::Util.html_escape(formula) # FIXME.
    absolute_path="/"+full_filename;

    if is_formula
        if inline
            result=converter.format_as_span_html("img",
                {"src"=>absolute_path,
                "class"=>"inline", "style"=>style}, "");
        else
            result=converter.format_as_block_html("img",
                {"src"=>absolute_path,
                "class"=>"inline", "style"=>style}, "", 0);
        end
    else
        result="<img src=\""+absolute_path+"\" style=\""+style+"\" class=\"inline\"/>"
    end

    cache=File.new(filename+".html_cache", "w")
    cache.puts(result)
    cache.close
end

def render_latex(formula, is_formula, inline, site, converter=0)
    directory="eq"
    if !File.exists?(directory)
        FileUtils.mkdir_p(directory)
    end

    formula_in_brackets=formula
    if is_formula
        equation_bracket="$"
        equation_bracket="$$" unless inline
        formula_in_brackets=equation_bracket+formula+equation_bracket
    end
    filename=Digest::MD5.hexdigest(formula_in_brackets)+".png"
    full_filename=File.join(directory, filename)
    cache=filename+".html_cache"
    # Do not generate the same formula again.
    return File.read(cache) if File.exists?(cache)

    #latex_source="\\documentclass[10pt]{article}\n"
    latex_source="\\documentclass[preview]{standalone}\n"
    latex_source<<"\\usepackage[utf8]{inputenc}\n"
    latex_source<<"\\usepackage[T2A,T1]{fontenc}\n"
    latex_source<<"\\usepackage{amsmath,amsfonts,amssymb,color,xcolor}\n"
    latex_source<<"\\usepackage[english, russian]{babel}\n"
    latex_source<<"\\usepackage{type1cm}\n"
    latex_source<<"\\usepackage{tikz}\n"
    latex_source<<"\\usepackage[european,emptydiode,americaninductor]{circuitikz-0.4}\n"
    #latex_source<<"\\usepackage{geometry}\n\\usetikzlibrary{backgrounds}\n"

    if formula&&inline
        latex_source<<"\\newsavebox\\frm\n"
        latex_source<<"\\sbox\\frm{"
        latex_source<<formula_in_brackets
        latex_source<<"}\n\\newwrite\\frmdims\n"
        latex_source<<"\\immediate\\openout\\frmdims=dimensions.tmp\n"
        latex_source<<"\\immediate\\write\\frmdims{depth: \\the\\dp\\frm}\n"
        latex_source<<"\\immediate\\write\\frmdims{height: \\the\\ht\\frm}\n"
        latex_source<<"\\immediate\\closeout\\frmdims\n"
    end

    #latex_source<<"\n\\geometry{papersize={\\wd\\frm,\\ht\\frm},margin=0pt,bindingoffset=0pt}\n"
    latex_source<<"\n\\begin{document}\n"
    #latex_source<<"\\pagestyle{empty}\n"
    #latex_source<<"\\begin{tikzpicture}[remember picture,overlay]\n"
    #latex_source<<"\\node[anchor=north west, inner sep=0pt] at (current page.north west) {\\usebox\\frm};%\n"
    #latex_source<<"\\end{tikzpicture}\n"
    if inline
        latex_source<<"\\usebox\\frm\n"
    else
        latex_source<<formula_in_brackets
    end
    latex_source<<"\\end{document}"

    puts("[debug] latex source for "+filename+": "+latex_source);

    latex_document=File.new("temp-file.tex", "w")
    latex_document.puts(latex_source)
    latex_document.close
    system("latex -interaction=nonstopmode temp-file.tex >/dev/null 2>&1")

    result="<pre>"+formula_in_brackets+"</pre>"
    if File.exists?("temp-file.dvi")
        #system("dvipng -q* -T tight temp-file.dvi -o "+full_filename);
        system("dvips -E -q temp-file.dvi -o temp-file.eps >/dev/null 2>&1");
        system("convert -density 120 -trim temp-file.eps "+full_filename+" >/dev/null 2>&1")
        if File.exists?(full_filename)
            #system("convert "+full_filename+"-fuzz 2% -transparent white "+full_filename)
            static_file=Jekyll::StaticFile.new(site, site.source, directory, filename)
            #Jekyll::Site::register_file(static_file.path) # FIXME.
            site.static_files<<static_file

            if is_formula&&inline
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
            end

            # Try to use ImageMagick's identify to get the height in pixels.
            system("identify -ping -format %h "+full_filename+" > height.tmp")
            height_pixels=File.read("height.tmp");
            style="height: "+height_pixels+"px;"
            system("identify -ping -format %w "+full_filename+" > width.tmp")
            width_pixels=File.read("width.tmp");
            style=style+" width: "+width_pixels+"px;"
            # FIXME: Visually incorrect size.

            if is_formula&&inline
                # For some reason the depth obtained from the latex
                # does not give a correct vertical position for a
                # image on an html-page. But nevertheless we can use
                # the proportionality between actual size of the image
                # and the reported dimensions (including the depth) to
                # convert from pt to px.

                conversion_factor=(height_pixels.to_f)/height_pt_float
                depth_pixels=(depth_pt_float*conversion_factor).round.to_i

                depth=depth_pixels.to_s

                #style="margin-bottom: -"+depth+"px;"
                style=style+" vertical-align: -"+depth+"px;";
            end

            result=generate_html(filename, full_filename, formula,
                is_formula, inline, style, converter)
        else
            puts "png file does not exist (for formula "+formula+")"
        end
    else
        puts "dvi file was not generated (for formula "+formula+")"
    end

    Dir.glob("temp-file.*").each do |f|
        File.delete(f)
    end

    return result
end

module Kramdown
    module Converter
        module MathEngine
            module SimpleMath
                @@my_site=nil
                def self.my_init(site)
                    @@my_site=site
                end

                def self.call(converter, element, options)
                    display_mode=element.options[:category]
                    formula=element.value
                    inline=true
                    if display_mode==:block
                        inline=false
                    end

                    return render_latex(formula, true, inline, @@my_site, converter)
                end
            end
        end
    end
end

Kramdown::Converter.add_math_engine(:simplemath, Kramdown::Converter::MathEngine::SimpleMath)

class Jekyll::Site
    def initialize()
        @xfiles=[]
    end

    def register_file(filename)
        @xfiles<<filename
    end

    alias :super_write :write

    def write
        super_write
        source_files=[]
        #source_files=@xfiles
        puts "generated files:"
        source_files.each do |f|
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
    end
end

Jekyll::Hooks.register(:site, :after_init) do |site|
    Kramdown::Converter::MathEngine::SimpleMath::my_init(site)
end

def fix_math(content)
    # FIXME: Try to insert &#8288; (word-joiner) after formulas
    # if the following character is not space.

    mathfix=MathFix.new(content)
    return mathfix.fixup()
end

# FIXME: How it will interoperate with a "latex" tag defined below?
class MathFix
    def initialize(content)
        @content=content
        @position=0
        @new_content=""
        @current_character=""

        @bracket=""
        @in_formula=false
    end

    def next_character
        return false if @position>=@content.length
        @current_character=@content[@position]
        @position=@position+1
        return true
    end

    def add_character(character)
        @new_content=@new_content+character
    end

    def add_current_character()
        add_character(@current_character)
    end

    def process_escaped()
        return false unless @current_character=="\\"
        add_current_character()
        if next_character()
            add_current_character()
        end
        next_character()
        return true
    end

    def detect_bracket()
        return false unless @current_character=="$"
        @bracket="$"
        if next_character()
            if @current_character=="$"
                @bracket="$$"
                next_character()
            end
        end
        return true
    end

    def process_bracket()
        add_character("\n\n") if ((@bracket=="$$")&&!@in_formula)
        add_character("$$")
        add_character("\n\n") if ((@bracket=="$$")&&@in_formula)
        @in_formula=!@in_formula
    end

    def fixup()
        next_character()
        while @position<@content.length
            if process_escaped()
                next
            end

            if detect_bracket()
                process_bracket()
                next
            else
                add_current_character()
                next_character()
            end
        end
        return @new_content
    end
end

Jekyll::Hooks.register(:pages, :pre_render) do |target, payload|
    if target.ext==".md"&&target.basename=="about"||target.basename=="index"
        target.content=fix_math(target.content)
    end
end

Jekyll::Hooks.register(:blog_posts, :pre_render) do |target, payload|
    if target.data["ext"]==".md"
        target.content=fix_math(target.content)
    end
end

module Jekyll
    module Tags
        class LatexBlock < Liquid::Block
            include Liquid::StandardFilters

            def initialize(tag_name, text, tokens)
                super
            end

            def render(context)
                latex_source=super
                site=context.registers[:site]
                return render_latex(latex_source, false, false, site)
            end

        end
    end
end

Liquid::Template.register_tag("latex", Jekyll::Tags::LatexBlock)
