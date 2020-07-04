# Some parts of this code is taken from github.com/fgalindo/jekyll-liquid-latex-plugin
# but with major rewrite [and, in fact, with considerable downgrade in the functionality].

require "kramdown/converter"
require "fileutils"
require "digest"
require "erb"

def generate_html(filename, full_filename, formula, inline, style)
    #title=CGI.escape(formula)
    #title=ERB::Util.url_encode(formula)
    #title=ERB::Util.html_escape(formula) # FIXME.
    absolute_path="/"+full_filename;

    result="<img src=\""+absolute_path+"\" style=\""+style+"\" class=\"latex\">"
    #result="<div style=\"text-align: center\">"+result+"</div>" unless inline
    result="<br><center>"+result+"</center><br>" unless inline

    cache=File.new(filename+".html_cache", "w")
    cache.puts(result)
    cache.close

    return result
end

def render_latex(formula, inline, site)
    directory="eq"
    FileUtils.mkdir_p(directory) unless File.exists?(directory)

    filename=Digest::MD5.hexdigest(formula)+".png"
    full_filename=File.join(directory, filename)
    cache=filename+".html_cache"
    # Do not generate the same formula again.
    return File.read(cache) if File.exists?(cache)

    #s="false"
    #s="true" if inline
    #puts "\n<formula inline="+s+">"+formula+"</formula>"

    latex_source="\\documentclass[preview,border=0pt]{standalone}\n"
    latex_source<<"\\usepackage[utf8]{inputenc}\n"
    latex_source<<"\\usepackage[T2A,T1]{fontenc}\n"
    latex_source<<"\\usepackage{amsmath,amsfonts,amssymb,color,xcolor}\n"
    latex_source<<"\\usepackage[english, russian]{babel}\n"
    latex_source<<"\\usepackage{type1cm}\n"

    if !inline
        latex_source<<"\\usepackage{tikz}\n"
        latex_source<<"\\usepackage[european,emptydiode,americaninductor]{circuitikz-0.4}\n"
    else
        latex_source<<"\\newsavebox\\frm\n"
        latex_source<<"\\sbox\\frm{"
        latex_source<<formula
        latex_source<<"}\n\\newwrite\\frmdims\n"
        latex_source<<"\\immediate\\openout\\frmdims=dimensions.tmp\n"
        latex_source<<"\\immediate\\write\\frmdims{depth: \\the\\dp\\frm}\n"
        latex_source<<"\\immediate\\write\\frmdims{height: \\the\\ht\\frm}\n"
        latex_source<<"\\immediate\\closeout\\frmdims\n"
    end

    latex_source<<"\n\\begin{document}\n"
    if inline
        latex_source<<"\\usebox\\frm\n"
    else
        latex_source<<formula
    end
    latex_source<<"\\end{document}"

    puts "[debug] <latex>"+latex_source+"</latex>"

    latex_document=File.new("temp-file.tex", "w")
    latex_document.puts(latex_source)
    latex_document.close
    system("latex -interaction=nonstopmode temp-file.tex >/dev/null 2>&1")
    #system("latex -interaction=nonstopmode temp-file.tex")

    result="<pre>"+formula+"</pre>" # FIXME: Add escaping, maybe.
    if File.exists?("temp-file.dvi")
        #system("dvips -E -q temp-file.dvi -o temp-file.eps >/dev/null 2>&1");
        #system("convert -density 120 -quality 90 -trim temp-file.eps "+full_filename+" >/dev/null 2>&1")
        system("dvips -E temp-file.dvi -o temp-file.eps");
        system("convert -density 120 -quality 90 -trim temp-file.eps "+full_filename)
        if File.exists?(full_filename)
            static_file=Jekyll::StaticFile.new(site, site.source, directory, filename)
            #Jekyll::Site::register_file(static_file.path) # FIXME.
            site.static_files<<static_file
            FilesSingleton::register(static_file.path)

            if inline
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

            if inline
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

            result=generate_html(filename, full_filename, formula, inline, style)
        else
            puts "debug: png file does not exist (for formula "+formula+")"
        end
    else
        puts "debug: dvi file was not generated (for formula "+formula+")"
    end

    Dir.glob("temp-file.*").each do |f|
        File.delete(f)
    end

    #puts "debug: <generated_html>"+result+"</generated_html>"
    return result
