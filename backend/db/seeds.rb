# frozen_string_literal: true

user = User.find_or_create_by!(email: 'demo@example.com') do |u|
  u.name = 'Demo User'
  u.password = 'password123'
end

3.times do |i|
  user.posts.find_or_create_by!(title: "Sample Post #{i + 1}") do |post|
    post.body = "This is the body for sample post #{i + 1}."
  end
end

puts "Seeded demo user (demo@example.com / password123) with #{user.posts.count} posts."
