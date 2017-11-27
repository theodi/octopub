[![Build Status](http://img.shields.io/travis/theodi/octopub.svg)](https://travis-ci.org/theodi/octopub)
[![Dependency Status](http://img.shields.io/gemnasium/theodi/octopub.svg)](https://gemnasium.com/theodi/octopub)
[![Coverage Status](http://img.shields.io/coveralls/theodi/octopub.svg)](https://coveralls.io/r/theodi/octopub)
[![Code Climate](http://img.shields.io/codeclimate/github/theodi/octopub.svg)](https://codeclimate.com/github/theodi/octopub)
[![License](http://img.shields.io/:license-mit-blue.svg)](http://theodi.mit-license.org)
[![Dependency Status](https://dependencyci.com/github/theodi/octopub/badge)](https://dependencyci.com/github/theodi/octopub)
[![Badges](http://img.shields.io/:badges-7/7-ff6799.svg)](https://github.com/badges/badgerbadgerbadger)


# Octopub

[Octopub](http://octopub.io/) is a Ruby on Rails application that provides a simple and frictionless way for users to publish data easily, quickly and correctly on GitHub.

## Summary of features

More information is in the announcement [blog post](http://theodi.org/blog/removing-barriers-to-publishing-open-data)

The live instance of Octopub is running at [http://octopub.io/](http://octopub.io/)

Follow the [public feature roadmap](https://trello.com/b/2xc7Q0kd/labs-public-toolbox-roadmap?menu=filter&filter=label:Octopub) for Octopub

## Requirements

These are the tools and services required to get Octopub fully working for development, testing and production environments. We'll explain how to set these up in the next section.

* Ruby 2.4
* PostgreSQL
* Redis/Sidekiq
* GitHub account
* AWS account
* Pusher account
* [Open Data Certificates](https://certificates.theodi.org/en/) account

## Setup

### Redis/Sidekiq

Sidekiq is used for managing the background proccessing of data uploads. To use Sidekiq just install Redis by following the instructions [here](https://redis.io/topics/quickstart), or if you are using Homebrew you can just do ```brew install redis```.

### Environment variables

For development Octopub uses the [dotenv](https://github.com/bkeepers/dotenv) gem to load environment variables. Create a file called ```.env``` in your project root and paste in the variables below. We'll fill these in as we go along.

```
# GitHub App Client ID & secret
GITHUB_KEY=
GITHUB_SECRET=

# OAuth access token for GitHub API access
GITHUB_TOKEN=

S3_BUCKET=

AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=

PUSHER_APP_ID=
PUSHER_KEY=
PUSHER_SECRET=
PUSHER_CLUSTER=

BASE_URI=
ODC_API_KEY=
ODC_USERNAME=

# production only
SMTP_USERNAME=
SMTP_PASSWORD=
SMTP_SERVER=
```

#### GitHub

Create a GitHub application:

1. Log in to GitHub.
2. In ```Settings -> Developer settings -> OAuth applications```, create a new OAuth application with a unique name. You can use ```http://octopub.io``` for the homepage and for the callback URL use your local server address, i.e. ```http://localhost:3000```. Click on your OAuth application to see your ```Client ID``` and ```Client Secret```, and update your ```.env``` file:

```
GITHUB_KEY=<YOUR CLIENT ID>
GITHUB_SECRET=<YOUR CLIENT SECRET>
```

3. In ```Settings -> Developer settings -> Personal access tokens```, generate a new token with a sensible description, e.g. octopub_dev_token, and update your ```.env``` file:

```
GITHUB_TOKEN=<Your token>
```

#### AWS

Create an S3 bucket:

1. In AWS go to the S3 service and create a bucket with a sensible name. **Make sure the region is set to EU(Ireland) since Octopub uses this.**
2. Click on your bucket and go to the ```Permissions``` tab. Click on ```CORS Configuration``` and paste in the configuration below. This will allow your local development version of Octopub to make requests to your S3 bucket.
```
<?xml version="1.0" encoding="UTF-8"?>
<CORSConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
<CORSRule>
    <AllowedOrigin>http://localhost:3000</AllowedOrigin>
    <AllowedMethod>GET</AllowedMethod>
    <AllowedMethod>POST</AllowedMethod>
    <AllowedMethod>PUT</AllowedMethod>
    <AllowedHeader>*</AllowedHeader>
</CORSRule>
</CORSConfiguration>
```
Grant permissions to your bucket:

1. In AWS go to the IAM (Identity and Access Management page) service.
2. Click ```Users```.
3. Add a new user and give it a name, e.g. octopub-development, and for Access Type select ```Programmatic Access```.
4. For permissions, select ```Attach existing policies directly``` - this will open a new tab in your browser.
5. Click ```create your own policy``` and give it a name, e.g. octopub-dev-permissions. Then for the policy document, use the following template, but add your bucket name in place of ```<BUCKETNAME>```.
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
                "arn:aws:s3:::<YOUR BUCKET NAME>",
                "arn:aws:s3:::<YOUR BUCKET NAME>/*"
            ]
        }
    ]
}
```
6. Click ```validate policy``` just to be sure you've not made a typo, then confirm.
7. Back on the ```Set permissions page```, select the policy you've just created in the table by selecting the checkbox, then click ```Review``` and then click ```Create user```.
8. Download the CSV file containing your ```Access key ID``` and ```Secret access key``` and update your ```.env``` file:

```
AWS_ACCESS_KEY_ID=<YOUR ACCESS KEY ID>
AWS_SECRET_ACCESS_KEY=<YOUR SECRET ACCESS KEY>
S3_BUCKET=<YOUR BUCKET NAME>
```

#### Pusher

1. Log in to https://pusher.com or create a free account.
2. Create a new application and call it something sensible.
3. Select the ```App Keys``` tab and use the relevant values there to update your ```.env``` file:

```
PUSHER_APP_ID=
PUSHER_KEY=
PUSHER_SECRET=
PUSHER_CLUSTER=
```

#### ODC (open data certificate) setup

1. Log in to https://certificates.theodi.org/ or create a free account.
2. Go to your profile page, copy your API token and update your ```.env``` file:

```
ODC_API_KEY=<API TOKEN>
ODC_USERNAME=<YOUR USERNAME (email address you used when signing up)>
```

## Running the full application locally

Assuming you have completed the setup instructions above...

* Start Redis with ```redis-server```.
* Start Sidekiq with ```bundle exec sidekiq``` in the application directory.
* Create the postgresql databases specified in ```config/database.yml``` and run ```rails db:migrate```.
* Start Octopub with ```rails s``` in the application directory. 
* Navigate to the home page.
* Sign into octopub with your GitHub account.

Congratulations, you should be signed in! Now try adding some data.

### Checking the Sidekiq queue

Start a rails console session and then...

```
require 'sidekiq/api'
Sidekiq::Queue.new.size
Sidekiq::Queue.new.first
```
### Tests

Octopub uses the ```rspec``` test framework and requires the presence of a ```.env```. See earlier section for details as you can (re)use your development variables*

The test suite can be run with ```bundle exec rspec```.  

\* Note - the tests use VCR or mocking to allow the tests to be run offline without interfacing with the services.

## Deployment

A commit to master will trigger a TravisCI run; If successful it will automatically deploy to Heroku.

## Caching

The GitHub organisations are cached for the logged in user. They can be cleared from a console with ```Rails.cache.clear```