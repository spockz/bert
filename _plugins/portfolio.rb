module Jekyll
  class PortfolioIndex < Page
    def initialize(site, base, dir)
      @site = site
      @base = base
      @dir  = dir
      @name = "index.html"

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'portfolio.html')
      self.data['projects'] = self.get_projects(site)
    end

    def get_projects(site)
      res = {}.tap do |projects|
        Dir['_schilderijen/*.yml'].sort_by{|s| File.basename(s, '.yml').to_i}.each do |path|
          name   = File.basename(path, '.yml')
          config = YAML.load(File.read(File.join(@base, path)))
          series = (config.key? "series") ? config["series"] : ['Ongesorteerd']
          series.each do |serie|
            projects[serie] = {} if !projects.key? serie
            projects[serie][name] = config if config['published']
          end
        end
      end
      res.sort_by {|k,v| k}
    end
  end

  class ProjectIndex < Page
    def initialize(site, base, dir, path)
      @site     = site
      @base     = base
      @dir      = dir
      @name     = "index.html"
      self.data = YAML.load(File.read(File.join(@base, path)))

      self.process(@name) if self.data['published']
    end
  end

  class GeneratePortfolio < Generator
    safe true
    priority :normal

    def generate(site)
      self.write_portfolio(site)
    end

    # Loops through the list of project pages and processes each one.
    def write_portfolio(site)
      if Dir.exists?('_schilderijen')
        Dir.chdir('_schilderijen')
        Dir["*.yml"].each do |path|
          name = File.basename(path, '.yml')
          self.write_project_index(site, "_schilderijen/#{path}", name)
        end

        Dir.chdir(site.source)
        self.write_portfolio_index(site)
      end
    end

    def write_portfolio_index(site)
      portfolio = PortfolioIndex.new(site, site.source, "/portfolio")
      portfolio.render(site.layouts, site.site_payload)
      portfolio.write(site.dest)

      site.pages << portfolio
      site.static_files << portfolio
    end

    def write_project_index(site, path, name)
      project = ProjectIndex.new(site, site.source, "/portfolio/#{name}", path)

      if project.data['published']
        project.render(site.layouts, site.site_payload)
        project.write(site.dest)

        site.pages << project
        site.static_files << project
      end
    end
  end
end
