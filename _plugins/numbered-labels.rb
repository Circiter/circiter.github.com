require "fileutils"
require "digest"

# TODO: Add support for other numeration styles (e.g., latin
# or alphabet instead of arabic).

# TODO: Implement the html anchors generation.

module Jekyll
  class Label < Liquid::Tag
    def initialize(name, params, tokens)
      parameters=params.gsub("  ", " ").split(" ")
      @namespace=parameters[0]
      @identifier=parameters[1]
      super
    end

    def render(context)
      id=context["page"]["id"]
      filename="./"+Digest::MD5.hexdigest(id+@namespace)+".labels.txt"
      labels=Array.new
      if File.exists?(filename)
        labels_file=File.open(filename, "r")
        labels_file.each_line do |line|
          labels<<line.gsub("\n", "")
        end
      else
          labels_file=File.new(filename, "w")
      end
      labels_file.close

      number=labels.find_index(@identifier)

      #number=1
      #found=false
      #labels.each do |label|
      #  if label==@identifier
      #    found=true
      #    break
      #  end
      #  number=number+1
      #end

      if number==nil
        labels_file=File.open(filename, "a")
        labels_file.puts(@identifier)
        labels_file.close
        number=labels.length
      end

      number=number+1
      return "#{number}"
    end
  end


end

Liquid::Template.register_tag("ref", Jekyll::Label)
