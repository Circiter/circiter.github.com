# Written by Circiter (mailto:xcirciter@gmail.com).

require "fileutils"
require "digest"

# TODO: Add support for other numeration styles (e.g., latin
# or alphabet instead of arabic).
# Possible styles: arabic-zero, arabic-one, latin, alpha, custom (?).

# TODO: Implement the html anchors generation.

# FIXME: Will this singleton live after one page generation,
# that is is it necessary to clear its data at the page's
# end and how to do it?
module LabelsSingleton
    @referenced_labels=Array.new
    @defined_labels=Array.new

    def self.register_referenced(namespace, label)
        @referenced_labels<<namespace+"::"+label if label!=""
    end

    def self.register_defined(namespace, label)
        @defined_labels<<namespace+"::"+label if label!=""
    end

    def self.find_referenced(namespace, identifier)
        return @referenced_labels.find_index(namespace+"::"+identifier)
    end

    def self.find_defined(namespace, identifier)
        return @defined_labels.find_index(namespace+"::"+identifier)
    end

    def self.referenced_count(namespace)
        #return @referenced_labels.length
        return @referenced_labels.count do |label|
            label.start_with?(namespace+"::")
        end
        #count=0
        #@referenced_labels.each do |label|
        #    count=count+1 if label.start_with?(namespace+"::")
        #end
        #return count
    end

    def self.defined_count(namespace)
        #count=0
        #@defined_labels.each do |label|
        #    count=count+1 if label.start_with?(namespace+"::")
        #end
        #return count
        return @defined_labels.count do |label|
            label.start_with?(namespace+"::")
        end
        #return @defined_labels.length
    end

    def self.cleanup()
        set1=@defined_labels.to_set
        set2=@referenced_labels.to_set
        diff=set1-set2 # FIXME.
        diff.each do |label|
            puts "numbered-labels.rb: undefined label "+label
        end
        @defined_labels.clear
        @referenced_labels.clear
    end
end

Jekyll::Hooks.register(:pages, :post_render) do |target, payload|
    if target.ext=="md"&&(target.basename=="about"||target.basename=="index")
        LabelsSingleton::cleanup
    end
end

Jekyll::Hooks.register(:blog_posts, :post_render) do |target, payload|
    if target.data["ext"]==".md"
        LabelsSingleton::cleanup
    end
end

#use_other_numeration_style=!config["numeration_style"].nil? && !config["numeration_style"].empty?
#numeration_style=config["numeration_style"]

module Jekyll
    class Label < Liquid::Tag
        def initialize(name, params, tokens)
            @tag_name=name
            parameters=params.gsub("  ", " ").split(" ")
            @namespace=parameters[0]
            @identifier=parameters[1]
           super
        end

        def render(context)
            id=context["page"]["id"]
            #filename="./"+Digest::MD5.hexdigest(id+@namespace)

            #referenced_labels_filename=filename+".referenced-labels.txt"
            #defined_labels_filename=filename+".defined-labels.txt"
            #puts "file for referenced labels: "+referenced_labels_filename
            #puts "file for defined labels: "+defined_labels_filename
            #referenced_labels=Array.new
            #defined_labels=Array.new

            #if File.exists?(referenced_labels_filename)
            #    referenced_labels_file=File.open(referenced_labels_filename, "r")
            #    referenced_labels_file.each_line do |line|
            #        puts "line readed and added to referenced labels: "+line
            #        referenced_labels<<line.gsub("\n", "")
            #    end
            #else
            #    referenced_labels_file=File.new(referenced_labels_filename, "w")
            #end

            #if File.exists?(defined_labels_filename)
            #    defined_labels_file=File.open(defined_labels_filename, "r")
            #    defined_labels_file.each_line do |line|
            #        puts "line readed and added to defined labels"+line
            #        defined_labels<<line.gsub("\n", "")
            #    end
            #else
            #    defined_labels_file=File.new(defined_labels_filename, "w")
            #end

            #referenced_labels_file.close
            #defined_labels_file.close

            #number=defined_labels.find_index(@identifier)
            number=LabelsSingleton::find_defined(@namespace, @identifier)
            #number_in_referenced=referenced_labels.find_index(@identifier)
            number_in_referenced=LabelsSingleton::find_referenced(@namespace, @identifier)

            to_register_in_referenced=""
            to_register_in_defined=""

            if number==nil
                puts "can not find id "+@identifier+" in defined labels"
            else
                puts @identifier+" found in defined labels and has index #{number}"
            end
            if number_in_referenced==nil
                puts "can not find id "+@identifier+" in referenced labels"
            else
                puts @identifier+" found in referenced labels and has index #{number_in_referenced}"
            end

            if @tag_name=="def"
                puts "defining new object "+@identifier+" in namespace "+@namespace
                if number==nil
                    puts "adding to an array with defined labels"
                    #defined_labels_file=File.open(defined_labels_filename, "a")
                    #defined_labels_file.puts(@identifier)
                    #defined_labels_file.close
                    to_register_in_defined=@identifier
                else
                    puts "numbered-labels.rb: multiple definitions of "+@identifier
                end

                number=number_in_referenced

                if number==nil
                    #number=defined_labels.length
                    number=LabelsSingleton::defined_count(@namespace)
                end
            else
                puts "referencing an object "+@identifier+" in namespace "+@namespace
                if number_in_referenced==nil
                    puts "adding to an array with referenced labels"
                    #referenced_labels_file=File.open(referenced_labels_filename, "a")
                    #referenced_labels_file.puts(@identifier)
                    #referenced_labels_file.close
                    to_register_in_referenced=@identifier
                end

                if number==nil
                    if number_in_referenced==nil
                        #number=referenced_labels.length
                        number=LabelsSingleton::referenced_count(@namespace)
                    else
                        number=number_in_referenced
                    end
                end
            end

            LabelsSingleton::register_referenced(@namespace, to_register_in_referenced)
            LabelsSingleton::register_defined(@namespace, to_register_in_defined)

            number=number+1
            return "#{number}"
        end
    end
end

Liquid::Template.register_tag("ref", Jekyll::Label)
Liquid::Template.register_tag("def", Jekyll::Label)
