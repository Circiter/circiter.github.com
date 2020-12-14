require "fileutils"
require "digest"
#require "erb"

module Jekyll
  class Label < Liquid::Tag
    def initialize(name, params, tokens)
      @current_tag=name
      parameters=params.gsub("  ", " ").split(" ")
      @namespace=parameters[0]
      @identifier=parameters[1]
      super
    end

    def render(context)
      id=context["page"]["id"]
      # FIXME: Try also:
      #context.environments.first["page"]["url"]
      #context["page"]["path"]
      #context.registers[:page].id
      puts "page id is "+id
      filename=Digest::MD5.hexdigest(id+@namespace)+".labels.txt"
      labels=Set.new
      labels_file=File.open(filename, "r")
      labels_file.each_line do |line|
        labels<<line
      end

      number=0
      if @current_tag=="newlabel"
        labels_file=File.open(filename, "a")
        labels_file.puts(@identifier)
        number=labels.length+1
      else
        found=false
        labels.each do |line|
          if line==@identifier
            found=true
            break
          end
          number=number+1
        end
        return "<undefined>" if !found
      end
      return "#{number}"
    end
  end


end

Liquid::Template.register_tag("newlabel", Jekyll::Label)
Liquid::Template.register_tag("ref", Jekyll::Label)

