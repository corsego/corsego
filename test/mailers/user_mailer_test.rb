# frozen_string_literal: true

require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  setup do
    @admin = users(:admin)
    @admin.add_role(:admin)
  end

  test 'new_user sends email to admin users' do
    user = users(:student)
    mail = UserMailer.new_user(user)

    assert_emails 1 do
      mail.deliver_now
    end

    assert_includes mail.to, @admin.email
    assert_match 'registered', mail.subject
    assert_match user.email, mail.subject
  end

  test 'new_user email body contains user info' do
    user = users(:student)
    mail = UserMailer.new_user(user)

    assert_match user.email, mail.body.encoded
    assert_match user.username, mail.body.encoded
  end

  test 'new_user email is properly formatted' do
    user = users(:student)
    mail = UserMailer.new_user(user)

    assert_match 'Hello Admin', mail.body.encoded
    assert_match 'registered', mail.body.encoded
    assert_match 'Corsego', mail.body.encoded
  end
end
