require "test_helper"

class AdminControllerTest < ActionDispatch::IntegrationTest
  test "should get admin_page" do
    get admin_admin_page_url
    assert_response :success
  end
end
