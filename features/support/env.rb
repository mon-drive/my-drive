require 'cucumber/rails'
require 'capybara'
require 'capybara/cucumber'
require 'selenium-webdriver'

Capybara.default_driver = :selenium_chrome
Capybara.javascript_driver = :selenium_chrome
Capybara.default_max_wait_time = 10

Capybara.register_driver :selenium_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36')
  options.add_argument('--disable-blink-features=AutomationControlled')
  options.add_preference("excludeSwitches", ["enable-automation"])
  options.add_preference('useAutomationExtension', false)
  options.add_argument('--start-maximized')
  
  driver = Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  driver.browser.execute_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")

  driver
end

Capybara.app_host = "http://localhost:3000"

Capybara.configure do |config|
  config.default_driver = :selenium_chrome
  config.javascript_driver = :selenium_chrome
end

ActionController::Base.allow_rescue = false

begin
  DatabaseCleaner.strategy = :transaction
rescue NameError
  raise "You need to add database_cleaner to your Gemfile (in the :test group) if you wish to use it."
end

Cucumber::Rails::Database.javascript_strategy = :truncation

