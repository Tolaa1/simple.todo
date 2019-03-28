require "tty-prompt"
require "rest-client"
require "json"
require "tty"
require "colorize"
require "terminal-table"

class CLI
  def initialize
    # Init app
    @prompt = TTY::Prompt.new
    @tasks = []
  end

  ####################
  # General
  ####################

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

  def exit_message
    puts "Bye #{@user["name"]}, have a nice day!".light_blue
  end

  def ask_choice
    # Prompts the user the main menu
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
    # Process user response from main menu

    # Fetch todos for the user everytime to be sure our list is up to date
    fetch_tasks()

    if arg == :view
      display_response(fetch_tasks())
    elsif arg == :add
      adds_task()
    elsif arg == :delete
      delete_task()
    elsif arg == :edit
      update_task()
    elsif arg == :quit
      exit_message()
    end
  end

  def danger(arg)
    if arg == "High"
      arg.red
    elsif arg == "Normal"
      arg.yellow
    elsif arg == "Low"
      arg.green
    end
  end

  def start
    # Main controller
    prompt_user()
    welcome()
    ask_choice()
  end

  def no_task
    puts "You have no tasks.".red
    ask_choice()
  end

  ####################
  # View
  ####################

  def fetch_tasks
    # Asks for every task that is related to the current user
    begin
      res = RestClient.post("http://localhost:3000/api/v1/matches/", {id: @user["id"]})
      @tasks = JSON.parse(res)["data"]
    rescue RestClient::UnprocessableEntity => e
      puts e.response
      @tasks = []
    end
  end

  def display_response(res)
    # Process and display API response
    begin
      if res.length
        res.each_with_index do |task, index|
          puts "#{index + 1}. #{task["task"]} - Priority: #{danger(task["priority"])}"
        end
        ask_choice()
      else
        no_task()
      end
    rescue
      no_task()
    end
  end

  ####################
  # Add
  ####################

  def adds_task
    new_task = @prompt.ask("Add new todo: ")
    new_priority = prompt_priority()
    res = RestClient.post("http://localhost:3000/api/v1/todo", {data: {task: new_task, priority: new_priority}, user_id: @user["id"]})
    ask_choice()
  end

  def prompt_priority
    choices = [
      {name: "Low", value: "Low"},
      {name: "Normal", value: "Normal"},
      {name: "High", value: "High"},
    ]
    @prompt.select("Select the priority", choices.each { |item| item[:name] })
  end

  ####################
  # Update
  ####################

  def update_task
    fetch_tasks()
    if @tasks.size > 0
      selected = @prompt.select("Select a task to edit: ", @tasks.each_with_index.map { |item, index| "#{index + 1}. #{item["task"]} - Priority: #{danger(item["priority"])}" })
      parse_to_update(selected)
    else
      no_task()
    end
  end

  def parse_to_update(arg)
    new_task = @prompt.ask("Edit task: ")
    task_id = @tasks.select { |task| task["task"] == arg.split(". ")[1].split(" - ")[0] }.first["id"]
    res = RestClient.put("http://localhost:3000/api/v1/todo/#{task_id}", {data: {task: new_task, priority: prompt_priority()}})
    ask_choice()
  end


  ####################
  # Delete
  ####################

  def delete_task
    # Displays tasks and user can select which one to delete
    fetch_tasks()
    if @tasks.size > 0
      selected = @prompt.select("Select the completed task: ", @tasks.each_with_index.map { |item, index| "#{index + 1}. #{item["task"]} - Priority: #{danger(item["priority"])}" })
      parse_items(selected)
    else
      no_task()
    end
  end

  def parse_to_delete(arg)
    # Receives user_id and todo_id and sends a delete request
    task_id = @tasks.select { |task| task["task"] == arg.split(". ")[1].split(" - ")[0] }.first["id"]
    RestClient.delete("http://localhost:3000/api/v1/destroy_selected/user_id=#{@user["id"]}&todo_id=#{task_id}")
    ask_choice()
  end
end
