require 'sidekiq/api'
require_relative 'base'

module Scheduler
  class Postbacks < Scheduler::Base
    def initialize(*args)
      super(*args)
      @klz = Consumers::Postbacks
    end
  end
end
