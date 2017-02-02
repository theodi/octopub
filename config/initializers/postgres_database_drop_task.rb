# config/initializers/postgresql_database_tasks.rb
module ActiveRecord
  module Tasks
    class PostgreSQLDatabaseTasks
      def drop
        if Rails.env.development?
          establish_master_connection
          connection.select_all "select pg_terminate_backend(pg_stat_activity.pid) from pg_stat_activity where datname='#{configuration['database']}' AND state='idle';"
          connection.drop_database configuration['database']
        end
      end
    end
  end
end