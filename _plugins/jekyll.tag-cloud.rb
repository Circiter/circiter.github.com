# Copyright (C) 2011 Anurag Priyam - MIT License

# The support for equivalence classes of tags was
# added by Circiter (mailto:xcirciter@gmail.com).

require "fileutils"

module Jekyll
  # FIXME: Convert to singleton.
  class Normalizer
    def initialize()
      @ntags=Set.new
      IO.foreach("tags_synonyms.txt") do |line|
        @ntags<<line.downcase.split(" ");
      end
    end

    def normalize(tag)
      tag=tag.downcase # Case normalization.
      @ntags.each {|synonyms| return synonyms[0] if synonyms.include?(tag)}
      return tag # Cannot normalize; return as is.
    end
  end

  # Jekyll plugin to generate tag clouds.
  #
  # The plugin defines a `tag_cloud` tag that is rendered by Liquid into a tag
  # cloud:
  #
  #     <div class='cloud'>
  #         {% tag_cloud %}
  #     </div>
  #
  # The tag cloud itself is a collection of anchor tags, styled dynamically
  # with the `font-size` CSS property. The range of values, and unit to use for
  # `font-size` can be specified with a very simple syntax:
  #
  #     {% tag_cloud font-size: 16 - 28px %}
  #
  # The output is automatically formatted to use the same number of decimal
  # places as used in the argument:
  #
  #     {% tag_cloud font-size: 0.8  - 1.8em  %}  # => 1
  #     {% tag_cloud font-size: 0.80 - 1.80em %}  # => 2
  #
  # Tags that have been used less than a certain number of times can be
  # filtered out from the tag cloud with the optional `threshold` parameter:
  #
  #     {% tag_cloud threshold: 2%}
  #
  # Both the parameters can be easily clubbed together:
  #
  #     {% tag_cloud font-size: 50 - 150%, threshold: 2%}
  #
  # The plugin randomizes the order of tags every time the cloud is generated.
  class TagCloud < Liquid::Tag
    safe = true

    # tag cloud variables - these are setup in `initialize`
    attr_reader :size_min, :size_max, :precision, :unit, :threshold

    def initialize(name, params, tokens)
      # initialize default values
      @size_min, @size_max, @precision, @unit = 70, 170, 0, '%'
      @threshold                              = 1

      # process parameters
      @params = Hash[*params.split(/(?:: *)|(?:, *)/)]
      process_font_size(@params['font-size'])
      process_threshold(@params['threshold'])

      @normalizer=Normalizer.new

      super
    end

    def render(context)
      # get an Array of [tag name, tag count] pairs
      posts=context.registers[:site].collections["blog_posts"]
      tags=posts.docs.flat_map{|post| post.data["tags"]||[]}

      normalized_tags=(tags.map {|tag| @normalizer.normalize(tag)}).to_set

      tags_pairs=normalized_tags.map do |tag|
        posts_count=posts.docs.count do |post|
          if post.data["test"]=="true"
            puts("[debug]: post "+post.data["title"]+" ignored.")
            false
          else
            post_tags=post.data["tags"]||[]
            post_tags.any? {|post_tag| @normalizer.normalize(post_tag)==tag}
          end
        end
        [tag, posts_count]
      end

      count=tags_pairs.map {|tag, posts_count| [tag, posts_count] if posts_count>=threshold}

      # clear nils if any
      count.compact!

      # get the minimum, and maximum tag count
      min, max = count.map(&:last).minmax

      # map: [[tag name, tag count]] -> [[tag name, tag weight]]
      weight = count.map do |name, count|
        # logarithmic distribution
        weight = (Math.log(count) - Math.log(min))/(Math.log(max) - Math.log(min))
        [name, weight]
      end

      # shuffle the [tag name, tag weight] pairs
      weight.sort_by! { rand }

      # reduce the Array of [tag name, tag weight] pairs to HTML
      first=true
      weight.reduce("") do |html, tag|
        name, weight = tag
        size = size_min + ((size_max - size_min) * weight).to_f
        size = sprintf("%.#{@precision}f", size)
        html << ", \n" if first==false
        first=false
        html << "<a style='font-size: #{size}#{unit}' href='/tag/#{name}'>#{name}</a>"
      end
    end

    private

    def process_font_size(param)
      /(\d*\.{0,1}(\d*)) *- *(\d*\.{0,1}(\d*)) *(%|em|px)/.match(param) do |m|
        @size_min  = m[1].to_f
        @size_max  = m[3].to_f
        @precision = [m[2].size, m[4].size].max
        @unit      = m[5]
      end
    end

    def process_threshold(param)
      /\d*/.match(param) do |m|
        @threshold = m[0].to_i
      end
    end
  end

  module NormalizeFilter
    def normalize(content)
      normalizer=Normalizer.new()
      normalizer.normalize(content)
    end
  end
end

Liquid::Template.register_tag("tag_cloud", Jekyll::TagCloud)
Liquid::Template.register_filter(Jekyll::NormalizeFilter)
