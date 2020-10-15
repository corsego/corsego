require 'aws-sdk-s3'
SitemapGenerator::Sitemap.compress = false
# Your website's host name
SitemapGenerator::Sitemap.default_host = "https://www.corsego.com"
# The remote host where your sitemaps will be hosted
SitemapGenerator::Sitemap.sitemaps_host = "https://corsego-public.s3.eu-central-1.amazonaws.com/"

SitemapGenerator::Sitemap.adapter = SitemapGenerator::AwsSdkAdapter.new(
  "corsego-public",
  aws_access_key_id: Rails.application.credentials.dig(:awss3, :access_key_id),
  aws_secret_access_key: Rails.application.credentials.dig(:awss3, :secret_access_key),
  aws_region: "eu-central-1"
)

SitemapGenerator::Sitemap.create do

  add new_user_registration_path, priority: 0.7, changefreq: 'monthly'
  add new_user_session_path, priority: 0.7, changefreq: 'monthly'
  add tags_path, priority: 0.3, changefreq: 'monthly'
  add courses_path, priority: 0.7, changefreq: 'daily'
  
  Course.where(approved: true, published: true).find_each do |course|
    add course_path(course), :lastmod => course.updated_at
  end
end