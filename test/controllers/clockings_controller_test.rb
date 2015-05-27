require 'test_helper'

class ClockingsControllerTest < ActionController::TestCase
  setup do
    @clocking = clockings(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:clockings)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create clocking" do
    assert_difference('Clocking.count') do
      post :create, clocking: { clocking: @clocking.clocking, direction: @clocking.direction, finger: @clocking.finger, workday: @clocking.workday }
    end

    assert_redirected_to clocking_path(assigns(:clocking))
  end

  test "should show clocking" do
    get :show, id: @clocking
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @clocking
    assert_response :success
  end

  test "should update clocking" do
    patch :update, id: @clocking, clocking: { clocking: @clocking.clocking, direction: @clocking.direction, finger: @clocking.finger, workday: @clocking.workday }
    assert_redirected_to clocking_path(assigns(:clocking))
  end

  test "should destroy clocking" do
    assert_difference('Clocking.count', -1) do
      delete :destroy, id: @clocking
    end

    assert_redirected_to clockings_path
  end
end
