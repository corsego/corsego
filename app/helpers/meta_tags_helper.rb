# frozen_string_literal: true

module MetaTagsHelper
  SITE_NAME = 'Corsego'
  DEFAULT_DESCRIPTION = 'Corsego is an online learning platform where you can discover courses, ' \
                        'learn new skills, and advance your career with expert-led video tutorials.'
  DEFAULT_KEYWORDS = 'online courses, video tutorials, e-learning, online education, skill development, ' \
                     'course platform, learn online, professional training'

  # Main entry point for rendering all meta tags
  def render_meta_tags
    safe_join([
      render_basic_meta_tags,
      render_open_graph_tags,
      render_twitter_card_tags,
      render_canonical_link,
      render_json_ld
    ].compact, "\n")
  end

  # Set page meta data from controller/view
  def set_meta_tags(options = {})
    @meta_title = options[:title]
    @meta_description = options[:description]
    @meta_keywords = options[:keywords]
    @meta_image = options[:image]
    @meta_type = options[:type]
    @meta_url = options[:url]
    @json_ld_data = options[:json_ld]
  end

  private

  def meta_title
    @meta_title || (content_for?(:title) ? content_for(:title) : SITE_NAME)
  end

  def full_title
    base_title = meta_title
    base_title == SITE_NAME ? SITE_NAME : "#{base_title} | #{SITE_NAME}"
  end

  def meta_description
    @meta_description || DEFAULT_DESCRIPTION
  end

  def meta_keywords
    @meta_keywords || DEFAULT_KEYWORDS
  end

  def meta_image
    return @meta_image if @meta_image.present?

    # Default to site logo
    image_url('thumbnail.png')
  end

  def meta_url
    @meta_url || request.original_url
  end

  def meta_type
    @meta_type || 'website'
  end

  def render_basic_meta_tags
    tags = []
    tags << tag.meta(name: 'description', content: truncate_description(meta_description))
    tags << tag.meta(name: 'keywords', content: meta_keywords)
    tags << tag.meta(name: 'robots', content: 'index, follow')
    safe_join(tags, "\n")
  end

  def render_open_graph_tags
    tags = []
    tags << tag.meta(property: 'og:site_name', content: SITE_NAME)
    tags << tag.meta(property: 'og:title', content: meta_title)
    tags << tag.meta(property: 'og:description', content: truncate_description(meta_description))
    tags << tag.meta(property: 'og:type', content: meta_type)
    tags << tag.meta(property: 'og:url', content: meta_url)
    tags << tag.meta(property: 'og:image', content: ensure_absolute_url(meta_image))
    tags << tag.meta(property: 'og:locale', content: 'en_US')
    safe_join(tags, "\n")
  end

  def render_twitter_card_tags
    tags = []
    tags << tag.meta(name: 'twitter:card', content: 'summary_large_image')
    tags << tag.meta(name: 'twitter:title', content: meta_title)
    tags << tag.meta(name: 'twitter:description', content: truncate_description(meta_description))
    tags << tag.meta(name: 'twitter:image', content: ensure_absolute_url(meta_image))
    safe_join(tags, "\n")
  end

  def render_canonical_link
    tag.link(rel: 'canonical', href: meta_url)
  end

  def render_json_ld
    return if @json_ld_data.blank?

    # Handle both single schema and array of schemas
    schemas = @json_ld_data.is_a?(Array) ? @json_ld_data : [@json_ld_data]
    tags = schemas.compact.map do |schema|
      tag.script(schema.to_json.html_safe, type: 'application/ld+json')
    end
    safe_join(tags, "\n")
  end

  # Build JSON-LD for a Course (Schema.org Course type)
  def course_json_ld(course)
    {
      '@context' => 'https://schema.org',
      '@type' => 'Course',
      'name' => course.title,
      'description' => strip_tags(course.marketing_description),
      'provider' => organization_json_ld,
      'url' => course_url(course),
      'coursePrerequisites' => course.level,
      'inLanguage' => course_language_code(course.language),
      'numberOfLessons' => course.lessons_count,
      'hasCourseInstance' => course_instance_json_ld(course),
      'offers' => course_offer_json_ld(course),
      'aggregateRating' => course_rating_json_ld(course),
      'image' => course_image_url(course)
    }.compact
  end

  def organization_json_ld
    {
      '@type' => 'Organization',
      'name' => SITE_NAME,
      'url' => root_url,
      'logo' => ensure_absolute_url(image_url('thumbnail.png'))
    }
  end

  def course_instance_json_ld(course)
    {
      '@type' => 'CourseInstance',
      'courseMode' => 'online',
      'courseWorkload' => "PT#{course.lessons_count}H"
    }
  end

  def course_offer_json_ld(course)
    {
      '@type' => 'Offer',
      'price' => format_price_for_schema(course.price),
      'priceCurrency' => 'USD',
      'availability' => 'https://schema.org/InStock',
      'url' => course_url(course),
      'validFrom' => course.created_at.iso8601
    }
  end

  def course_rating_json_ld(course)
    return nil if course.enrollments_count.zero? || course.average_rating.zero?

    {
      '@type' => 'AggregateRating',
      'ratingValue' => course.average_rating,
      'ratingCount' => course.enrollments_count,
      'bestRating' => 5,
      'worstRating' => 1
    }
  end

  # Build JSON-LD for Product (for Google Shopping)
  def course_product_json_ld(course)
    {
      '@context' => 'https://schema.org',
      '@type' => 'Product',
      'name' => course.title,
      'description' => strip_tags(course.marketing_description),
      'image' => course_image_url(course),
      'brand' => {
        '@type' => 'Organization',
        'name' => SITE_NAME
      },
      'offers' => {
        '@type' => 'Offer',
        'price' => format_price_for_schema(course.price),
        'priceCurrency' => 'USD',
        'availability' => 'https://schema.org/InStock',
        'url' => course_url(course)
      },
      'aggregateRating' => course_rating_json_ld(course),
      'category' => 'Online Courses'
    }.compact
  end

  # Build breadcrumb JSON-LD
  def breadcrumb_json_ld(items)
    {
      '@context' => 'https://schema.org',
      '@type' => 'BreadcrumbList',
      'itemListElement' => items.each_with_index.map do |item, index|
        {
          '@type' => 'ListItem',
          'position' => index + 1,
          'name' => item[:name],
          'item' => item[:url]
        }
      end
    }
  end

  # Website schema for homepage
  def website_json_ld
    {
      '@context' => 'https://schema.org',
      '@type' => 'WebSite',
      'name' => SITE_NAME,
      'url' => root_url,
      'description' => DEFAULT_DESCRIPTION,
      'potentialAction' => {
        '@type' => 'SearchAction',
        'target' => {
          '@type' => 'EntryPoint',
          'urlTemplate' => "#{courses_url}?q={search_term_string}"
        },
        'query-input' => 'required name=search_term_string'
      }
    }
  end

  # Helper methods
  def truncate_description(text, length: 160)
    plain_text = strip_tags(text.to_s)
    truncate(plain_text, length: length, omission: '...')
  end

  def ensure_absolute_url(url)
    return url if url.blank?
    return url if url.start_with?('http://', 'https://')

    "#{request.protocol}#{request.host_with_port}#{url.start_with?('/') ? '' : '/'}#{url}"
  end

  def course_image_url(course)
    if course.avatar.attached?
      ensure_absolute_url(url_for(course.avatar))
    else
      ensure_absolute_url(image_url('thumbnail.png'))
    end
  end

  def course_language_code(language)
    language_codes = {
      'English' => 'en',
      'Russian' => 'ru',
      'Polish' => 'pl',
      'Spanish' => 'es'
    }
    language_codes[language.to_s] || 'en'
  end

  def format_price_for_schema(price_in_cents)
    (price_in_cents.to_f / 100).round(2).to_s
  end
end
