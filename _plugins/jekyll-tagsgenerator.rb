module Jekyll

  class TagsGenerator < Generator
  
    safe true

    def generate(site)
      site.tags.each do |tag, posts|
        build_subpages(site, tag, posts)
      end
    end

    def build_subpages(site, tag, posts) 
      posts = posts.sort_by { |p| -p.date.to_f }     
      atomize(site, tag, posts)
      paginate(site, tag, posts)
    end

    def atomize(site, tag, posts)
      path = "/tag/#{tag.downcase}"
      atom = AtomPageTags.new(site, site.source, path, "tag", tag)
      site.pages << atom
    end

    def paginate(site, tag, posts)
      pages = Jekyll::Paginate::Pager.calculate_pages(posts, site.config['paginate'].to_i)
      (1..pages).each do |num_page|
        pager = Jekyll::Paginate::Pager.new(site, num_page, posts, pages)
        path = "/tag/#{tag.downcase}"
        if num_page > 1
          path = path + site.config['paginate_path'].gsub(/:num/, num_page.to_s)
        end
        newpage = GroupSubPageTags.new(site, site.source, path, "tag", tag)
        newpage.pager = pager
        site.pages << newpage 

      end
    end
  end

  class GroupSubPageTags < Page
    def initialize(site, base, dir, type, val)
      @site = site
      @base = base
      @dir = dir
      @name = 'index.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), "tag.html")
      self.data["grouptype"] = type
      self.data[type] = val
    end
  end

  class AtomPageTags < Page
    def initialize(site, base, dir, type, val)
      @site = site
      @base = base
      @dir = dir
      @name = 'rss.xml'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), "tag.xml")
      self.data["grouptype"] = type
      self.data[type] = val
      
      tag = site.data['tags'][val]
      unless tag.nil?
        self.data["title"] = tag['name']
        self.data["description"] = tag['desc']
      else
        self.data["title"] = val
      end
    end
  end
end