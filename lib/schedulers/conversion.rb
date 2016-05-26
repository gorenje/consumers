require 'sidekiq/api'
require_relative 'base'

module Scheduler
  class Conversion < Scheduler::Base
    def initialize(*args)
      super(*args)
      @klz = Consumers::Conversion
    end
  end
end
