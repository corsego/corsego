xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0", "xmlns:atom" => "http://www.w3.org/2005/Atom" do
  xml.channel do
    xml.title "Corsego - Online Courses"
    xml.description "Discover courses published by independent instructors on Corsego."
    xml.link courses_url
    xml.language "en"
    xml.tag! "atom:link", href: courses_url(format: :rss), rel: "self", type: "application/rss+xml"

    @courses.each do |course|
      xml.item do
        xml.title course.title
        xml.description strip_tags(course.marketing_description)
        xml.link course_url(course)
        xml.guid course_url(course), isPermaLink: true
        xml.pubDate course.created_at.to_fs(:rfc822)
        course.tags.each do |tag|
          xml.category tag.name
        end
      end
    end
  end
end
