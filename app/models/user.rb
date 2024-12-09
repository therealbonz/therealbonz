class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable, and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  has_many :pins, dependent: :destroy
  has_many :videos, dependent: :destroy

  # ActiveStorage attachment
  has_one_attached :avatar

  # Validations
  validate :acceptable_avatar

  private

  def acceptable_avatar
    return unless avatar.attached?

    unless avatar.content_type.in?(%w[image/jpeg image/png image/gif])
      errors.add(:avatar, "must be a JPEG, PNG, or GIF file.")
    end

    if avatar.byte_size > 5.megabytes
      errors.add(:avatar, "must be less than 5MB.")
    end
  end
end