# frozen_string_literal: true

require 'test_helper'

class Api::V1::AuthenticationLoginTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = User.find_or_create_by!(email: 'admin_login@example.com') do |user|
      user.password = 'password123'
      user.role = 'admin'
    end
    @regular_user = User.find_or_create_by!(email: 'user_login@example.com') do |user|
      user.password = 'password123'
      user.role = 'user'
    end
  end

  test 'should login admin user with valid credentials' do
    post api_v1_auth_login_url, params: {
      email: 'admin_login@example.com',
      password: 'password123'
    }, as: :json

    assert_response :success
    assert json_response['token'].present?
    assert_equal 'admin_login@example.com', json_response['user']['email']
    assert_equal 'admin', json_response['user']['role']
  end

  test 'should return JWT token on successful login' do
    post api_v1_auth_login_url, params: {
      email: 'admin_login@example.com',
      password: 'password123'
    }, as: :json

    assert_response :success
    token = json_response['token']
    assert_not_nil token
    assert token.start_with?('eyJ')
  end

  test 'should not login with invalid password' do
    post api_v1_auth_login_url, params: {
      email: 'admin_login@example.com',
      password: 'wrongpassword'
    }, as: :json

    assert_response :unauthorized
    assert_equal 'Invalid email or password', json_response['errors'][0]['message']
  end

  test 'should not login with non-existent email' do
    post api_v1_auth_login_url, params: {
      email: 'nonexistent@example.com',
      password: 'password123'
    }, as: :json

    assert_response :unauthorized
    assert_equal 'Invalid email or password', json_response['errors'][0]['message']
  end

  test 'should login regular user with valid credentials' do
    post api_v1_auth_login_url, params: {
      email: 'user_login@example.com',
      password: 'password123'
    }, as: :json

    assert_response :success
    assert json_response['token'].present?
    assert_equal 'user_login@example.com', json_response['user']['email']
    assert_equal 'user', json_response['user']['role']
  end

  test 'should not login with missing email' do
    post api_v1_auth_login_url, params: {
      password: 'password123'
    }, as: :json

    assert_response :unauthorized
    assert_equal 'Invalid email or password', json_response['errors'][0]['message']
  end

  test 'should not login with missing password' do
    post api_v1_auth_login_url, params: {
      email: 'admin_login@example.com'
    }, as: :json

    assert_response :unauthorized
    assert_equal 'Invalid email or password', json_response['errors'][0]['message']
  end

  test 'should login with case-insensitive email' do
    post api_v1_auth_login_url, params: {
      email: 'ADMIN_LOGIN@EXAMPLE.COM',
      password: 'password123'
    }, as: :json

    assert_response :success
    assert json_response['token'].present?
  end
end
