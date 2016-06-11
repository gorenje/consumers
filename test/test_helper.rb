ENV['RAILS_ENV']    = 'test' # ensures that settings.environment == 'test'
ENV['RACK_ENV']     = 'test'
ENV['IP']           = 'www.example.com'
ENV['PORT']         = '9999'
ENV['TZ']           = 'UTC'

ENV['DATABASE_URL']          = ENV['DATABASE_URL'] + "_test"
ENV['REDISTOGO_URL']         = "redis://localhost:6379/15"
ENV['CLICK_STATS_REDIS_URL'] = "redis://localhost:6379/15"
ENV['CLICK_REDIS_URL']       = "redis://localhost:6379/15"

require "bundler/setup"
require 'rack/test'
require 'shoulda'
require 'rr'
# use binding.pry at any point of the tests to enter the pry shell
# and pock around the current object and state
#    https://github.com/pry/pry/wiki/Runtime-invocation
require 'pry'
require 'fakeweb'
require 'minitest/autorun'

require_relative '../application.rb'
require_relative 'redis_overrides.rb'
require_relative 'event_payloads.rb'

raise "Not Using Test Environment" if settings.environment != 'test'

FakeWeb.register_uri(:post, /metrics-api.librato.com/, :status => 200)

class Minitest::Test
  include RR::Adapters::TestUnit

  def _pry
    binding.pry
  end

  def replace_in_env(changes)
    original_values = Hash[changes.map { |k,_| [k,ENV[k] ]}]
    changes.each { |k,v| ENV[k] = v }
    yield
  ensure
    original_values.each { |key,value| ENV[key] = value }
  end

  def add_to_env(changes)
    changes.each { |k,v| ENV[k] = v }
    yield
  ensure
    changes.keys.each { |key| ENV.delete(key) }
  end

  def assert_not_match(regexp, str, msg = nil)
    assert !(str =~ regexp), msg
  end

  def assert_redirect_to(path, msg = nil)
    assert(last_response.redirect?,
           "Request was not redirect" + (msg ? " (#{msg})" : ""))
    assert_equal('http://example.org/%s' % [path],
                 last_response.headers["Location"],
                 "Redirect location didn't match"+ (msg ? " (#{msg})" : ""))
  end

  def kafka_mock(group_id, topic, loop_count, msg)
    kafka_message = OpenStruct.new({ :offset => 1, :value => msg })

    Object.new.tap do |o|
      mock(o).consumer(:group_id => group_id) { o }
      mock(o).subscribe(topic)
      mock(o).each_message(:loop_count => loop_count).yields(kafka_message)
    end
  end

  def silence_is_golden
    old_stderr,old_stdout,stdout,stderr =
      $stderr, $stdout, StringIO.new, StringIO.new

    $stdout = stdout
    $stderr = stderr
    result = yield
    [result, stdout.string, stderr.string]
  ensure
    $stderr, $stdout = old_stderr, old_stdout
  end

  def generate_postback( overrides = {})
    Postback.create({ :network       => "test",
                      :event         => "ist",
                      :platform      => "all",
                      :user_id       => 1,
                      :user_required => false,
                      :store_user    => false,
                      :env           => { },
                      :url_template  => "http://localhost/fubar"
                    }.merge(overrides))
  end
end
