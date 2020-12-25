# Written by Circiter (mailto:xcirciter@gmail.com).

# Usage:
# In a file, to be processed with the liquid, you can use the following tags:
# {% def <namespace> <label> %} -- define a label.
# {% ref <namespace> <label> %} -- reference a label.
# N.B., a definition (def) can be placed after a reference (ref); ordering does not matter.
# All the tags will be replaced with a numbers, linking an objects with its corresponding 
# references.

# E.g.:
#
# Theorem {% def theorem pythagor %}: $a^2+b^2=c^2$.
#
# The theorem of Pythagor is written in theorem {% ref theorem pythagor %}.
#
# See also the fig. {% ref fig illustration %}.
#
# ![](illustration.png)
# Fig. {% def fig illustration %}

# TODO: Add support for other numeration styles (e.g., latin
# or alphabet instead of arabic).
# Possible styles: arabic-zero, arabic-one, latin, alpha, custom (?).

# TODO: Implement the html anchors generation.

# FIXME: What about cross-references?

module LabelsSingleton
    @referenced_labels=Hash.new
    @defined_labels=Hash.new

    def self.register_referenced(namespace, label)
        @referenced_labels[namespace]=Array.new unless @referenced_labels.has_key?(namespace)
        @referenced_labels[namespace]<<label if label!=""
    end

    def self.register_defined(namespace, label)
        @defined_labels[namespace]=Array.new unless @defined_labels.has_key?(namespace)
        @defined_labels[namespace]<<label if label!=""
    end

    def self.find_referenced(namespace, identifier)
        return nil unless @referenced_labels.has_key?(namespace)
        return @referenced_labels[namespace].find_index(identifier)
    end

    def self.find_defined(namespace, identifier)
        return nil unless @defined_labels.has_key?(namespace)
        return @defined_labels[namespace].find_index(identifier)
    end

    def self.referenced_count(namespace)
        return 0 unless @referenced_labels.has_key?(namespace)
        return @referenced_labels[namespace].length
    end

    def self.defined_count(namespace)
        return 0 unless @defined_labels.has_key?(namespace)
        return @defined_labels[namespace].length
    end

    def self.cleanup()
        # Each referenced label must be defined.
        @referenced_labels.each_key do |namespace|
            if @defined_labels.has_key?(namespace)
                @referenced_labels[namespace].each do |label|
                    unless @defined_labels[namespace].include?(label)
                        puts "label "+label+" is undefined in namespace "+namespace
                    end
                end
            else
                puts "no one label in namespace "+key+" is defined"
            end
        end
        @defined_labels.clear
        @referenced_labels.clear
    end
end

# FIXME: Is it possible to use
#        Jekyll::Hooks.register(:pages, :post_render, LabelsSingleton::cleanup)?
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

def read_config(config, key, default=nil)
    config=Jekyll.configuration({}) if config==nil
    return config[key] if config.has_key?(key)
    return default
end

module Jekyll
    class Label < Liquid::Tag
        def initialize(name, params, tokens)
            @tag_name=name
            parameters=params.gsub("  ", " ").split(" ")
            @namespace=parameters[0]
            @identifier=parameters[1]
            @numbering_style=nil
            super
        end

        def custom_numeration(number, style)
            return "#{number}"
        end

        def render(context)
            id=context["page"]["id"]
            number=LabelsSingleton::find_defined(@namespace, @identifier)
            number_in_referenced=LabelsSingleton::find_referenced(@namespace, @identifier)

            to_register_in_referenced=""
            to_register_in_defined=""

            if @tag_name=="def"
                if number==nil
                    to_register_in_defined=@identifier
                else
                    puts "numbered-labels.rb: multiple definitions of "+@identifier
                end

                number=number_in_referenced

                number=LabelsSingleton::defined_count(@namespace) if number==nil
            else
                to_register_in_referenced=@identifier if number_in_referenced==nil

                if number==nil
                    if number_in_referenced==nil
                        number=LabelsSingleton::referenced_count(@namespace)
                    else
                        number=number_in_referenced
                    end
                end
            end

            LabelsSingleton::register_referenced(@namespace, to_register_in_referenced)
            LabelsSingleton::register_defined(@namespace, to_register_in_defined)

            number=number+1
            if @numbering_style==nil
                cfg=read_config(nil, "numbered_labels")
                @numbering_style=read_config(cfg, "numbering_style", "arabic")
            end
            return custom_numeration(number, @numbering_style) if @numbering_style!="arabic"
            return "#{number}"
        end
    end
end

Liquid::Template.register_tag("ref", Jekyll::Label)
Liquid::Template.register_tag("def", Jekyll::Label)
