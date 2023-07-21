class ApplicationController < ActionController::Base
  protect_from_forgery except: [:callback]
  def after_sign_in_path_for(_resource)
    # ログイン後にリダイレクトする先のパスを指定します
    root_path
  end
end
