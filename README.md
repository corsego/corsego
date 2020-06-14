# Corsego - online learning platform.

###### Best udemy clone on the market. Set up your online school in minutes!

[![N|Solid](https://i.imgur.com/Hvjl2YJ.png)](https://corsego.herokuapp.com)

### Entity-Relationship Diagram

[![N|Solid](https://i.imgur.com/IIWWYxW.png)](https://corsego.herokuapp.com)

### Installation Requirements 
* ruby v 2.7.1 +
* rails 6.0.3 +
* postgresql database
* yarn

### Connected services required
* google recaptcha for signing up ** in development & production **
* google analytics in production
* AWS S3 - file storage in production
* google oauth ** in development and production **

### Installation

1. Create app
```
git clone https://github.com/yshmarov/corsego
cd corsego
bundle
yarn
bundle update
rake db:create
rake db:migrate

sudo apt-get install graphviz
sudo apt install imagemagick
```
2. Set up your secret credentials:

Go to **config** folder and delete the file `credentials.yml.enc`
```
EDITOR=vim rails credentials:edit
```
and inside the file:
```
aws:
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

```
* i = to make the file editable
* ESC + : + w + q + Enter = save changes in the file

3. Run the server
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
