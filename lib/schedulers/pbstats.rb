require 'sidekiq/api'
require_relative 'base'

module Scheduler
  class Pbstats < Scheduler::Base
    def initialize(*args)
      super(*args)
      @klz = Consumers::Pbstats
    end
  end
end
