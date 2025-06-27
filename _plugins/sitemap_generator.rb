require 'jekyll'
require 'uri'

module Jekyll
  class SitemapGenerator < Generator
    safe true
    priority :low

    def generate(site)
      # Parameters
      max_urls_per_sitemap = 50000

      # Collect all URLs from the products collection
      products = site.collections['products'].docs
      urls = products.map do |product|
        absolute_url(product.url, site)
      end

      # Determine number of sitemaps needed
      total_sitemaps = (urls.size.to_f / max_urls_per_sitemap).ceil

      # Create the sitemap directory
      sitemap_dir = File.join(site.dest, 'sitemap')
      FileUtils.mkdir_p(sitemap_dir)

      # Generate sitemap index file
      sitemap_index_path = File.join(sitemap_dir, 'sitemap.xml')
      File.open(sitemap_index_path, 'w') do |file|
        file.write(generate_sitemap_index(total_sitemaps, site))
      end

      # Generate each sitemap file
      total_sitemaps.times do |i|
        start_index = i * max_urls_per_sitemap
        end_index = [start_index + max_urls_per_sitemap, urls.size].min
        sitemap_file_path = File.join(sitemap_dir, "sitemap-#{i + 1}.xml")
        File.open(sitemap_file_path, 'w') do |file|
          file.write(generate_sitemap(urls[start_index...end_index], site))
        end
      end
    end

    private

    def generate_sitemap_index(total_sitemaps, site)
      <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  #{(1..total_sitemaps).map do |i|
    "<sitemap>
      <loc>#{absolute_url("/sitemap/sitemap-#{i}.xml", site)}</loc>
      <lastmod>#{Time.now.strftime('%Y-%m-%d')}</lastmod>
    </sitemap>"
  end.join("\n")}
</sitemapindex>
      XML
    end

    def generate_sitemap(urls, site)
      <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  #{urls.map do |url|
    "<url>
      <loc>#{url}</loc>
      <lastmod>#{Time.now.strftime('%Y-%m-%d')}</lastmod>
      <changefreq>weekly</changefreq>
      <priority>0.5</priority>
    </url>"
  end.join("\n")}
</urlset>
      XML
    end

    def absolute_url(path, site)
      URI.join(site.config['url'], path).to_s
    end
  end
end
