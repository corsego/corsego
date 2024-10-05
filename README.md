# Corsego - online learning platform.

###### Best udemy clone on the market. Set up your online school in minutes!

[![N|Solid](https://i.imgur.com/Hvjl2YJ.png)](https://corsego.herokuapp.com)

### Entity-Relationship Diagram

[![N|Solid](https://i.imgur.com/IIWWYxW.png)](https://corsego.herokuapp.com)

### Video: How to install

[![Corsego e-learning platform: How to run localy on ubuntu + AWS C9](http://img.youtube.com/vi/nQd03MgXDXY/0.jpg)](http://www.youtube.com/watch?v=nQd03MgXDXY "Video Title")

### Installation Requirements 
* ruby v 2.7.1 +
* rails 6.0.3 +
* postgresql database
* yarn

### Connected services required
* AWS S3 - file storage ** in production **
* Amazon SES - sending emails ** in production **
* google analytics code ** in production **
* google recaptcha API for signing up ** in development & production **
* google oauth API ** in development and production **
* github oauth API ** in development and production **
* facebook oauth API
* stripe API ** in development and production **

### 1. Installing RoR

```
rvm install ruby-2.7.1
rvm --default use 2.7.1
rvm uninstall 2.6.3
gem install rails -v 6.0.3
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update
sudo apt install postgresql libpq-dev redis-server redis-tools yarn
```

# postgresql setup

```
sudo su postgres
createuser --interactive
ubuntu
y 
exit
```

### 2. Installation the app

1. Create app
```
git clone https://github.com/rormvp/corsego
cd corsego
bundle
yarn

sudo apt-get install graphviz
sudo apt install imagemagick
```
2. IMPORTANT Set up your secret credentials, otherwise you will not be able to run the app:

Go to **config** folder and delete the file `credentials.yml.enc`
```
EDITOR=vim rails credentials:edit
```
and inside the file:
```
awss3:
  access_key_id: YOUR_CODE_FOR_S3_STORAGE
  secret_access_key: YOUR_CODE_FOR_S3_STORAGE
google_analytics: YOUR_CODE_FOR_GOOGLE_ANALYTICS
recaptcha:
  site_key: YOUR_CODE_FOR_RECAPTCHA
  secret_key: YOUR_CODE_FOR_RECAPTCHA
google_oauth2:
  client_id: YOUR_CODE_FOR_OAUTH
  client_secret: YOUR_CODE_FOR_OAUTH
development:
  github:
    client: YOUR_CODE_FOR_OAUTH
    secret: YOUR_CODE_FOR_OAUTH
  stripe:
    publishable: YOUR_STRIPE_PUBLISHABLE
    secret: YOUR_STRIPE_SECRET
production:
  github:
    client: YOUR_CODE_FOR_OAUTH
    secret: YOUR_CODE_FOR_OAUTH
  stripe:
    publishable: YOUR_STRIPE_PUBLISHABLE
    secret: YOUR_STRIPE_SECRET
facebook:
  client: YOUR_CODE_FOR_OAUTH
  secret: YOUR_CODE_FOR_OAUTH
smtp:
  address: email-smtp.eu-central-1.amazonaws.com
  user_name: SMTP_CREDENTIALS_USER_NAME
  password: SMTP_CREDENTIALS_PASSWORD
```
* i = to make the file editable
* :set paste = to disable autoindentation when pasting
* Ctrl + V = to paste
* ESC + : + w + q + Enter = save changes in the file

3. Run the migrations 
```
rails db:create
rails db:migrate
```
4. Configure your development environment in config/environments/development.rb
5. Start the server
```
rails s
```

### For production environments
```
heroku create
heroku rename *your-app-name*
heroku git:remote -a *your-app-name*
git push heroku master
heroku run rake db:migrate
heroku config:set RAILS_MASTER_KEY=`cat config/master.key`
```
If you have troubles running the app or any questions don't hesitate to contact me at yashm@outlook.com 🧐 

****

Manually creating an enrollment:

```
PublicActivity.enabled = false
Enrollment.create(user: User.find(544), course: Course.find(56), price: 0)
```

add stripe ids to all exiting products
```
Course.all.each do |course|
  product = Stripe::Product.create(name: course.title)
  price = Stripe::Price.create(product: product, currency: "usd", unit_amount: course.price.to_i * 100)
  course.update(stripe_product_id: product.id, stripe_price_id: price.id)
end
```

TODO:
fix yarn/webpacker errors. they block deployment!
bundle update
upgrade rails
upgrade puma to v5
replace google_captcha with invisible_captcha
make system tests work
lint
upgrade ruby version to 3.2.3
upgrade heroku stack to 24

heroku buildpacks:add heroku/nodejs

bundle exec rake webpacker:clobber webpacker:compile
