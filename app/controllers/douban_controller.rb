require 'douban'

class DoubanController < ApplicationController
  DOUBAN_APIKEY = '0fb6d0a851af01a12f2471f8f50d04e3'
  DOUBAN_SECRET = 'c59e3be2ccdde999'

  def index
    reset_session
    @douban_apikey = DOUBAN_APIKEY
    @douban_secret = DOUBAN_SECRET
  end

  def authorize
    logger.info session.inspect
    unless params[:oauth_token]
      unless session[:access_token]
        session[:douban_apikey] = params[:apikey] || DOUBAN_APIKEY
        session[:douban_secret] = params[:secret] || DOUBAN_SECRET
        # step 1, initial state, store request_token to session
        callback_url = url_for :action => :authorize
        redirect_url = douban.get_authorize_url(callback_url)
        session[:request_token] = douban.request_token :as_hash
        redirect_to redirect_url
      else
        # step 3, have access_token, now you can use douban API
        douban.access_token = session[:access_token]
        @access_token = douban.access_token
        @people = douban.get_people
        render :authorize, :content_type => Mime::TEXT, :layout => false
        #render :text => douban.get_people.inspect, :content_type => Mime::TEXT
      end
    else
      if session[:request_token]
        # step 2, return from douban, store access_token to session
        douban.request_token = session[:request_token]
        douban.auth
        douban_apikey = session[:douban_apikey]
        douban_secret = session[:douban_secret]
        reset_session
        session[:access_token] = douban.access_token :as_hash
        session[:douban_apikey] = douban_apikey
        session[:douban_secret] = douban_secret
        redirect_to :action => :authorize
      else
        # error branch, you return from douban, but request_token
        logger.info "return from oauth but no request_token"
        redirect_to :action => :authorize
      end
    end
  end

  private
  def douban
    @douban ||= Douban::Authorize.new session[:douban_apikey], session[:douban_secret]
  end
end
