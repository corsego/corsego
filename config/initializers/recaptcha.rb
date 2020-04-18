# config/initializers/recaptcha.rb
Recaptcha.configure do |config|
  config.site_key  = '6Le09eoUAAAAAL-oQMopCXt4ZQ0mmue3OCa-i-ZZ'
  config.secret_key = '6Le09eoUAAAAABYyCfE0fcK6y67q7VRWwcbjIXGq'
  # Uncomment the following line if you are using a proxy server:
  # config.proxy = 'http://myproxy.com.au:8080'
end