# Application template recipe for the rails_apps_composer. Change the recipe here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/setup.rb

## Ruby on Rails
say_wizard "You are using Ruby version #{RUBY_VERSION}."
say_wizard "You are using Rails version #{Rails::VERSION::STRING}."

## Git
say_wizard "initialize git"
prefs[:git] = true unless prefs.has_key? :git
if prefer :git, true
  begin
    remove_file '.gitignore'
    get 'https://raw.github.com/RailsApps/rails3-application-templates/master/files/gitignore.txt', '.gitignore'
  rescue OpenURI::HTTPError
    say_wizard "Unable to obtain gitignore file from the repo"
  end
  git :init
  git :add => '.'
  git :commit => "-aqm 'rails_apps_composer: initial commit'"
end

## Is sqlite3 in the Gemfile?
f = File.open(destination_root() + '/Gemfile', "r")
gemfile = ''
f.each_line do |line|
  gemfile += line
end
sqlite_detected = gemfile.include? 'sqlite3'

## Web Server
prefs[:dev_webserver] = multiple_choice "Web server for development?", [["WEBrick (default)", "webrick"], 
  ["Thin", "thin"], ["Unicorn", "unicorn"], ["Puma", "puma"]] unless prefs.has_key? :dev_webserver
webserver = multiple_choice "Web server for production?", [["Same as development", "same"], 
  ["Thin", "thin"], ["Unicorn", "unicorn"], ["Puma", "puma"]] unless prefs.has_key? :prod_webserver
if webserver == 'same'
  case prefs[:dev_webserver]
    when 'thin'
      prefs[:prod_webserver] = 'thin'
    when 'unicorn'
      prefs[:prod_webserver] = 'unicorn'
    when 'puma'
      prefs[:prod_webserver] = 'puma'
  end
else
  prefs[:prod_webserver] = webserver
end

## Database Adapter
prefs[:database] = multiple_choice "Database used in development?", [["SQLite", "sqlite"], ["PostgreSQL", "postgresql"], 
  ["MySQL", "mysql"], ["MongoDB", "mongodb"]] unless prefs.has_key? :database
case prefs[:database]
  when 'mongodb'
    unless sqlite_detected
      prefs[:orm] = multiple_choice "How will you connect to MongoDB?", [["Mongoid","mongoid"]] unless prefs.has_key? :orm
    else
      raise StandardError.new "SQLite detected in the Gemfile. Use '-O' or '--skip-activerecord' as in 'rails new foo -O' if you don't want ActiveRecord and SQLite"
    end
end

## Template Engine
prefs[:templates] = multiple_choice "Template engine?", [["ERB", "erb"], ["Haml", "haml"], ["Slim", "slim"]] unless prefs.has_key? :templates

## Testing Framework
if recipes.include? 'testing'
  prefs[:unit_test] = multiple_choice "Unit testing?", [["Test::Unit", "test_unit"], ["RSpec", "rspec"]] unless prefs.has_key? :unit_test
  prefs[:integration] = multiple_choice "Integration testing?", [["RSpec with Capybara", "capybara"], 
    ["Cucumber with Capybara", "cucumber"], ["Turnip with Capybara", "turnip"]] unless prefs.has_key? :integration
  prefs[:fixtures] = multiple_choice "Fixture replacement?", [["None","none"], ["Factory Girl","factory_girl"], ["Machinist","machinist"]] unless prefs.has_key? :fixtures
end

## Front-end Framework
if recipes.include? 'frontend'
  prefs[:frontend] = multiple_choice "Front-end framework?", [["None", "none"], ["Twitter Bootstrap", "bootstrap"], 
    ["Zurb Foundation", "foundation"], ["Skeleton", "skeleton"], ["Just normalize CSS for consistent styling", "normalize"]] unless prefs.has_key? :frontend
  if prefer :frontend, 'bootstrap'
    prefs[:bootstrap] = multiple_choice "Twitter Bootstrap version?", [["Twitter Bootstrap (Less)", "less"],
      ["Twitter Bootstrap (Sass)", "sass"]] unless prefs.has_key? :bootstrap
  end
end

