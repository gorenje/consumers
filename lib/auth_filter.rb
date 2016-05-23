class AuthFilter
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    # server public stuff
    if request.path_info =~ /^\/(js|css|img|images|fonts)/
      return @app.call(env)
    end

    unless request.session[:authenticated]
      unless (['/accessdenied', '/logout','/error','/auth','/auth/google_oauth2','/oauth2callback'].include?(request.path_info) || request.path_info =~ /^\/auth/)
        return [ 307, { 'Location' => '/auth'}, []]
      end
    end

    return @app.call(env)
  end
end
