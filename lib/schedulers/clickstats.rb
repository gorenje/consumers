require 'sidekiq/api'
require_relative 'base'

module Scheduler
  class Clickstats < Scheduler::Base
    def initialize(*args)
      super(*args)
      @klz = Consumers::Clickstats
    end
  end
end
