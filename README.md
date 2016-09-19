# Kafka Consumers

Sidekiq worker process that controls the kafka consumers.

## Consumers

Currently there are four consumers and one worker, all located [here](/lib/consumers):

- attribution: listens to install events and matches these to clicks,
  to attribute the user to a network. Generates conversion events when a
  match is identified.
- clickstore: responsible for store click events to redis and collection
  statistics on campaign links
- conversion: responsible for handling conversion events and generating
  postback calls for these events.
- postbacks: generates postbacks calls for all events where required.
  This does not handle conversion events.
- url_worker: worker for triggering postback urls generated by the postbacks
  and conversion consumers.

## Design

Consumers are sidekiq workers and are run by sidekiq. However these are not
directly scheduled with sidekiq, instead for each consumer, there is a
[scheduler](/lib/schedulers) that queues the consumers to be executed.

The intention is to have short running processes consuming events and then
stoping, only to be restarted by the scheduler. This avoids have memory leaks
or zombie consumer processes.

## Kafka Message Format

An example of a typical kafka message:

```
/t/ist bot_name&country=DE&device=smartphone&device_name=iPhone&ip=3160898477&klag=1&platform=ios&ts=1465287056 adid=ECC27E57-1605-2714-CCCC-13DC6DFB742E
```

1. First comes the event type, the actual type is assumed to be everything
   after the final '/' (slash).
2. Meta dataset, this is in the form of CGI encoded parameter/value pairs.
   The meta data is generated exclusively by the kafkastore and its values
   are based on the IP and user agent information. In addition, there is
   ```klag``` value the represents the time (in seconds) of how long the
   message waited in [redis before being pushed to kafka](https://github.com/adtekio/kafkastore/blob/a9e3670011c71fcc669a46e62df95d06683cae79/lib/batch_worker.rb#L32).
3. Query string of the original request. This is just passed through from
   the tracker, unmodified.

If this format should change, then the [consumers need updating](https://github.com/adtekio/consumers/blob/b71a17d9f8669f232036670c71c54adca6186ef3/lib/kafka/event.rb#L11). However this is only the case if the format changes
(i.e. ```<type> <meta> <params>```), not if there are extra "meta" or
"query" parameters included.

Also if the format is changed here, then the [kafkastore](https://github.com/adtekio/kafkastore/blob/dbb7acde4dd70e22fe1f6fc8565d7553a0cd6f6e/lib/batch_inserter.rb#L20-L21)
needs updating.

The [format is explained in more details elsewhere](https://github.com/adtekio/kafkastore#kafka-message-format).


## Development

Generate a ```.env``` and then fill it with values:

    prompt> rake appjson:to_dotenv
    prompt> $EDITOR .env

Start the worker and web frontend with:

    prompt> foreman start web
    prompt> foreman start worker

## Deployment

Easiest way to deploy this, is to use heroku!

[![Deploy To Heroku](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy?template=https://github.com/adtekio/consumers)

## Travis

[![Build Status](https://travis-ci.org/adtekio/consumers.svg?branch=master)](https://travis-ci.org/adtekio/consumers)
