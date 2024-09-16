require 'rufus-scheduler'

scheduler = Rufus::Scheduler.singleton

scheduler.every '2m' do
  User.find_each do |user|
    if user.logged_in?
      DriveController.new.update_db(user)
    end
  end
end
