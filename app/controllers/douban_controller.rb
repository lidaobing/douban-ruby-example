require 'douban'

class DoubanController < ApplicationController
  DOUBAN_APIKEY = '0fb6d0a851af01a12f2471f8f50d04e3'
  DOUBAN_SECRET = 'c59e3be2ccdde999'

  def index
    logger.info session.inspect
    unless params[:oauth_token]
      unless session[:access_token]
        # step 1, initial state, store request_token to session
        callback_url = url_for :action => :index
        redirect_url = douban.get_authorize_url(callback_url)
        session[:request_token] = douban.request_token :as_hash
        redirect_to redirect_url
      else
        # step 3, have access_token, now you can use douban API
        douban.access_token = session[:access_token]
        render :text => douban.get_people.inspect
      end
    else
      if session[:request_token]
        # step 2, return from douban, store access_token to session
        douban.request_token = session[:request_token]
        douban.auth
        reset_session
        session[:access_token] = douban.access_token :as_hash
        redirect_to :action => :index
      else
        # error branch, you return from douban, but request_token 
        logger.info "return from oauth but no request_token"
        redirect_to :action => :index
      end
    end
  end

  private
  def douban
    @douban ||= Douban::Authorize.new DOUBAN_APIKEY, DOUBAN_SECRET
  end
end
