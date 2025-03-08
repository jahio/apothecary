namespace :db do
  desc "Rebuilds the database in development mode after dropping and recreating it"
  task :rebuild => :environment do
    puts "Refusing to run outside development mode!" && exit unless Rails.env.development?

    ["db:drop", "db:create", "db:migrate", "db:seed"].each do |t|
      Rake::Task[t].invoke
    end
  end
end
