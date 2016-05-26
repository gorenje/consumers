require 'sidekiq/api'
require_relative 'base'

module Scheduler
  class Clickstore < Scheduler::Base
    def initialize(*args)
      super(*args)
      @klz = Consumers::Clickstore
    end
  end
end
