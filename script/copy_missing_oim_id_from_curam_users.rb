users = User.where(oim_id: nil)

users.no_timeout.each do |user|
  # Copy from curan_users
  if user.person.present? && CuramUser.match_unique_login(user.email).first.present?
    user.oim_id = CuramUser.match_unique_login(user.email).first.username
    user.save!
    puts "#{user.email} :  oim_id updated from curam_users table"
  end   
end
puts "Process Completed!"
