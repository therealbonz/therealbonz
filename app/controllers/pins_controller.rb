class PinsController < ApplicationController
  before_action :set_pin, only: %i[show edit update destroy upvote downvote remove_image]
  before_action :authenticate_user!, except: %i[index show]
  before_action :authorize_user!, only: %i[edit destroy]

  # GET /pins or /pins.json
  def index
    @pins = Pin.all.order(created_at: :desc)
  end

  # GET /pins/:id or /pins/:id.json
  def show; end

  # GET /pins/new
  def new
    @pin = current_user.pins.new
  end

  # GET /pins/:id/edit
  def edit; end

  # POST /pins or /pins.json
  def create
    @pin = current_user.pins.new(pin_params)

    if validate_and_attach_images(@pin, params[:pin][:images])
      if @pin.save
        redirect_to @pin, notice: "Pin was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    else
      flash.now[:alert] = "Please attach at least one valid image."
      render :new
    end
  end

  # PATCH/PUT /pins/:id or /pins/:id.json
  def update
    if @pin.update(pin_params)
      validate_and_attach_images(@pin, params[:pin][:images])
      redirect_to @pin, notice: "Pin was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /pins/:id or /pins/:id.json
  def destroy
    @pin.destroy
    redirect_to pins_path, notice: "Pin was successfully destroyed."
  end

  # Upvotes the pin
  def upvote
    if @pin.votes_for.exists?(voter: current_user)
      flash[:alert] = "You have already upvoted this pin."
    else
      @pin.upvote_by(current_user)
    end
    redirect_back(fallback_location: pin_path(@pin))
  end

  # Downvotes the pin
  def downvote
    if @pin.votes_against.exists?(voter: current_user)
      flash[:alert] = "You have already downvoted this pin."
    else
      @pin.downvote_from(current_user)
    end
    redirect_back(fallback_location: pin_path(@pin))
  end

  # Removes an image from the pin
  def remove_image
    image_to_remove = @pin.images.find_by(id: params[:image_id])
    if image_to_remove
      image_to_remove.purge
      flash[:notice] = "Image removed successfully."
    else
      flash[:alert] = "Image not found."
    end
    redirect_to edit_pin_path(@pin)
  end

  private

  def set_pin
    @pin = Pin.find(params[:id])
  end

  def pin_params
    params.require(:pin).permit(:title, :description, images: [])
  end

  def authorize_user!
    redirect_to root_path, notice: "Not your pin!" unless @pin.user == current_user
  end

  # Validates and attaches images while avoiding duplicates
  def validate_and_attach_images(pin, images)
    return false unless images.present?

    existing_checksums = pin.images.map { |img| img.blob.checksum }
    images.each do |image|
      next unless image.is_a?(ActionDispatch::Http::UploadedFile)

      checksum = Digest::SHA256.hexdigest(image.read)
      unless existing_checksums.include?(checksum)
        pin.images.attach(
          io: StringIO.new(image.read),
          filename: image.original_filename,
          content_type: image.content_type
        )
        existing_checksums << checksum
      end
    end
    true
  end
end