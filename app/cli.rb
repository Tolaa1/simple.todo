require "tty-prompt"
require "rest-client"
require "json"
require "tty"
require "colorize"


class CLI
  def initialize
    # Init app
    @prompt = TTY::Prompt.new
    @tasks = []
  end

  def prompt_user
    # Prompts the user for their username
    name = @prompt.ask("What is your name?")
    get_user(name)
  end

  def get_user(name)
    # Fetches user from database or creates a new one
    res = RestClient.post("http://localhost:3000/api/v1/user", {name: name})
    response = JSON.parse(res)["data"]
    @user = response
  end

  def welcome
    # Greet user
    puts "Hi #{@user["name"]}, welcome to TodoApp 2000!".light_blue
  end

  def ask_choice
    # Prompts the user the main menu
    choices = [
      {name: "View todos", value: :view},
      {name: "Add todo", value: :add},
      {name: "Complete todo", value: :delete},
      {name: "Edit todo", value: :edit},
      {name: "Exit", value: :quit}
    ]
    controller(@prompt.select("What are you up to?", choices.each { |item| item[:name] }))
  end

  def controller(arg)
    # Process user response from main menu
    fetch_tasks()

    if arg == :view
      display_response(fetch_tasks())
    elsif arg == :add
      adds_task()
    elsif arg == :delete
      delete_task()
    elsif arg == :edit
      puts "edit"
    elsif arg == :quit
      puts "quit"
    end
  end

  def fetch_tasks
    # Asks for every task that is related to the current user
    begin
      res = RestClient.post("http://localhost:3000/api/v1/matches/", {id: @user["id"]})
      @tasks = JSON.parse(res)["data"]
    rescue RestClient::UnprocessableEntity => e
      e.response

    end
  end

  def adds_task
    new_task = @prompt.ask("Add new todo: ")
    new_priority = prompt_priority()
    res = RestClient.post("http://localhost:3000/api/v1/todo", {task: new_task, priority: new_priority})
    #res = RestClient.post("http://localhost:3000/api/v1/todo", {data: {task: new_task, priority: new_priority}, user_id: @user["id"]})
  end

  def delete_task
    fetch_tasks()
    if @tasks.size > 0
      selected = @prompt.select("Select the completed task: ", @tasks.each_with_index.map {|item, index|  "#{index + 1}. #{item["task"]}"})
      parse_items(selected)
    else
      no_task()
    end
  end

  def parse_items(arg)
    task_id = @tasks.select {|task| task["task"] == arg.split(". ")[1]}.first["id"]
    res = RestClient.delete("http://localhost:3000/api/v1/destroy_selected/user_id=#{@user["id"]}&todo_id=#{task_id}")
    puts res
  end

  def display_response(res)
    # Process and display API response
    if res.code != 422
      response = JSON.parse(res)["data"]
      response.each_with_index do |task, index|
        puts "#{index + 1}. #{task["task"]}."
      end
    else
      no_task()
    end

  end

  def prompt_priority
    choices = [
      {name: "Low", value: 1},
      {name: "Normal", value: 2},
      {name: "High", value: 3}
    ]
    @prompt.select("Select the priority", choices.each { |item| item[:name] })
  end

  def no_task
    puts "You have no tasks.".red
    ask_choice()
  end


  def start
    # Main controller
    prompt_user()
    welcome()
    ask_choice()
  end
end
