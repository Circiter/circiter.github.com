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

def generate_html(filename, full_filename, formula, inline, style)
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

def latex_preamble
    #latex_source="\\documentclass[preview=true,tikz=true,border=1pt]{standalone}\n"
    latex_source="\\documentclass[preview,border=1pt]{standalone}\n"
    if FilesSingleton::multi_mode()
        #latex_source="\\documentclass[preview=true,multi=true,tikz=true,border=1pt]{standalone}\n"
        latex_source="\\documentclass[preview,multi,border=1pt]{standalone}\n"
    end
    latex_source<<"\\usepackage[T1,T2A]{fontenc}\n"
    latex_source<<"\\usepackage[utf8]{inputenc}\n"
    latex_source<<"\\usepackage{mathtext}\n"
    latex_source<<"\\usepackage{amsmath,amsfonts,amssymb,color,xcolor,stmaryrd}\n"
    latex_source<<"\\usepackage[matrix,arrow,curve,frame,arc]{xy}\n"
    latex_source<<"\\usepackage[english,russian]{babel}\n"
    #latex_source<<"\\usepackage{type1cm}\n"
    #latex_source<<"\\usepackage{fouriernc}\n"
    latex_source<<"\\usepackage{tikz}\n"
    latex_source<<"\\usepackage[european,emptydiode,americaninductor]{circuitikz}\n"
    latex_source<<"\\newwrite\\frmdims\n"
    latex_source<<"\\newsavebox\\xfrm\n"
    latex_source<<"\\begin{document}\n"
    return latex_source
end

def latex_define_formula(findex, formula, inline)
    return "" unless inline
    latex_source="\n"
    latex_source<<"\\sbox\\xfrm{"
    latex_source<<formula
    latex_source<<"}\n"
    latex_source<<"\\immediate\\openout\\frmdims=dimensions#{findex}.tmp\n"
    latex_source<<"\\immediate\\write\\frmdims{depth: \\the\\dp\\xfrm}\n"
    latex_source<<"\\immediate\\write\\frmdims{height: \\the\\ht\\xfrm}\n"
    latex_source<<"\\immediate\\write\\frmdims{width: \\the\\wd\\xfrm}\n"
    latex_source<<"\\immediate\\closeout\\frmdims\n"
    return latex_source
end

def latex_use_formula(findex, formula, inline)
    latex_source=""
    latex_source<<"\\begin{preview}" #if FilesSingleton::multi_mode()
    if inline
        latex_source<<"\\usebox\\xfrm"
    else
        latex_source<<"\n"+formula
    end
    latex_source<<"\n\\end{preview}" #if FilesSingleton::multi_mode()
    latex_source<<"\n\n"
    return latex_source
end

def latex_epilogue()
    return "\\end{document}"
end

def compile_latex(basename, ext, silent=true)
    silence=">/dev/null 2>&1"
    silence="" unless silent
    filename=basename+ext
    processor="pdflatex" #="latex"
    system("#{processor} -interaction=nonstopmode #{filename} #{silence}")
    unless File.exists?(basename+".pdf")
        puts "the first pass of compilation/typesetting fails"
        return
    end
    if FilesSingleton::multi_mode()
        # N.B., run twice to resolve all the references.
        system("#{processor} -interaction=nonstopmode #{filename} #{silence}")
    end
end

def generate_style(findex, full_filename, inline)
    puts "generating style..."
    depth_pt="0pt"
    height_pt="0pt"
    width_pt="0pt"
    if inline
        if File.exists?("dimensions#{findex}.tmp")
            IO.foreach("dimensions#{findex}.tmp") do |line|
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
        else
            puts "can not read dimensions of a image"
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
    puts "style calculated: "+style
    return style
end

def style_stub(findex, decimal_index, is_inline)
    inline="block"
    if is_inline
        inline="inline"
    end
    return "{% style_stub #{findex} #{decimal_index} #{inline} %}"
    #position=...
    #FilesSingleton::register_fixup(position, findex, basename, inline)
    #return ""
end

def generate_images(document_filename, output_filename)
    #system("dvips -E -q temp-file.dvi -o temp-file.eps >/dev/null 2>&1");
    #system("convert -density 120 -quality 90 -trim temp-file.eps "+full_filename+" >/dev/null 2>&1")
    #system("convert -density 120 +repage -trim +repage "+document_filename+" "+output_filename+" >/dev/null 2>&1")
    puts("executing: convert -density 120 -trim +repage "+document_filename+" "+output_filename)
    if File.exists?(document_filename)
        puts "the file "+document_filename+" exists"
    end
    if File.exists?(output_filename)
        puts "output file already exists, removing..."
        File.delete(output_filename)
    end
    system("convert -density 120 -trim +repage "+document_filename+" "+output_filename)
    #system("convert -density 120 -trim +repage "+document_filename+" PNG32:"+output_filename)
