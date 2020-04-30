# For each tag like "programming", you will have a page that lists all posts with that tag
# at /tag/programming.

# From jameshfisher.com

module Jekyll
    class TagPageGenerator < Generator
        def generate(site)
            tags=site.blog_posts.docs.flat_map{|post| post.data['tags']||[]}.to_set
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

            self.process(@name)
            self.read_yaml(File.join(base, '_layouts'), 'tag.html')
            self.data['tag']=tag
            self.data['title']="Tag: #{tag}"
            self.data['permalink']="/tag/#{tag}"
        end
    end
end
