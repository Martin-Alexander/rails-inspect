#!/usr/bin/env ruby

class Debug
  def self.suppress
    begin
      original_stderr = $stderr.clone
      original_stdout = $stdout.clone
      $stderr.reopen(File.new('/dev/null', 'w'))
      $stdout.reopen(File.new('/dev/null', 'w'))
      retval = yield
    rescue Exception => e
      $stdout.reopen(original_stdout)
      $stderr.reopen(original_stderr)
      raise e
    ensure
      $stdout.reopen(original_stdout)
      $stderr.reopen(original_stderr)
    end
    retval
  end
end

def load_env
  require File.expand_path('./config/environment', File.dirname(__FILE__))
end

def run_migrations
  if ActiveRecord::Base.connection.migration_context.needs_migration?
    begin
      ActiveRecord::MigrationContext.new("db/migrate").migrate
    rescue
      # Try once more after purging db
      ActiveRecord::Tasks::DatabaseTasks.purge_current
      ActiveRecord::MigrationContext.new("db/migrate").migrate
    end
  end
end

Kernel.fork do
  Debug.suppress do
    require 'railroady'

    Dir.chdir("/home/martin/some/rails/app")
    load_env
    run_migrations

    ModelsDiagram.new(OptionsStruct.new(output: "tmp_md.dot"))
      .tap(&:process)
      .tap(&:generate)
      .print

    ControllersDiagram.new(OptionsStruct.new(output: "tmp_cd.dot"))
      .tap(&:process)
      .tap(&:generate)
      .print

    system "dot -Tsvg tmp_model_diagram.dot > hike_away_models.svg"
    system "dot -Tsvg tmp_model_diagram.dot > hike_away_models.svg"
  end
end

Process.wait