end

module Kramdown
    module Converter
        module MathEngine
            module SimpleMath
                #@@my_site=nil
                #def self.my_init(site)
                #    @@my_site=site
                #end

                def self.call(converter, element, options)
                    return element.value
                end
            end
        end
    end
end

Kramdown::Converter.add_math_engine(:simplemath, Kramdown::Converter::MathEngine::SimpleMath)

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

#Jekyll::Hooks.register(:site, :after_init) do |site|
#    Kramdown::Converter::MathEngine::SimpleMath::my_init(site)
#end

def fix_math(content)
    # FIXME: Try to insert &#8288; (word-joiner) after formulas
    # if the following character is not space.

    mathfix=MathFix.new(content)
    return mathfix.fixup()
end

class MathFix
    def initialize(content)
        @content=content
        @position=-1
        @new_content=""
        @current_character=""

        @bracket=""
        @in_formula=false

        @xtag=""
    end

    def next_character
        @position=@position+1
        return false if @position>=@content.length
        @current_character=@content[@position]
        return true
    end

    def add_character(character)
        @new_content=@new_content+character
    end

    def add_current_character()
        add_character(@current_character)
    end

    # FIXME: Is it correct for a formulas?
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
        if next_character()&&@current_character=="$"
            @bracket="$$"
            next_character()
        end
        return true
    end

    def process_bracket()
        if !@in_formula
            if @bracket=="$$"
                add_character("{% tex block %}")
            else
                add_character("{% tex %}")
            end
        end
        add_character(@bracket)
        add_character("{% endtex %}") if @in_formula
        @in_formula=!@in_formula
    end

    def is_white(c)
        return (c==" "||c=="\n"||c=="\t")
    end

    def skip_white()
        while is_white(@current_character)
            #puts "skip_white(): current_character="+@current_character
            add_current_character()
            break unless next_character()
        end
    end

    def match(fragment, exactly_here)
        skip_white()
        pos=@position
        while true
            return false if pos+fragment.length>=@content.length
            #puts "match(): fragment=("+fragment+") content substring=("+@content[pos, 
            #    fragment.length]+"), pos="+pos.to_s
            if fragment==@content[pos, fragment.length]
                add_character(@content[@position,pos+fragment.length-@position])
                #puts "add_character("+@content[@position,pos+fragment.length-@position]+")"
                @position=pos+fragment.length
                @current_character=@content[@position]
                #puts "matched!"
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
            #puts "read_word(): current_character="+@current_character
            word+=@current_character
            add_current_character()
            break unless next_character()
        end
        return word
    end

    # FIXME: Consider to use a stack to keep
    # track of the multi-level structure of tags.
    def detect_liquid_tag(tag_to_ignore)
        return unless match("{%", true)
        word=read_word()
        match("%}", false)

        if @xtag==""
            if word==tag_to_ignore
                #puts "open tag: {% tex %}"
                @xtag=word
            end
        else
            if word=="end"+@xtag
                #puts "close tag: {% endtex %}"
                @xtag=""
            end
        end
    end

    def fixup()
        next_character()
        while @position<@content.length
            detect_liquid_tag("tex")
            next if process_escaped()

            if @xtag==""&&detect_bracket()
                process_bracket()
                next
            else
                #if @xtag!=""
                #    print @current_character
                #end
                add_current_character()
                next_character()
            end
        end
        return @new_content
    end
end

Jekyll::Hooks.register(:pages, :pre_render) do |target, payload|
    if target.ext==".md"&&(target.basename=="about"||target.basename=="index")
        target.content=fix_math(target.content)
    end
end

# FIXME: Try a modes other than :pre_render.
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
                @inline=true
                text.gsub("  ", " ").split(" ").each do |x|
                    @inline=false if x=="block"
                end
            end

            def render(context)
                latex_source=super
                site=context.registers[:site]
                return render_latex(latex_source, @inline, site)
            end

        end
    end
end

Liquid::Template.register_tag("tex", Jekyll::Tags::LatexBlock)
