#!/usr/bin/env ruby
# frozen_string_literal: true

# Corsego MCP Server
#
# A Model Context Protocol server that lets any AI assistant create and manage
# courses on a Corsego instance without ever opening the web app.
#
# Usage:
#   ruby mcp/server.rb
#
# Environment variables:
#   CORSEGO_URL       - Base URL of the Corsego instance (default: http://localhost:3000)
#   CORSEGO_API_TOKEN - API token for authentication (obtain via POST /api/v1/auth/token)
#
# Configure in Claude Desktop (claude_desktop_config.json):
#   {
#     "mcpServers": {
#       "corsego": {
#         "command": "ruby",
#         "args": ["/path/to/corsego/mcp/server.rb"],
#         "env": {
#           "CORSEGO_URL": "https://your-corsego-instance.com",
#           "CORSEGO_API_TOKEN": "your-api-token-here"
#         }
#       }
#     }
#   }

require 'json'
require 'net/http'
require 'uri'

class CorsegoMcpServer
  PROTOCOL_VERSION = '2024-11-05'
  SERVER_NAME = 'corsego-course-manager'
  SERVER_VERSION = '1.0.0'

  def initialize
    @base_url = ENV.fetch('CORSEGO_URL', 'http://localhost:3000')
    @api_token = ENV['CORSEGO_API_TOKEN']
  end

  def run
    $stderr.puts "Corsego MCP Server starting (#{@base_url})"

    $stdin.each_line do |line|
      line = line.strip
      next if line.empty?

      begin
        request = JSON.parse(line)
        response = handle_request(request)
        write_response(response) if response
      rescue JSON::ParserError => e
        write_response(error_response(nil, -32_700, "Parse error: #{e.message}"))
      rescue => e
        $stderr.puts "Error: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
        write_response(error_response(nil, -32_603, "Internal error: #{e.message}"))
      end
    end
  end

  private

  def handle_request(request)
    id = request['id']
    method = request['method']
    params = request['params'] || {}

    case method
    when 'initialize'
      handle_initialize(id, params)
    when 'notifications/initialized'
      nil # notification, no response needed
    when 'tools/list'
      handle_tools_list(id)
    when 'tools/call'
      handle_tool_call(id, params)
    when 'ping'
      jsonrpc_response(id, {})
    else
      error_response(id, -32_601, "Method not found: #{method}")
    end
  end

  def handle_initialize(id, _params)
    jsonrpc_response(id, {
      protocolVersion: PROTOCOL_VERSION,
      capabilities: {
        tools: {}
      },
      serverInfo: {
        name: SERVER_NAME,
        version: SERVER_VERSION
      }
    })
  end

  def handle_tools_list(id)
    jsonrpc_response(id, { tools: tool_definitions })
  end

  def handle_tool_call(id, params)
    tool_name = params['name']
    args = params['arguments'] || {}

    result = case tool_name
             when 'authenticate'
               tool_authenticate(args)
             when 'list_courses'
               tool_list_courses
             when 'get_course'
               tool_get_course(args)
             when 'create_course'
               tool_create_course(args)
             when 'update_course'
               tool_update_course(args)
             when 'delete_course'
               tool_delete_course(args)
             when 'publish_course'
               tool_publish_course(args)
             when 'create_chapter'
               tool_create_chapter(args)
             when 'update_chapter'
               tool_update_chapter(args)
             when 'delete_chapter'
               tool_delete_chapter(args)
             when 'reorder_chapters'
               tool_reorder_chapters(args)
             when 'create_lesson'
               tool_create_lesson(args)
             when 'update_lesson'
               tool_update_lesson(args)
             when 'delete_lesson'
               tool_delete_lesson(args)
             when 'reorder_lessons'
               tool_reorder_lessons(args)
             when 'list_tags'
               tool_list_tags
             when 'add_tags_to_course'
               tool_add_tags_to_course(args)
             when 'remove_tag_from_course'
               tool_remove_tag_from_course(args)
             else
               { error: "Unknown tool: #{tool_name}" }
             end

    is_error = result.is_a?(Hash) && result[:error]
    jsonrpc_response(id, {
      content: [{ type: 'text', text: JSON.pretty_generate(result) }],
      isError: is_error || false
    })
  end

  # -------------------------------------------------------------------
  # Tool definitions
  # -------------------------------------------------------------------

  def tool_definitions
    [
      {
        name: 'authenticate',
        description: 'Authenticate with your Corsego account using email and password. Returns an API token that will be used for all subsequent requests. You only need to call this once if CORSEGO_API_TOKEN is not already set.',
        inputSchema: {
          type: 'object',
          properties: {
            email: { type: 'string', description: 'Your Corsego account email' },
            password: { type: 'string', description: 'Your Corsego account password' }
          },
          required: %w[email password]
        }
      },
      {
        name: 'list_courses',
        description: 'List all courses you own. Returns a summary of each course including title, price, published/approved status, and enrollment count.',
        inputSchema: { type: 'object', properties: {} }
      },
      {
        name: 'get_course',
        description: 'Get full details of a course you own, including all chapters, lessons, tags, and content. Use the course ID or slug.',
        inputSchema: {
          type: 'object',
          properties: {
            course_id: { type: 'string', description: 'Course ID or slug' }
          },
          required: %w[course_id]
        }
      },
      {
        name: 'create_course',
        description: 'Create a new course. At minimum provide a title. Price is in cents (e.g. 4900 = $49.00). Language options: English, Russian, Polish, Spanish. Level options: All levels, Beginner, Intermediate, Advanced.',
        inputSchema: {
          type: 'object',
          properties: {
            title: { type: 'string', description: 'Course title (max 70 characters, must be unique)' },
            description: { type: 'string', description: 'Full course description (rich text / HTML supported, min 5 characters)' },
            marketing_description: { type: 'string', description: 'Short marketing description (max 300 characters)' },
            price: { type: 'integer', description: 'Price in cents (0 = free, max 499999). Example: 4900 = $49.00' },
            language: { type: 'string', description: 'Course language: English, Russian, Polish, or Spanish', enum: %w[English Russian Polish Spanish] },
            level: { type: 'string', description: 'Course level', enum: ['All levels', 'Beginner', 'Intermediate', 'Advanced'] }
          },
          required: %w[title]
        }
      },
      {
        name: 'update_course',
        description: 'Update an existing course you own. Only provide the fields you want to change.',
        inputSchema: {
          type: 'object',
          properties: {
            course_id: { type: 'string', description: 'Course ID or slug' },
            title: { type: 'string', description: 'New course title' },
            description: { type: 'string', description: 'New full course description' },
            marketing_description: { type: 'string', description: 'New marketing description (max 300 chars)' },
            price: { type: 'integer', description: 'New price in cents' },
            language: { type: 'string', description: 'Course language', enum: %w[English Russian Polish Spanish] },
            level: { type: 'string', description: 'Course level', enum: ['All levels', 'Beginner', 'Intermediate', 'Advanced'] }
          },
          required: %w[course_id]
        }
      },
      {
        name: 'delete_course',
        description: 'Delete a course you own. Only works if the course has no enrollments.',
        inputSchema: {
          type: 'object',
          properties: {
            course_id: { type: 'string', description: 'Course ID or slug' }
          },
          required: %w[course_id]
        }
      },
      {
        name: 'publish_course',
        description: 'Toggle the published status of a course. Publishing makes it visible to students (once approved by admin). Call again to unpublish.',
        inputSchema: {
          type: 'object',
          properties: {
            course_id: { type: 'string', description: 'Course ID or slug' }
          },
          required: %w[course_id]
        }
      },
      {
        name: 'create_chapter',
        description: 'Create a new chapter in a course. Chapters group lessons together.',
        inputSchema: {
          type: 'object',
          properties: {
            course_id: { type: 'string', description: 'Course ID or slug' },
            title: { type: 'string', description: 'Chapter title (max 100 characters, unique within course)' }
          },
          required: %w[course_id title]
        }
      },
      {
        name: 'update_chapter',
        description: 'Update a chapter title.',
        inputSchema: {
          type: 'object',
          properties: {
            course_id: { type: 'string', description: 'Course ID or slug' },
            chapter_id: { type: 'string', description: 'Chapter ID or slug' },
            title: { type: 'string', description: 'New chapter title' }
          },
          required: %w[course_id chapter_id title]
        }
      },
      {
        name: 'delete_chapter',
        description: 'Delete a chapter and all its lessons from a course.',
        inputSchema: {
          type: 'object',
          properties: {
            course_id: { type: 'string', description: 'Course ID or slug' },
            chapter_id: { type: 'string', description: 'Chapter ID or slug' }
          },
          required: %w[course_id chapter_id]
        }
      },
      {
        name: 'reorder_chapters',
        description: 'Set the display order of chapters in a course. Provide all chapter IDs in the desired order.',
        inputSchema: {
          type: 'object',
          properties: {
            course_id: { type: 'string', description: 'Course ID or slug' },
            ordered_ids: {
              type: 'array',
              items: { type: 'integer' },
              description: 'Array of chapter IDs in the desired display order'
            }
          },
          required: %w[course_id ordered_ids]
        }
      },
      {
        name: 'create_lesson',
        description: 'Create a new lesson in a chapter. Content supports rich text / HTML. Video URL supports YouTube, Vimeo, and Loom links.',
        inputSchema: {
          type: 'object',
          properties: {
            course_id: { type: 'string', description: 'Course ID or slug' },
            chapter_id: { type: 'string', description: 'Chapter ID or slug (the chapter this lesson belongs to)' },
            title: { type: 'string', description: 'Lesson title (max 100 characters, unique within course)' },
            content: { type: 'string', description: 'Lesson content (rich text / HTML supported)' },
            video_url: { type: 'string', description: 'Video URL (YouTube, Vimeo, or Loom)' }
          },
          required: %w[course_id chapter_id title content]
        }
      },
      {
        name: 'update_lesson',
        description: 'Update an existing lesson. Only provide the fields you want to change.',
        inputSchema: {
          type: 'object',
          properties: {
            course_id: { type: 'string', description: 'Course ID or slug' },
            lesson_id: { type: 'string', description: 'Lesson ID or slug' },
            title: { type: 'string', description: 'New lesson title' },
            content: { type: 'string', description: 'New lesson content' },
            video_url: { type: 'string', description: 'New video URL' },
            chapter_id: { type: 'string', description: 'Move lesson to a different chapter (chapter ID or slug)' }
          },
          required: %w[course_id lesson_id]
        }
      },
      {
        name: 'delete_lesson',
        description: 'Delete a lesson from a course.',
        inputSchema: {
          type: 'object',
          properties: {
            course_id: { type: 'string', description: 'Course ID or slug' },
            lesson_id: { type: 'string', description: 'Lesson ID or slug' }
          },
          required: %w[course_id lesson_id]
        }
      },
      {
        name: 'reorder_lessons',
        description: 'Set the display order of lessons in a course. Provide all lesson IDs in the desired order.',
        inputSchema: {
          type: 'object',
          properties: {
            course_id: { type: 'string', description: 'Course ID or slug' },
            ordered_ids: {
              type: 'array',
              items: { type: 'integer' },
              description: 'Array of lesson IDs in the desired display order'
            }
          },
          required: %w[course_id ordered_ids]
        }
      },
      {
        name: 'list_tags',
        description: 'List all available tags/categories that can be applied to courses.',
        inputSchema: { type: 'object', properties: {} }
      },
      {
        name: 'add_tags_to_course',
        description: 'Add one or more tags to a course for categorization.',
        inputSchema: {
          type: 'object',
          properties: {
            course_id: { type: 'string', description: 'Course ID or slug' },
            tag_ids: {
              type: 'array',
              items: { type: 'integer' },
              description: 'Array of tag IDs to add to the course'
            }
          },
          required: %w[course_id tag_ids]
        }
      },
      {
        name: 'remove_tag_from_course',
        description: 'Remove a tag from a course.',
        inputSchema: {
          type: 'object',
          properties: {
            course_id: { type: 'string', description: 'Course ID or slug' },
            tag_id: { type: 'integer', description: 'Tag ID to remove from the course' }
          },
          required: %w[course_id tag_id]
        }
      }
    ]
  end

  # -------------------------------------------------------------------
  # Tool implementations
  # -------------------------------------------------------------------

  def tool_authenticate(args)
    response = api_request(:post, '/api/v1/auth/token', {
      email: args['email'],
      password: args['password']
    }, skip_auth: true)

    if response['api_token']
      @api_token = response['api_token']
      {
        message: 'Authentication successful. Token stored for this session.',
        email: response['email'],
        name: response['name'],
        roles: response['roles']
      }
    else
      { error: response['error'] || 'Authentication failed.' }
    end
  end

  def tool_list_courses
    api_request(:get, '/api/v1/courses')
  end

  def tool_get_course(args)
    api_request(:get, "/api/v1/courses/#{args['course_id']}")
  end

  def tool_create_course(args)
    body = {}
    %w[title description marketing_description price language level].each do |key|
      body[key] = args[key] if args.key?(key)
    end
    api_request(:post, '/api/v1/courses', body)
  end

  def tool_update_course(args)
    body = {}
    %w[title description marketing_description price language level].each do |key|
      body[key] = args[key] if args.key?(key)
    end
    api_request(:patch, "/api/v1/courses/#{args['course_id']}", body)
  end

  def tool_delete_course(args)
    api_request(:delete, "/api/v1/courses/#{args['course_id']}")
  end

  def tool_publish_course(args)
    api_request(:patch, "/api/v1/courses/#{args['course_id']}/publish")
  end

  def tool_create_chapter(args)
    api_request(:post, "/api/v1/courses/#{args['course_id']}/chapters", {
      title: args['title']
    })
  end

  def tool_update_chapter(args)
    api_request(:patch, "/api/v1/courses/#{args['course_id']}/chapters/#{args['chapter_id']}", {
      title: args['title']
    })
  end

  def tool_delete_chapter(args)
    api_request(:delete, "/api/v1/courses/#{args['course_id']}/chapters/#{args['chapter_id']}")
  end

  def tool_reorder_chapters(args)
    api_request(:patch, "/api/v1/courses/#{args['course_id']}/chapters/reorder", {
      ordered_ids: args['ordered_ids']
    })
  end

  def tool_create_lesson(args)
    body = { title: args['title'], content: args['content'], chapter_id: args['chapter_id'] }
    body[:video_url] = args['video_url'] if args['video_url']
    api_request(:post, "/api/v1/courses/#{args['course_id']}/lessons", body)
  end

  def tool_update_lesson(args)
    body = {}
    %w[title content video_url chapter_id].each do |key|
      body[key] = args[key] if args.key?(key)
    end
    api_request(:patch, "/api/v1/courses/#{args['course_id']}/lessons/#{args['lesson_id']}", body)
  end

  def tool_delete_lesson(args)
    api_request(:delete, "/api/v1/courses/#{args['course_id']}/lessons/#{args['lesson_id']}")
  end

  def tool_reorder_lessons(args)
    api_request(:patch, "/api/v1/courses/#{args['course_id']}/lessons/reorder", {
      ordered_ids: args['ordered_ids']
    })
  end

  def tool_list_tags
    api_request(:get, '/api/v1/tags')
  end

  def tool_add_tags_to_course(args)
    api_request(:post, "/api/v1/courses/#{args['course_id']}/tags", {
      tag_ids: args['tag_ids']
    })
  end

  def tool_remove_tag_from_course(args)
    api_request(:delete, "/api/v1/courses/#{args['course_id']}/tags/#{args['tag_id']}")
  end

  # -------------------------------------------------------------------
  # HTTP client
  # -------------------------------------------------------------------

  def api_request(method, path, body = nil, skip_auth: false)
    unless skip_auth || @api_token
      return { error: 'Not authenticated. Call the "authenticate" tool first with your email and password, or set the CORSEGO_API_TOKEN environment variable.' }
    end

    uri = URI.join(@base_url, path)

    request = case method
              when :get    then Net::HTTP::Get.new(uri)
              when :post   then Net::HTTP::Post.new(uri)
              when :patch  then Net::HTTP::Patch.new(uri)
              when :put    then Net::HTTP::Put.new(uri)
              when :delete then Net::HTTP::Delete.new(uri)
              end

    request['Content-Type'] = 'application/json'
    request['Accept'] = 'application/json'
    request['Authorization'] = "Bearer #{@api_token}" unless skip_auth
    request.body = JSON.generate(body) if body

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = 10
    http.read_timeout = 30

    response = http.request(request)
    JSON.parse(response.body)
  rescue Errno::ECONNREFUSED
    { error: "Cannot connect to Corsego at #{@base_url}. Is the server running?" }
  rescue Net::OpenTimeout, Net::ReadTimeout
    { error: "Request to Corsego timed out." }
  rescue JSON::ParserError
    { error: "Invalid response from server (status #{response&.code})" }
  rescue => e
    { error: "Request failed: #{e.message}" }
  end

  # -------------------------------------------------------------------
  # JSON-RPC helpers
  # -------------------------------------------------------------------

  def jsonrpc_response(id, result)
    { jsonrpc: '2.0', id: id, result: result }
  end

  def error_response(id, code, message)
    { jsonrpc: '2.0', id: id, error: { code: code, message: message } }
  end

  def write_response(response)
    json = JSON.generate(response)
    $stdout.write(json + "\n")
    $stdout.flush
  end
end

# Run the server
CorsegoMcpServer.new.run