end

def render_latex(formula, inline, site)
    directory="eq"
    FileUtils.mkdir_p(directory) unless File.exists?(directory)

    basename=Digest::MD5.hexdigest(formula)
    filename=basename+".png"
    full_filename=File.join(directory, filename)

    multi_image=File.join(directory, basename+"*.png")
    unless FilesSingleton::multi_mode()
        cache=filename+".html_cache"
        # Do not generate the same formula again.
        return File.read(cache) if File.exists?(cache)
    end

    findex=FilesSingleton::next_index()
    eq_index=FilesSingleton::next_equation_index()
    doc_index=FilesSingleton::document_index()

    define_formula=latex_define_formula(findex, formula, inline)
    use_formula=latex_use_formula(findex, formula, inline)

    result="<pre>"+formula+"</pre>" # FIXME: Add escaping, maybe.

    if FilesSingleton::multi_mode()
        file=File.new("composite.tex", "a")
        file.puts define_formula
        file.puts use_formula
        file.close

        style=style_stub(findex, eq_index, inline)
        fname="#{doc_index}-#{eq_index}.png"
        fname=File.join(directory, fname)
        return generate_html(filename, fname, formula, inline, style)
    end

    latex_document=File.new("temp-file.tex", "w")
    latex_document.puts latex_preamble()
    latex_document.puts define_formula
    latex_document.puts use_formula
    latex_document.puts latex_epilogue()
    latex_document.close
    compile_latex("temp-file", ".tex", false)

    #unless File.exists?("temp-file.dvi")
    unless File.exists?("temp-file.pdf")
        puts "debug: pdf file was not generated (for formula "+formula+")"
        return result
    end

    generate_images("temp-file.pdf", full_filename)

    unless File.exists?(full_filename)
        puts "debug: png file does not exist (for formula "+formula+")"
        return result
    end
    static_file=Jekyll::StaticFile.new(site, site.source, directory, filename)
    site.static_files<<static_file
    FilesSingleton::register(static_file.path)

    style=generate_style(findex, full_filename, inline)
    result=generate_html(filename, full_filename, formula, inline, style)

    if !FilesSingleton::multi_mode()
        Dir.glob("temp-file.*").each do |f|
            File.delete(f)
        end
    end

    return result
end

module FilesSingleton
    @list=[]

    @initial_index="aaaaaa"
    @index=@initial_index
    @decimal_index=-1

    @doc_index=0

    def self.document_index()
        return @doc_index
    end

    def self.new_document()
        @doc_index=@doc_index+1
    end

    def self.next_equation_index()
        @decimal_index=@decimal_index+1
        return @decimal_index
    end

    def self.next_index()
        i=0
        while i<@index.length
            if @index[i]!="z"
                @index[i]=(@index[i].ord()+1).chr()
                break
            else
                @index[i]="a"
                if i==@index.length-1
                    puts "formula index overflow"
                    @index="overflow"
                end
            end
            i=i+1
        end
        return @index
    end

    def self.reset_index()
        @index=@initial_index
        @decimal_index=-1
    end

    def self.register(filename)
        @list<<filename
    end

    def self.get_files()
        return @list
    end

    @shared_context=nil
    @transparency=true

    def self.read_config(cfg, key, default=nil)
        return cfg[key] if cfg!=nil&&cfg.has_key?(key)
        return default
    end

    def self.multi_mode()
        return @shared_context if @shared_context!=nil

        cfg=Jekyll.configuration({})
        cfg=read_config(cfg, "simplemath")
        @shared_context=read_config(cfg, "shared_context", false)
        @transparency=read_config(cfg, "transparency", true)

        return @shared_context
    end
end

class Jekyll::Site
    alias :super_write :write

    def write
        super_write
        source_files=FilesSingleton::get_files()
        #puts "generated files:"
        #source_files.each do |f|
        #    puts(f)
        #end
        #to_remove=Dir.glob("eq/*.png")-source_files # FIXME.
        to_remove=Dir.glob("eq/*.png").intersection(source_files)
        #puts "to remove:"
        to_remove.each do |f|
            #puts(f)
            if File.exists?(f)
                #puts("removing "+f)
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

# TODO: Try to factor out the common
#       code from the classes StyleFix
#       and MathFix into a superclass.

