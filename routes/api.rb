post '/api/:version/create' do
  if ENV['API_SECRET_KEY']
    pepper = Digest::SHA1.
      hexdigest(request.env["HTTP_X_API_SALT"] + params[:postback] +
                ENV['API_SECRET_KEY']) rescue ""
    halt(404) if params[:pepper] != pepper
  end

  cl = JSON.parse(params[:postback])
  Postback.
    find_or_create_by(:id => cl["id"]).
    update(cl)
  json({ :status => :ok })
end
