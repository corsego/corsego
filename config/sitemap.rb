# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://www.corsego.com"

SitemapGenerator::Sitemap.compress = false

SitemapGenerator::Sitemap.create do

  add new_user_registration_path, priority: 0.8, changefreq: "monthly"
  add new_user_session_path, priority: 0.8, changefreq: "monthly"
  add courses_path, priority: 0.7, changefreq: "daily"
  add tags_path, priority: 0.2, changefreq: "monthly"
  
  Course.where(published: true, approved: true).find_each do |course|
    add course_path(course), lastmod: course.updated_at
  end
end