# FIXME: Consider to replace it by
#        a singleton to keep track
#        of necessary fixups in memory;
#        then we can apply these fixups
#        without reparsing of the page
#        content.
class StyleFix
    def initialize(content)
        @content=content
        @position=0
        @result_content=""
    end

    def match(substring)
        i=0
        pos=@position
        while i<substring.length
            return false if pos>=@content.length||@content[pos]!=substring[i]
            i=i+1
            pos=pos+1
        end
        puts "matched"
        @position=@position+i-1 # FIXME.
        return true
    end

    def locate_next_style_stub()
        puts "searching for a next style stub..."
        result=Hash.new

        tag_start=-1
        tag_end=-1
        puts "@content.length=#{@content.length}"
        while @position<@content.length
            if tag_start>=0
                tag_end=@position
                if match("%}")
                    puts "%} found"
                    tag=@content[tag_start..tag_end]
                    tag_start=-1
                    puts "style tag readed: "+tag
                    parameters=tag.gsub("\t", " ").gsub("\n"," ").gsub("  "," ").split(" ")
                    if parameters.length==0||parameters.length!=4||parameters[0]!="style_stub"
                        puts "invalid style stub"
                        @result_content=@result_content+"{%"+tag+"%}"
                        next
                    end
                    puts "parameters (findex, basename, inline) are extracted successfully"
                    puts "findex="+parameters[1]
                    puts "basename="+parameters[2]
                    puts "inline="+parameters[3]
                    result["findex"]=parameters[1]
                    result["basename"]=parameters[2]
                    result["inline"]=parameters[3]
                    return result
                end
            else
                if match("{%")
                    puts "{% found"
                    tag_start=@position
                    next
                end
                @result_content=@result_content+@content[@position]
            end

            @position=@position+1
        end

        puts "unterminated tag" if tag_start>=0

        return nil

        #@content.match(/{%\s*style_stub\s+(\a*)\s+(\d*)\s+(\a*)\s*%}/)
    end

    def replace_style_stub(style)
        puts "replacing current style stub..."
        @result_content=@result_content+style
        # Try \b instead of \w+
        #@content.sub!(/{% style_stub\w+.*\w+\d*\w+.* %}/, style)
        #@content.sub!(/{%\s*style_stub\s+(\a*)\s+(\d*)\s+(\a*)\s*%}/, style)
        #return @content
    end

    def get_content()
        return @result_content
    end
end

########################################################

def fix_sizes(content, site)
    return content unless FilesSingleton::multi_mode()

    directory="eq"
    ext=".tex"
    compiled_ext=".pdf"
    img_ext=".png"
    composite_filename="composite"
    doc_index=FilesSingleton::document_index()
    document_filename="#{doc_index}"#"document"

    return content unless File.exists?(composite_filename+ext)

    puts "creating composite tex file..."

    preamble=latex_preamble()
    epilogue=latex_epilogue()
    composite_content=File.read(composite_filename+ext);

    document=File.new(document_filename+ext, "w")
    document.puts(preamble)
    document.puts(composite_content)
    document.puts(epilogue)
    document.close

    puts "compiling composite tex file..."

    compile_latex(document_filename, ext, true)

    if !File.exists?(document_filename+compiled_ext)
        puts "can not generate a composite pdf file"
        return content
    end
    puts "compiled."

    puts "generating images..."

    generate_images(document_filename+compiled_ext, File.join(directory, document_filename+img_ext))

    multi_image=document_filename+"*"+img_ext
    multi_image=File.join(directory, multi_image)
    puts "generated images (#{multi_image}):"
    images=Dir.glob(multi_image)
    if images.length==0
        puts "there are no images for current document"
    end
    if images.length==1
        puts "there is only one image for current document, renaming..."
        FileUtils.mv(images[0], File.join(directory, document_filename+"-0.png"))
        #File.rename(images[0], File.join(directory, "#{doc_index}-0.png"))
    end
    images.each do |individual_image|
        puts "registering individual image: "+individual_image
        static_file=Jekyll::StaticFile.new(site, site.source, directory, File.basename(individual_image))
        site.static_files<<static_file
        FilesSingleton::register(static_file.path)
    end

    puts "applying the style fixes..."

    # {% style_stub <findex> <eq_index> <inline> %}
    content=content.gsub(/{%\s*style_stub\s+(\w+)\s+(\d+)\s+(\w+)\s*%}/) do |tag|
        puts "regex matched:"
        puts "tag=#{tag}, findex=#{$1}, eq_index=#{$2}, inline=#{$3}"
        generate_style($1, File.join(directory, "#{doc_index}-#{$2}.png"), $3=="inline")
    end

    Dir.glob("*.tex").each {|f| File.delete(f)}
    Dir.glob("*.tmp").each {|f| File.delete(f)}

    return content
end

######################################################

