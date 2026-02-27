# frozen_string_literal: true

require 'test_helper'

class ContentSecurityPolicyTest < ActionDispatch::IntegrationTest
  test "responses include Content-Security-Policy header" do
    get root_url
    assert_response :success
    csp = response.headers['Content-Security-Policy']
    assert csp.present?, "Expected Content-Security-Policy header to be present"
  end

  test "CSP blocks inline scripts without nonce" do
    get root_url
    csp = response.headers['Content-Security-Policy']
    assert_no_match(/unsafe-inline/, csp.split('script-src').last.split(';').first,
                    "script-src should not allow unsafe-inline")
  end

  test "CSP restricts object-src to none" do
    get root_url
    csp = response.headers['Content-Security-Policy']
    assert_match(/object-src 'none'/, csp)
  end

  test "CSP allows required frame sources for video embeds" do
    get root_url
    csp = response.headers['Content-Security-Policy']
    frame_src = csp[/frame-src[^;]*/]
    assert frame_src.present?, "Expected frame-src directive"
    assert_match(/player\.vimeo\.com/, frame_src)
    assert_match(/www\.youtube-nocookie\.com/, frame_src)
  end
end
