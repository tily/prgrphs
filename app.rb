Bundler.require
require 'open-uri'
require './models/user.rb'
require './models/paragraph.rb'
require './jobs/capture.rb'

Resque.redis = Redis.new(url: ENV['REDISTOGO_URL'] || 'redis://redis:6379')

configure do
  UUID_REGEXP = "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"
  enable :sessions
  set :session_secret, ENV['SESSION_SECRET']
  set :haml, ugly: true, escape_html: true
  set :protection, :except => :path_traversal
  use OmniAuth::Builder do
          provider :twitter, ENV['CONSUMER_KEY'], ENV['CONSUMER_SECRET']
  end
  Mongoid.load!("./mongoid.yml")
end

helpers do
  def current_user
    @current_user ||= User.where(uid: session[:uid]).first
  end

  def markdown2html(markdown)
    renderer = Redcarpet::Render::HTML.new(filter_html:true)
    Redcarpet::Markdown.new(renderer, autolink: true).render(markdown)
  end

  def current_page
    params[:page] || 1
  end
end

get '/' do
  haml :top
end

post '/:user' do
  @paragraph = current_user.paragraphs.new
  @paragraph.body = params[:body]
  @paragraph.published = params[:published] == 'on'
  if @paragraph.save
    share_on_twitter = params[:share_on_twitter] == 'on'
    Resque.enqueue(Capture, current_user.screen_name, @paragraph.id, share_on_twitter) if @paragraph.published
    redirect "/#{current_user.screen_name}/#{@paragraph.id}"
  else
    haml :edit
  end
end

get '/logout' do
  session[:uid] = nil
  redirect '/'
end

get '/:user/new' do
  haml :edit
end

get '/admin' do
  session[:admin] = !session[:admin]
  redirect params[:redirect_to] || '/'
end

get %r|^/(.+)/(#{UUID_REGEXP})/prepend| do
  @paragraph = Paragraph.find(params[:captures][1])
  halt 403 unless @paragraph.user == current_user || @paragraph.published
  haml :prepend
end

put %r|^/(.+)/(#{UUID_REGEXP})/head| do
  @paragraph = Paragraph.find(params[:captures][1])
  halt 403 unless @paragraph.user == current_user || @paragraph.published
  @paragraph.body = ["* #{params[:line]}", @paragraph.body].join("\n")
  if @paragraph.save
    Resque.enqueue(Capture, current_user.screen_name, @paragraph.id) if @paragraph.published
    redirect params[:redirect_to] || "/#{current_user.screen_name}/#{@paragraph.id}/prepend"
  else
    haml :prepend
  end
end

get %r|^/(.+)/(#{UUID_REGEXP})/edit| do
  @paragraph = current_user.paragraphs.find(params[:captures][1])
  haml :edit
end

get %r|^/(.+)/(#{UUID_REGEXP})\.png| do
  @paragraph = Paragraph.find(params[:captures][1])
  halt 403 unless @paragraph.user == current_user || @paragraph.published
  content_type 'image/png'
  open("https://s3-ap-northeast-1.amazonaws.com/prgrphs-images#{request.path}").read
end

get %r|^/(.+)/(#{UUID_REGEXP})| do
  @paragraph = Paragraph.find(params[:captures][1])
  @user = @paragraph.user
  halt 403 unless @paragraph.user == current_user || @paragraph.published
  haml :show
end

put %r|^/(.+)/(#{UUID_REGEXP})| do
  @paragraph = current_user.paragraphs.find(params[:captures][1])
  @paragraph.body = params[:body]
  @paragraph.published = params[:published] == 'on'
  if @paragraph.save
    share_on_twitter = params[:share_on_twitter] == 'on'
    Resque.enqueue(Capture, current_user.screen_name, @paragraph.id, share_on_twitter) if @paragraph.published
    redirect params[:redirect_to] || "/#{current_user.screen_name}/#{@paragraph.id}"
  else
    haml :edit
  end
end

delete %r|^/(.+)/(#{UUID_REGEXP})| do
  @paragraph = current_user.paragraphs.find(params[:captures][1])
  @paragraph.destroy
  redirect "/#{current_user.screen_name}"
end

get '/:user/feed' do
  @user = User.where(screen_name: params[:user]).first
  @paragraphs = @user.paragraphs.desc(:updated_at).limit(params[:count] || 1)
  @paragraphs = @paragraphs.where(published: true) if @user != current_user
  builder :feed, layout: false
end

get '/:user.xlsx' do
  content_type 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  @user = User.where(screen_name: params[:user]).first
  @paragraphs = @user.paragraphs.desc(:updated_at)
  @paragraphs = @paragraphs.where(published: true) if @user != current_user
  stream = nil
  Axlsx::Package.new do |p|
    p.workbook.add_worksheet(:name => "paragraphs") do |sheet|
      sheet.add_row ["created_at", "updated_at", "published", "body"], :style => Axlsx::STYLE_THIN_BORDER
      @paragraphs.each do |paragraph|
        sheet.add_row [
          (@user == current_user ? paragraph.created_at.to_s : nil),
          paragraph.updated_at.to_s,
          paragraph.published,
          paragraph.body
        ], :style => Axlsx::STYLE_THIN_BORDER
      end
      end
    stream = p.to_stream
  end
  stream.read
end

get '/:user' do
  @user = User.where(screen_name: params[:user]).first
  @paragraphs = @user.paragraphs.desc(:updated_at).page(current_page)
  @paragraphs = @paragraphs.where(published: true) if @user != current_user
  haml :list
end

get '/auth/twitter/callback' do
  auth = request.env["omniauth.auth"]
  user = User.where(:provider => auth["provider"], :uid => auth["uid"]).first || User.create_with_omniauth(auth)
  if auth["provider"] == "twitter"
    user.update!(twitter_token: auth["credentials"]["token"], twitter_secret: auth["credentials"]["secret"])
  end
  session[:uid] = auth["uid"]
  redirect '/'
end

error 403 do
  '403 Forbidden'
end
