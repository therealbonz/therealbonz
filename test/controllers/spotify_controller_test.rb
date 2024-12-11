require "test_helper"

class SpotifyControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get spotify_index_url
    assert_response :success
  end
end
