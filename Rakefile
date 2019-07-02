require_relative "config/environment"
require 'sinatra/activerecord/rake'

desc 'Start our app console'
task :console do
    Pry.start
end

desc 'Run the app'
task :run do
  cli = CLI.new
  cli.start
end
