require 'erubis'
require 'uuidtools'
require 'digest/md5'

class UrlConfigParser

  class MD5 < Digest::MD5
    class << self
      alias orig_new new
      def new(str = nil)
        if str
          orig_new.update(str)
        else
          orig_new
        end
      end

      def md5(*args)
        new(*args)
      end
    end
  end

  class CGIEruby < Erubis::PI::Eruby
    REGEXP = Regexp.new("[^#{URI::PATTERN::UNRESERVED}]").freeze

    def escaped_expr(code)
      return "URI.encode((#{code.strip}).to_s, CGIEruby::REGEXP)"
    end
  end

  attr_reader :event, :params, :user, :netcfg

  def initialize(event, postback)
    @event  = event
    @params = NetworkUser::WrapClickData.new(event.params)
    @url    = postback.url_template
    @body   = postback.env["body"]
    @header = postback.env["header"]
    @check  = postback.env["check"]
    @user   = postback.user_required? ? event.network_user(postback) : nil
    @netcfg = postback.netcfg
  end

  def valid_check?
    @check.nil? || eval(@check)
  end

  def generate
    return nil unless valid_check?

    #Because we have ruby code injections that are multilined
    parsed_url = if @url =~ /@{.*}@/ || @url =~ /<%.*%>/m
                   CGIEruby.new(@url).result(binding)
                 else
                   @url
                 end
    parsed_body = if @body && (@body =~ /@{.*}@/ || @body =~ /<%.*%>/m)
                    CGIEruby.new(@body).result(binding)
                  else
                    @body
                  end

    parsed_header = if @header && (@header =~ /@{.*}@/ || @header =~ /<%.*%>/m)
                      CGI::parse(CGIEruby.new(@header).result(binding))
                    else
                      CGI::parse(@header || "")
                    end
    parsed_header.each {|key, value| parsed_header[key] = value.first }

    { :url => parsed_url, :body => parsed_body, :header => parsed_header }
  end

  def sha1(value)
    Digest::SHA1.hexdigest(value)
  end

  def muidify(val)
    Base64.encode64(MD5.md5(val).digest).tr("+/=", "-_\n").strip
  end
end
