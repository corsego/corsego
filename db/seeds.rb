if User.find_by_email("admin@example.com").nil?
  admin = User.create!(email: "admin@example.com", password: "admin@example.com", password_confirmation: "admin@example.com", confirmed_at: Time.now)
  # admin.skip_confirmation!
  admin.add_role(:admin) unless admin.has_role?(:admin)
  admin.add_role(:teacher) unless admin.has_role?(:teacher)
end

# Enrollment.create(user_id: 298, course_id: 56, price: 0)

if User.find_by_email("studentteacher@example.com").nil?
  studentteacher = User.create!(email: "studentteacher@example.com", password: "studentteacher@example.com", password_confirmation: "studentteacher@example.com", confirmed_at: Time.now)
  # studentteacher.skip_confirmation!
  studentteacher.add_role(:teacher) unless studentteacher.has_role?(:teacher)
  studentteacher.add_role(:student) unless studentteacher.has_role?(:student)
end

if User.find_by_email("student@example.com").nil?
  student = User.create!(email: "student@example.com", password: "student@example.com", password_confirmation: "student@example.com", confirmed_at: Time.now)
  # student.skip_confirmation!
  student.add_role(:student) unless student.has_role?(:student)
end

PublicActivity.enabled = false

5.times do
  Course.create!([{
    title: Faker::Educator.course_name,
    marketing_description: Faker::Quote.famous_last_words,
    description: Faker::TvShows::GameOfThrones.quote,
    user: User.find_by(email: "admin@example.com"),
    language: "English",
    level: "All levels",
    # price: Faker::Number.between(from: 1000, to: 20000),
    price: 0,
    approved: true,
    published: true
  }])
end

5.times do
  Course.create!([{
    title: Faker::Educator.course_name,
    marketing_description: Faker::Quote.famous_last_words,
    description: Faker::TvShows::GameOfThrones.quote,
    user: User.find_by(email: "studentteacher@example.com"),
    language: Faker::ProgrammingLanguage.name,
    level: "Beginner",
    # price: Faker::Number.between(from: 1000, to: 20000),
    price: 0,
    approved: true,
    published: true
  }])
end

Course.all.each do |course|
  10.times do
    Lesson.create!([{
      title: Faker::Lorem.sentence(word_count: 3),
      content: Faker::Lorem.sentence,
      course: course
    }])
  end

  Enrollment.create!([{
    user: User.find_by(email: "studentteacher@example.com"),
    course: course
  }])

  Enrollment.create!([{
    user: User.find_by(email: "student@example.com"),
    course: course,
    price: course.price
  }])
end

PublicActivity.enabled = true
