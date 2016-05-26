require 'sidekiq/api'
require_relative 'base'

module Scheduler
  class Attribution < Scheduler::Base
    def initialize(*args)
      super(*args)
      @klz = Consumers::Attribution
    end
  end
end
