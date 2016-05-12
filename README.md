Clickstore
==========

Worker process for storing in-app tracking events from redis to kafka.

Development
----------

Generate a ```.env``` and then fill it with values:

    prompt> rake appjson:to_dotenv
    prompt> $EDITOR .env

Start the worker and web frontend with:

    prompt> foreman start web
    prompt> foreman start worker

Deployment
----------

[![Deploy To Heroku](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy?template=https://github.com/eccrine/kafkastore)
