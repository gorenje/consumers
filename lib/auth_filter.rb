class AuthFilter
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    unless request.session[:authenticated] || request.path_info =~ /^\/(auth|pingdom)/
      request.session[:lgkp] = request.path
      return [ 307, { 'Location' => '/auth/google_oauth2'}, []]
    end
    return @app.call(env)
  end
end
