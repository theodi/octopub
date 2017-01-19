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

### Running the application locally

Pre-requeisites, GitHub account, AWS account

 1. Create a github application
   1. Log in go github and go to settings
   2. Click on 'OAuth applications' in the 'Developer settings' section
   3. Create a new OAuth application with a unique name, you can use http://octopub.io for the hompage. For the callback URL use your local dev machine's address, i.e. http://octopub.dev
   
 2. Once create, you can use the client ID and client secret in your ```.env``` file as follows:
 
 NOTE GITHUB_KEY is your Client ID
 GITHUB_SECRET is your Client Secret
 
 ```
 GITHUB_KEY
 GITHUB_SECRET
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
GITHUB_TOKEN
S3_BUCKET
```
  
 3. Create an AWS and access keys bucket

   1. Log in to your AWS account and create an S3 bucket
   2. Now head to the IAM (Identitiy and Access page)
   3. Click Users
   4. Add user (call it something like octopub-developmet) and select Programmtic Access for Access Type.
   5. For permissions, select 'Attach existing policies directly' - this will open a new tab
   6. CLick create your own policy and give it a name, like octopub-dev-permissions, then for the policy document, use the following template, but add your own bucket name instead of <BUCKETNAME>
   
 ```
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

  7. Click validate policy just to b sure
  8. Now back on the Set permissions page, select the policy you've just created in the table. Then click 'REview' then 'Create user'
  
  9. Now download the csv file containing the credentials
  

   
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
