require 'test_helper'

module Kaui
  class AdminTenantsControllerTest < ActionController::TestCase
    test "should get index" do
      get :index
      assert_response :success
    end
  
  end
end
