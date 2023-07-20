class User < ApplicationRecord
  has_and_belongs_to_many :line_groups

  def values(omniauth)
    return if provider.to_s != omniauth['provider'].to_s || uid != omniauth['uid']
  end

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[line]
end
