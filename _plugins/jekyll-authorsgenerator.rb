module Jekyll

  class AuthorsGenerator < Generator
  
    safe true

    def generate(site)
      site.categories.each do |author, posts|
        build_subpages(site, author, posts)
      end
    end

    def build_subpages(site, author, posts) 
      posts = posts.sort_by { |p| -p.date.to_f }     
      atomize(site, author, posts)
      paginate(site, author, posts)
    end

    def atomize(site, author, posts)
      path = "/author/#{author.downcase}"
      atom = AtomPageAuthor.new(site, site.source, path, "author", author)
      site.pages << atom
    end

    def paginate(site, author, posts)
      pages = Jekyll::Paginate::Pager.calculate_pages(posts, site.config['paginate'].to_i)
      (1..pages).each do |num_page|
        pager = Jekyll::Paginate::Pager.new(site, num_page, posts, pages)
        path = "/author/#{author.downcase}"
        if num_page > 1
          path = path + site.config['paginate_path'].gsub(/:num/, num_page.to_s)
        end
        newpage = GroupSubPageAuthor.new(site, site.source, path, "author", author)
        newpage.pager = pager
        site.pages << newpage 

      end
    end
  end

  class GroupSubPageAuthor < Page
    def initialize(site, base, dir, type, val)
      @site = site
      @base = base
      @dir = dir
      @name = 'index.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), "author.html")
      self.data["grouptype"] = type
      self.data[type] = val
    end
  end
  
  class AtomPageAuthor < Page
    def initialize(site, base, dir, type, val)
      @site = site
      @base = base
      @dir = dir
      @name = 'rss.xml'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), "author.xml")
      self.data[type] = val
      self.data["grouptype"] = type

      author = site.data['authors'][val]
      unless author.nil?
        self.data["title"] = author['name']
        self.data["description"] = author['bio']
      else
        self.data["title"] = val
      end
    end
  end
end