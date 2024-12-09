class PinsController < ApplicationController
  # Callbacks to set the pin, authenticate the user, and authorize the user for specific actions
  before_action :set_pin, only: %i[show edit update destroy upvote downvote remove_image]
  before_action :authenticate_user!, except: %i[index show]
  before_action :authorize_user!, only: %i[edit destroy]

  # GET /pins or /pins.json
  # Lists all pins ordered by creation date (most recent first)
  def index
    @pins = Pin.all.order("created_at DESC")
  end

  # GET /pins/:id or /pins/:id.json
  # Displays a specific pin and its details
  def show
  end

  # GET /pins/new
  # Renders the form to create a new pin
  def new
    @pin = current_user.pins.build
  end

  # GET /pins/:id/edit
  # Renders the form to edit an existing pin
  def edit
  end

  # POST /pins or /pins.json
  # Creates a new pin with the provided parameters
  def create
     @pin = current_user.pins.create(pin_params)

    # Ensure at least one image is attached before saving the pin
    if params[:pin][:images].present?
      # Initialize a set to store checksums of already attached images
      existing_checksums = @pin.images.map { |img| img.blob.checksum }

      # Iterate over the uploaded images to check for duplicates based on checksum
      params[:pin][:images].each do |image|
        if image.is_a?(ActionDispatch::Http::UploadedFile)
          image_content = image.read
          checksum = Digest::SHA256.hexdigest(image_content)

          # Attach image if it's not a duplicate
          unless existing_checksums.include?(checksum)
            @pin.images.attach(io: StringIO.new(image_content), filename: image.original_filename, content_type: image.content_type)
            existing_checksums << checksum # Add checksum to existing list to prevent duplicates
          end
        end
      end
    else
      flash.now[:alert] = "Please attach at least one image." # Flash alert if no images were attached
      render :new and return # Render the new pin form again if validation fails
    end

    # Attempt to save the pin and handle the response accordingly
    respond_to do |format|
      if @pin.save
        format.html { redirect_to @pin, notice: "Pin was successfully created." }
        format.json { render :show, status: :created, location: @pin }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @pin.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /pins/:id or /pins/:id.json
  # Updates an existing pin with the provided parameters
  def update
    # Ensure that the current user is the pin's owner before updating
    if @pin.user == current_user && @pin.update(pin_params)
      # Reattach new images if provided, avoiding duplicates
      if params[:pin][:images].present?
        existing_checksums = @pin.images.map { |img| img.blob.checksum }

        params[:pin][:images].each do |image|
          if image.is_a?(ActionDispatch::Http::UploadedFile)
            image_content = image.read
            checksum = Digest::SHA256.hexdigest(image_content)

            # Attach image if it’s not already attached
            unless existing_checksums.include?(checksum)
              @pin.images.attach(io: StringIO.new(image_content), filename: image.original_filename, content_type: image.content_type)
              existing_checksums << checksum
            end
          end
        end
      end

      # Redirect to the updated pin's show page
      redirect_to @pin, notice: "Pin was successfully updated."
    else
      # If the update fails, re-render the edit page with errors
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /pins/:id or /pins/:id.json
  # Destroys the pin and redirects to the pins index page
  def destroy
    if @pin.user == current_user
      @pin.destroy
      redirect_to pins_path, notice: "Pin was successfully destroyed."
    else
      # If the current user is not the owner, deny the destruction
      redirect_to root_path, notice: "Not your pin!" 
    end
  end

  # Upvotes the pin by the current user
  def upvote
    # Ensure that the current user has not already upvoted this pin
    if !@pin.votes_for.exists?(voter: current_user)
      @pin.upvote_by current_user
    else
      flash[:alert] = "You have already upvoted this pin."
    end
    redirect_back(fallback_location: pin_path(@pin)) # Redirect back to the pin's show page
  end

  # Downvotes the pin by the current user
  def downvote
    # Ensure that the current user has not already downvoted this pin
    if !@pin.votes_against.exists?(voter: current_user)
      @pin.downvote_from current_user
    else
      flash[:alert] = "You have already downvoted this pin."
    end
    redirect_back(fallback_location: pin_path(@pin)) # Redirect back to the pin's show page
  end

  # Removes an image from the pin
  def remove_image
    # Find the image to remove by the provided image_id
    image_to_remove = @pin.images.find_by(id: params[:image_id])

    if image_to_remove
      image_to_remove.purge # Purge the image from ActiveStorage
      flash[:notice] = "Image removed successfully."
    else
      flash[:alert] = "Image not found."
    end

    # Redirect back to the edit page after removal
    redirect_to edit_pin_path(@pin)
  end

  private

  # Sets the pin based on the ID provided in the URL parameters
  def set_pin
    @pin = Pin.find(params[:id])
  end

  # Strong parameters for pin creation and updating
  def pin_params
    # Permits the title, description, and images (multiple file uploads) for the pin
    params.require(:pin).permit(:title, :description, images: [])
  end

  # Authorizes the user to ensure they are the owner of the pin
  def authorize_user!
    if @pin.user != current_user
      redirect_to root_path, notice: "Not your pin!" # Deny access if the user is not the pin's owner
    end
  end
end
