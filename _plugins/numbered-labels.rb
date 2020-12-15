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
      filename="./"+Digest::MD5.hexdigest(id+@namespace)+".labels.txt"
      labels=Set.new
      if File.exists?(filename)
        labels_file=File.open(filename, "r")
        labels_file.each_line do |line|
          labels<<line.gsub("\n", "")
        end
      else
          labels_file=File.new(filename, "w")
          #labels_file.puts("")
      end
      labels_file.close

      number=0
      if @current_tag=="newlabel"
        labels_file=File.open(filename, "a")
        labels_file.puts(@identifier)
        labels_file.close
        number=labels.length+1
      else
        found=false
        labels.each do |label|
          if label==@identifier
            found=true
            break
          end
          number=number+1
        end
        return "(undefined)" if !found
      end
      return "#{number}"
    end
  end


end

Liquid::Template.register_tag("newlabel", Jekyll::Label)
Liquid::Template.register_tag("ref", Jekyll::Label)

