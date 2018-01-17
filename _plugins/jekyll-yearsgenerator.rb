module Jekyll

  class YearsGenerator < Generator
  
    safe true

    def generate(site)
      @posts = site.posts
      years.each do |year, posts|
        paginate(site, year, posts)
      end
    end

    def years
      hash = Hash.new { |h, key| h[key] = [] }
      @posts.docs.each { |p| hash[p.date.strftime("%Y")] << p }
      hash.each_value { |posts| posts.sort!.reverse! }
      hash
    end

    def paginate(site, year, posts)
      pages = Jekyll::Paginate::Pager.calculate_pages(posts, site.config['paginate'].to_i)
      (1..pages).each do |num_page|
        pager = Jekyll::Paginate::Pager.new(site, num_page, posts, pages)
        path = "/year/#{year}"
        if num_page > 1
          path = path + site.config['paginate_path'].gsub(/:num/, num_page.to_s)
        end
        newpage = GroupSubPageYears.new(site, site.source, path, "year", year)
        newpage.pager = pager
        site.pages << newpage 

      end
    end
  end

  class GroupSubPageYears < Page
    def initialize(site, base, dir, type, val)
      @site = site
      @base = base
      @dir = dir
      @name = 'index.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), "year.html")
      self.data["grouptype"] = type
      self.data[type] = val
    end
  end

end