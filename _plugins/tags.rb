# For each tag like "programming", you will have a page that lists all posts with that tag
# at /programming.

# Original code from jameshfisher.com
# Modified by Circiter.

# TODO: Make it possible to specify a list of tags for a blog-post; such a tags
#       may be included in a keywords html-header, for example.

require "fileutils"

module Jekyll
    class TagPageGenerator < Generator
        def generate(site)
            posts=site.collections["blog_posts"]
            tags=posts.docs.flat_map{|post| post.data["tags"]||[]}.to_set
            tags.each do |tag|
                site.pages << TagPage.new(site, site.source, tag)
            end
        end
    end

    class TagPage < Page
        def initialize(site, base, tag)
            @site=site
            @base=base
            @dir=File.join('tag', tag)
            @name='index.html'
            @tagdescriptor=TagDescriptor.new()

            self.process(@name)
            self.read_yaml(File.join(base, "_layouts"), "tag.html")
            self.data['tag']=tag
            description=@tagdescriptor.get_description(tag)
            self.data['description']=description #if description!=""
            self.data['title']=self.data['title'].gsub(/@/, "#{tag}");
            self.data['permalink']=@dir
        end
    end

    class TagDescriptor
        def initialize()
            i=0
            @descriptions=Array.new()
            @ntags=Set.new()
            read_description=false
            IO.foreach("tags_synonyms.txt") do |line|
                if read_description
                    @descriptions[i]=line.downcase
                    i=i+1
                else
                    @ntags<<line.split(" ");
                end
                read_description=!read_description
            end
        end

        def dcase(strings)
            return (strings.map {|string| string.downcase}).to_set
        end

        def get_description(tag)
            tag=tag.downcase
            i=0
            @ntags.each do |synonyms|
                return @descriptions[i] if dcase(synonyms).include?(tag)
                i=i+1
            end
            return ""
        end
    end
end
