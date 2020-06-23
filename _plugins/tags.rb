# For each tag like "programming", you will have a page that lists all posts with that tag
# at /tag/programming.

# From jameshfisher.com

# TODO: implement equivalence classes of tags.

module Jekyll
    class TagPageGenerator < Generator
        def generate(site)
            posts=site.collections["blog_posts"]
            #tags=posts.docs.flat_map{|post| post.data["tags"]||[]}.to_set
            #tags.each do |tag|
            #    site.pages << TagPage.new(site, site.source, tag)
            #end
        end
    end

    class TagPage < Page
        def initialize(site, base, tag)
            @site=site
            @base=base
            @dir=File.join('tag', tag)
            @name='index.html'

            self.process(@name)
            self.read_yaml(File.join(base, "_layouts"), "tag.html")
            self.data['tag']=tag
            self.data['title']=self.data['title'].gsub(/@/, "#{tag}");
            self.data['permalink']=@dir
        end
    end
end
