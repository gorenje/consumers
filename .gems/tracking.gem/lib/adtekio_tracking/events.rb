module AdtekioTracking
  class Events
    include AdtekioTracking::Http

    def initialize
    end

    def payment(params = {})
      send_request('/t/pay', params)
    end

    def install(params = {})
      send_request('/t/ist', params)
    end

    def tutorial_step(params = {})
      send_request('/t/tut', params)
    end

    def funnel_step(params = {})
      send_request('/t/fun', params)
    end

    def application_open(params = {})
      send_request('/t/apo', params)
    end

    def end_of_round(params = {})
      send_request('/t/eor', params)
    end

    def level_complete(params = {})
      send_request('/t/lvc', params)
    end

    def scene_start(params = {})
      send_request('/t/scs', params)
    end

    def scene_complete(params = {})
      send_request('/t/scc', params)
    end

    def postback(params = {})
      send_request('/t/pob', params)
    end
  end
end
