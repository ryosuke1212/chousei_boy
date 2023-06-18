class ApplicationController < ActionController::Base
  def after_sign_in_path_for(resource)
    # ログイン後にリダイレクトする先のパスを指定します
    root_path
  end
end