## Email
if recipes.include? 'email'
  prefs[:email] = multiple_choice "Add support for sending email?", [["None", "none"], ["Gmail","gmail"], ["SMTP","smtp"], 
    ["SendGrid","sendgrid"], ["Mandrill","mandrill"]] unless prefs.has_key? :email
else
  prefs[:email] = 'none'
end

## Authentication and Authorization
if recipes.include? 'auth'
  prefs[:authentication] = multiple_choice "Authentication?", [["None", "none"], ["Devise", "devise"], ["OmniAuth", "omniauth"]] unless prefs.has_key? :authentication
  case prefs[:authentication]
    when 'devise'
      if prefer :orm, 'mongoid'
        prefs[:devise_modules] = multiple_choice "Devise modules?", [["Devise with default modules","default"]] unless prefs.has_key? :devise_modules
      else
        prefs[:devise_modules] = multiple_choice "Devise modules?", [["Devise with default modules","default"], ["Devise with Confirmable module","confirmable"], 
          ["Devise with Confirmable and Invitable modules","invitable"]] unless prefs.has_key? :devise_modules
      end
    when 'omniauth'
      prefs[:omniauth_provider] = multiple_choice "OmniAuth provider?", [["Facebook", "facebook"], ["Twitter", "twitter"], ["GitHub", "github"], 
        ["LinkedIn", "linkedin"], ["Google-Oauth-2", "google-oauth2"], ["Tumblr", "tumblr"]] unless prefs.has_key? :omniauth_provider
  end
  prefs[:authorization] = multiple_choice "Authorization?", [["None", "none"], ["CanCan with Rolify", "cancan"]] unless prefs.has_key? :authorization
end

## MVC
if (recipes.include? 'models') && (recipes.include? 'controllers') && (recipes.include? 'views') && (recipes.include? 'routes')
  if prefer :authorization, 'cancan'
    prefs[:starter_app] = multiple_choice "Install a starter app?", [["None", "none"], ["Home Page", "home_app"], 
      ["Home Page, User Accounts", "users_app"], ["Home Page, User Accounts, Admin Dashboard", "admin_app"]] unless prefs.has_key? :starter_app
  elsif prefer :authentication, 'devise'
    if prefer :orm, 'mongoid'
      prefs[:starter_app] = multiple_choice "Install a starter app?", [["None", "none"], ["Home Page", "home_app"], 
        ["Home Page, User Accounts", "users_app"], ["Home Page, User Accounts, Subdomains", "subdomains_app"]] unless prefs.has_key? :starter_app
    else
      prefs[:starter_app] = multiple_choice "Install a starter app?", [["None", "none"], ["Home Page", "home_app"], 
        ["Home Page, User Accounts", "users_app"]] unless prefs.has_key? :starter_app
    end
  elsif prefer :authentication, 'omniauth'
    prefs[:starter_app] = multiple_choice "Install a starter app?", [["None", "none"], ["Home Page", "home_app"], 
      ["Home Page, User Accounts", "users_app"]] unless prefs.has_key? :starter_app
  else
    prefs[:starter_app] = multiple_choice "Install a starter app?", [["None", "none"], ["Home Page", "home_app"]] unless prefs.has_key? :starter_app
  end
  if (recipes.include? 'prelaunch') && (prefer :authentication, 'devise') && (prefer :authorization, 'cancan')
    prefs[:prelaunch_app] = multiple_choice "Install a prelaunch app?", [["None", "none"], ["Prelaunch Signup App", "signup_app"]]
    if prefs[:prelaunch_app] == 'signup_app'
      prefs[:devise_modules] = 'confirmable'
      prefs[:bulkmail] = multiple_choice "Send news and announcements with a mail service?", [["None", "none"], ["MailChimp","mailchimp"]]
      if prefer :git, true
        prefs[:prelaunch_branch] = multiple_choice "Git branch for the prelaunch app?", [["wip (work-in-progress)", "wip"], ["master", "master"], ["prelaunch", "prelaunch"], ["staging", "staging"]]
        if prefs[:prelaunch_branch] == 'master'
          prefs[:main_branch] = multiple_choice "Git branch for the main app?", [["None (delete)", "none"], ["wip (work-in-progress)", "wip"], ["edge", "edge"]]
        end
      end
    end
  end
end

__END__

name: setup
description: "Make choices for your application."
author: RailsApps

category: configuration
