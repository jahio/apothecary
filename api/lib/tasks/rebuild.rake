namespace :db do
  desc "Rebuilds the database in development mode after dropping and recreating it"
  task :rebuild => :environment do
    puts "Refusing to run outside development mode!" && exit unless Rails.env.development?

    ["db:drop", "db:create", "db:migrate", "db:seed"].each do |t|
      Rake::Task["db:force_disconnect"].invoke
      Rails.logger.info(["Proceeding with task", t].join(" "))
      Rake::Task[t].invoke
    end
  end

  desc "Forcibly disconnects clients before invoking db:rebuild"
  task :force_disconnect => :environment do
    db_config = ActiveRecord::Base.connection_db_config.configuration_hash

    dcon_q = <<~END_QUERY
      SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity
      WHERE pg_stat_activity.datname='#{db_config['database']}'
      AND pid <> pg_backend_pid();
    END_QUERY

    warning = <<~END_MSG
      There's a possible rare edge case where a thread in the primary Puma Ruby process may try to re-establish the database connection in the small sub-second space between when this task disconnects all other processes, and when it kicks off the rebuild.
      If that happens, you might see error messages like "other connections are using the database" or something to that effect.
      Should this occur, simply re-run this task.
    END_MSG

    puts warning

    # AR may not always disconnect immediately; therefore, we first forcibly disconnect on purpose
    ActiveRecord::Base.connection.disconnect!

    # NOW, we can execute a disconnect from the manual query above, forcing other clients to disconnect
    conn = PG.connect(ENV.fetch("DATABASE_URL", { db_name: db_config['database'] }))
    conn.exec(dcon_q)
    conn.close

    # So subsequent queries work, now we reconnect to AR/DB
    ActiveRecord::Base.establish_connection(Rails.env.to_sym)

    Rails.logger.warn("Disconnected other clients; proceeding...")
  end
end