def fix_sizes_old(content, site)
    return content unless FilesSingleton::multi_mode()

    directory="eq"
    ext=".tex"
    compiled_ext=".pdf"
    img_ext=".png"
    composite_filename="composite"
    doc_index=FilesSingleton::document_index()
    document_filename="#{doc_index}"#"document"

    return content unless File.exists?(composite_filename+ext)

    puts "creating composite tex file..."

    preamble=latex_preamble()
    epilogue=latex_epilogue()
    composite_content=File.read(composite_filename+ext);

    document=File.new(document_filename+ext, "w")
    document.puts(preamble)
    document.puts(composite_content)
    document.puts(epilogue)
    document.close

    #puts "content of composite tex file:"
    #puts(File.read(document_filename+ext))
    #puts "---------------------------------------"

    puts "compiling composite tex file..."

    compile_latex(document_filename, ext, true)

    if !File.exists?(document_filename+compiled_ext)
        puts "can not generate a composite pdf file"
        return content
    end
    puts "compiled."

    # FIXME: What if a "single" formula in a document
    #        actually maps to several image files?
    #        May be store a image hashes to the dimension files?
    #        Does it will be helpful?

    # If we are processing a block equation and there are
    # several images for it, then place all the images
    # sequentially, one after another (may be duplicating
    # the html markup for defining the proper sizes of images).

    # For inline there is (or should be) only one image generated.

    puts "generating images..."

    generate_images(document_filename+compiled_ext, File.join(directory, document_filename+img_ext))

    multi_image=document_filename+"*"+img_ext
    multi_image=File.join(directory, multi_image)
    puts "generated images (#{multi_image}):"
    images=Dir.glob(multi_image)
    if images.length==0
        puts "there are no images for current document"
    end
    if images.length==1
        puts "there is only one image for current document, renaming..."
        FileUtils.mv(images[0], File.join(directory, document_filename+"-0.png"))
        #File.rename(images[0], File.join(directory, "#{doc_index}-0.png"))
    end
    puts "registering images..."
    images.each do |individual_image|
        puts "individual image: "+individual_image
        puts "site.source="+site.source
        static_file=Jekyll::StaticFile.new(site, site.source, directory, File.basename(individual_image))
        site.static_files<<static_file
        FilesSingleton::register(static_file.path)
    end

    stylefix=StyleFix.new(content)

    puts "applying the style fixes..."

    # FIXME: Consider to use this snippet instead:
    # {% style_stub <findex> <eq_index> <inline> %}
    #content.gsub!(/{%\s*style_stub\s+(\w+)\s+(\d+)\s+(\w+)\s*%}/).each do |tag|
    #    puts "regex matched:"
    #    puts "tag=#{tag}, findex=#{$1}, eq_index=#{$2}, inline=#{$3}"
    #    generate_style($1, File.join(directory, "#{doc_index}-#{$2}.png"), $3=="inline")
    #end

    stub_options=stylefix.locate_next_style_stub()
    #stub_options=FilesSingleton::current_fixup()
    if stub_options==nil
        puts "stub_options==nil"
    end
    while stub_options!=nil
        puts "style stub located; applying..."

        findex=stub_options["findex"]
        eq_index=stub_options["eq_index"]

        full_filename=File.join(directory, "#{doc_index}-#{eq_index}.png")

        inline=false
        if stub_options["inline"]=="inline"
            inline=true
        end
        style=generate_style(findex, full_filename, inline)
        stylefix.replace_style_stub(style)
        #content=FilesSingleton::apply_current_fixup(content, style)
        #stub_options=FilesSingleton::next_fixup()
        stub_options=stylefix.locate_next_style_stub()
        #stub_options=nil
    end

    content=stylefix.get_content()

    Dir.glob("*.tex").each {|f| File.delete(f)}
    Dir.glob("*.tmp").each {|f| File.delete(f)}

    return content
end

######################################################

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

    # FIXME: Try to use <string>.each_char to
    #        iterate over characters in a utf-8
    #        compatible way (but it seems to work
    #        correctly with usual indexing nevertheless).
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

def prerender(target)
    FilesSingleton::new_document()
    target.content=fix_math(target.content)
end

def postrender(target)
        FilesSingleton::reset_index()
        fixed=fix_sizes(target.content, target.site)
        puts "fixed content:"
        puts fixed
        puts "\n------------------------------------------------\n\n"
        target.content=fixed
        #FilesSingleton::reset_fixups()
end

Jekyll::Hooks.register(:pages, :pre_render) do |target, payload|
    if target.ext==".md"&&(target.basename=="about"||target.basename=="index")
        prerender(target)
    end
end

Jekyll::Hooks.register(:blog_posts, :pre_render) do |target, payload|
    if target.data["ext"]==".md"
        prerender(target)
    end
end

Jekyll::Hooks.register(:pages, :post_render) do |target, payload|
    if target.ext==".md"&&(target.basename=="about"||target.basename=="index")
        postrender(target)
    end
end

Jekyll::Hooks.register(:blog_posts, :post_render) do |target, payload|
    if target.data["ext"]==".md"
        postrender(target)
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
