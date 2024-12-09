class Pin < ApplicationRecord
has_many_attached :images

def image_urls
  if images.attached?
    images.map do |image|
      Rails.application.routes.url_helpers.rails_blob_path(image, only_path: true)
    end
  else
    self.images.attach(io: File.open(Rails.root.join(‘client’, ‘src’, ‘images’, ‘no_photo.jpeg’)), filename: ‘no_photo.jpeg’, content_type: “application/jpeg”)
  end
end

end
