require "tty-prompt"
require "rest-client"
require "json"
require "tty"


class CLI
  def initialize
    @prompt = TTY::Prompt.new
  end

  def prompt_user
    name = @prompt.ask("What is your name?")
    get_user(name)
  end

  def get_user(name)
    res = RestClient.post("http://localhost:3000/api/v1/user", {name: name})
    response = JSON.parse(res)["data"]
    @user = response
  end

  def welcome
    puts "Hi #{@user["name"]}, welcome to TodoApp 2000!"
  end

  def ask_choice

    choices = [
      {name: "View todos", value: :view},
      {name: "Add todo", value: :add},
      {name: "Complete todo", value: :delete},
      {name: "Edit todo", value: :edit},
      {name: "Exit", value: :quit},
    ]
    controller(@prompt.select("What are you up to?", choices.each { |item| item[:name] }))
  end

  def controller(arg)
    if arg == :view
      get_tasks()
    elsif arg == :add
      puts "add"
    elsif arg == :delete
      puts "delete"
    elsif arg == :edit
      puts "edit"
    elsif arg == :quit
      puts "quit"
    end
  end

  def fetch_tasks
    res = RestClient.post("http://localhost:3000/api/v1/matches/", {id: @user["id"]})
    display_response(res)
  end

  def display_response(res)
    # Process and display API response
    response = JSON.parse(res)["data"]
    response.each_with_index do |task, index|
      puts "#{index + 1}. #{task["task"]}."
    end
  end

  def start
    prompt_user()
    welcome()
    ask_choice()
  end
end

#res = RestClient.get("http://localhost:3000/api/v1/todo", headers = {})
#response = JSON.parse(res)["data"]
#puts response["data"]
#response.each_with_index do |task, index|
#  puts "#{index + 1}. #{task["task"]}."
#end
