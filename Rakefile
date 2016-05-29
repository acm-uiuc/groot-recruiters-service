require './app'
require 'rake'
require 'pry'

namespace :db do

  desc "Migrate the database"
  task :migrate do
    puts "Migrating database"
    DataMapper.auto_migrate!
  end

  desc "Upgrade the database"
  task :upgrade do
    puts "Upgrading the database"
    DataMapper.auto_upgrade!
  end

  desc "Populate the database with dummy data by running scripts/applicants.rb"
  task :seed do
    puts "Seeding database"
    require './scripts/applicants.rb'
  end

  desc "Migrate and Seed database"
  task :funky => [ "db:migrate", "db:seed" ]
end


namespace :generate do

  desc "Add new spec file"
  task :spec do
    unless ENV.has_key?('NAME')
      raise "Must specify spec file name, e.g., rake generate:spec NAME=craftsman_profile"
    end

    spec_path = "spec/" + ENV['NAME'].downcase + "_spec.rb"

    if File.exist?(spec_path)
      raise "ERROR: Spec file '#{spec_path}' already exists."
    end

    puts "Creating #{spec_path}"
    File.open(spec_path, 'w+') do |f|
      f.write("require 'spec_helper'")
    end
  end

end

desc 'Start Pry with application environment loaded'
task :pry  do
    exec "pry -r./init.rb"
end
