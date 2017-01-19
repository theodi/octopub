[![Build Status](http://img.shields.io/travis/theodi/octopub.svg)](https://travis-ci.org/theodi/octopub)
[![Dependency Status](http://img.shields.io/gemnasium/theodi/octopub.svg)](https://gemnasium.com/theodi/octopub)
[![Coverage Status](http://img.shields.io/coveralls/theodi/octopub.svg)](https://coveralls.io/r/theodi/octopub)
[![Code Climate](http://img.shields.io/codeclimate/github/theodi/octopub.svg)](https://codeclimate.com/github/theodi/octopub)
[![License](http://img.shields.io/:license-mit-blue.svg)](http://theodi.mit-license.org)
[![Dependency Status](https://dependencyci.com/github/theodi/octopub/badge)](https://dependencyci.com/github/theodi/octopub)
[![Badges](http://img.shields.io/:badges-7/7-ff6799.svg)](https://github.com/badges/badgerbadgerbadger)

# Octopub

A Rails app that provides a simple and frictionless way for users to publish data on Github.

More information is in the [announcement blog post](http://theodi.org/blog/removing-barriers-to-publishing-open-data).

Live instance is running at [http://octopub.io/](http://octopub.io/)

## Development

Checkout the repository and run ```bundle``` in the checked out directory.
The application uses sidekiq for managing the background proccessing of data uploads. To use this functionality, install ```redis``` either by following the [instructions](https://redis.io/topics/quickstart) or if on macOS and using homebrew, run ```brew install redis``` and start a redis instance running with ```redis-server```.

### Running the full application locally

Pre-requisites, GitHub account, AWS account, Pusher Account - these instructions assume you have these in place already.

#### Github setup 

Create a github application

1. Log in to github and go to ```settings```
2. Click on ```OAuth applications``` in the ```Developer settings``` section
3. Create a new OAuth application with a unique name, you can use http://octopub.io for the hompage. 
For the callback URL use your local dev machine's address, i.e. http://octopub.dev
   
Once created, you can use the client ID and client secret in your ```.env``` file as follows:
 
 ```
GITHUB_KEY=<whatever your Client ID is>
GITHUB_SECRET=<whatever your client secret is>
GITHUB_TOKEN=???
```

#### AWS setup
  
Create an AWS S3 bucket and grant it's permissions accordingly

1. Log in to your AWS account and create an S3 bucket with a sensible name
2. Now head to the AWS IAM (Identity and Access Management page)
3. Click ```Users```
4. Add user (call it something sensible like octopub-development) and select ```Programmatic Access for Access Type```.
5. For permissions, select ```Attach existing policies directly``` - this will open a new tab in your browser.
6. CLick ```create your own policy``` and give it a name, like ```octopub-dev-permissions```, then for the policy document, use the following template, but add your own bucket name instead of ```<BUCKETNAME>```.
 ```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowAdminAccessToBucketOnly",
            "Action": [
                "s3:*"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::<BUCKETNAME>",
                "arn:aws:s3:::<BUCKETNAME>/*"
            ]
        }
    ]
}
```
7. Click ```validate policy``` just to be sure you've not made a typo. Then confirm.
8. Now back on the ```Set permissions page```, select the policy you've just created in the table by selecting the checkbox. Then click ```Review``` then ```Create user```.
9. Now download the ```csv file``` containing the credentials and add the following to your ```.env``` file

```
AWS_ACCESS_KEY_ID=<YOURNEWUSERACCESSKEY>
AWS_SECRET_ACCESS_KEY=<YOURNEWUSERSECRET>
S3_BUCKET=<YOURNEWS3BUCKETNAME>
```
  
 4. Create Pusher Account
 
 	1. Create an account on pusher.com if you don't have one.
    2. Create a new application
    3. Selete 'App Keys' and get the values
  

3:Pusher.app_id = ENV['PUSHER_APP_ID']
4:Pusher.key = ENV['PUSHER_KEY']
5:Pusher.secret = ENV['PUSHER_SECRET']


   
### Now to test

* Make sure redis is running!
* Make sure Sidekiq is running!
* fire up the app
* Go to index page
* Sign in with github (your acocunt)
* Authorise in github
SIGNED IN

### Check the queue

in a rails console session 

```
require 'sidekiq/api'
Sidekiq::Queue.new.size
Sidekiq::Queue.new.first

## Tests

Octopub uses the ```rspec``` test framework and the test suite can be run with the usual ```bundle exec rspec```

## Environment variables

Create a ```.env``` file as follows to enable the tests to run succesfully. For development purposes, use your own github username if you want to run against a real instance.

```
GITHUB_USER=bert
```

## Deployment

A commit to master will trigger a TravisCI run, which, if successful, will automatically deploy to Heroku.
