class Pin < ApplicationRecord
  # Associations
  has_many_attached :images
  belongs_to :user

  # Validations
  validates :images, presence: { message: "must have at least one image" }
  validates :title, presence: true
  validates :description, presence: true

  # Method to retrieve image URLs or attach a default image
  def image_urls
    if images.attached?
      images.map do |image|
        Rails.application.routes.url_helpers.rails_blob_path(image, only_path: true)
      end
    else
      # Attach a default 'no_photo.jpeg' image if no images are attached
      images.attach(io: File.open(Rails.root.join('client', 'src', 'images', 'no_photo.jpeg')), 
                    filename: 'no_photo.jpeg', 
                    content_type: 'image/jpeg')
      [Rails.application.routes.url_helpers.rails_blob_path(images.last, only_path: true)]
    end
  end
end