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
      puts "namespace: "+@namespace
      puts "label id: "+@identifier
      filename="./"+Digest::MD5.hexdigest(id+@namespace)+".labels.txt"
      labels=Set.new
      if File.exists?(filename)
        puts "reading file: "+filename
        labels_file=File.open(filename, "r")
        labels_file.each_line do |line|
          labels<<line
        end
      else
          puts "creating file: "+filename
          labels_file=File.new(filename, "w")
          labels_file.puts("")
      end
      labels_file.close

      number=0
      if @current_tag=="newlabel"
        labels_file=File.open(filename, "a")
        puts "new label stored"
        labels_file.puts(@identifier)
        labels_file.close
        number=labels.length+1
      else
        found=false
        puts "searching for the id."
        labels.each do |line|
          if line==@identifier
            puts "id. found"
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

