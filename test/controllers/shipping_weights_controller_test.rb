require 'test_helper'

class ShippingWeightsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @shipping_weight = shipping_weights(:one)
  end

  test "should get index" do
    get shipping_weights_url
    assert_response :success
  end

  test "should get new" do
    get new_shipping_weight_url
    assert_response :success
  end

  test "should create shipping_weight" do
    assert_difference('ShippingWeight.count') do
      post shipping_weights_url, params: { shipping_weight: {  } }
    end

    assert_redirected_to shipping_weight_url(ShippingWeight.last)
  end

  test "should show shipping_weight" do
    get shipping_weight_url(@shipping_weight)
    assert_response :success
  end

  test "should get edit" do
    get edit_shipping_weight_url(@shipping_weight)
    assert_response :success
  end

  test "should update shipping_weight" do
    patch shipping_weight_url(@shipping_weight), params: { shipping_weight: {  } }
    assert_redirected_to shipping_weight_url(@shipping_weight)
  end

  test "should destroy shipping_weight" do
    assert_difference('ShippingWeight.count', -1) do
      delete shipping_weight_url(@shipping_weight)
    end

    assert_redirected_to shipping_weights_url
  end
end
