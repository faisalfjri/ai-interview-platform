# frozen_string_literal: true

require 'test_helper'

class Api::V1::AuthenticationSignupTest < ActionDispatch::IntegrationTest
  setup do
    @existing_user = User.find_or_create_by!(email: 'existing_signup@example.com') do |user|
      user.password = 'password123'
      user.role = 'user'
    end
  end

  test 'should create user with valid params' do
    assert_difference('User.count', 1) do
      post api_v1_signup_url, params: {
        email: 'newuser_signup@example.com',
        password: 'password123',
        role: 'user'
      }, as: :json
    end

    assert_response :created
    assert json_response['token'].present?
    assert_equal 'newuser_signup@example.com', json_response['user']['email']
    assert_equal 'user', json_response['user']['role']
  end

  test 'should create admin user' do
    assert_difference('User.count', 1) do
      post api_v1_signup_url, params: {
        email: 'newadmin_signup@example.com',
        password: 'password123',
        role: 'admin'
      }, as: :json
    end

    assert_response :created
    assert_equal 'admin', json_response['user']['role']
  end

  test 'should downcase email before saving' do
    post api_v1_signup_url, params: {
      email: 'UPPERCASE_SIGNUP_TEST@example.com',
      password: 'password123',
      role: 'user'
    }, as: :json

    assert_response :created
    user = User.find_by(email: 'uppercase_signup_test@example.com')
    assert_not_nil user
    assert_equal 'uppercase_signup_test@example.com', user.email
  end

  test 'should not create user without email' do
    assert_no_difference('User.count') do
      post api_v1_signup_url, params: {
        password: 'password123',
        role: 'user'
      }, as: :json
    end

    assert_response :unprocessable_entity
    assert json_response['errors'][0]['message'].include?("Email can't be blank")
  end

  test 'should not create user with duplicate email' do
    assert_no_difference('User.count') do
      post api_v1_signup_url, params: {
        email: 'existing_signup@example.com',
        password: 'password123',
        role: 'user'
      }, as: :json
    end

    assert_response :unprocessable_entity
    assert_equal 'Email has already been taken', json_response['errors'][0]['message']
  end

  test 'should not create user with duplicate email case insensitive' do
    assert_no_difference('User.count') do
      post api_v1_signup_url, params: {
        email: 'EXISTING_SIGNUP@EXAMPLE.COM',
        password: 'password123',
        role: 'user'
      }, as: :json
    end

    assert_response :unprocessable_entity
    assert_equal 'Email has already been taken', json_response['errors'][0]['message']
  end

  test 'should not create user with invalid email' do
    assert_no_difference('User.count') do
      post api_v1_signup_url, params: {
        email: 'not_an_email',
        password: 'password123',
        role: 'user'
      }, as: :json
    end

    assert_response :unprocessable_entity
    assert_equal 'Email is invalid', json_response['errors'][0]['message']
  end

  test 'should not create user with invalid role' do
    assert_no_difference('User.count') do
      post api_v1_signup_url, params: {
        email: 'valid_signup@example.com',
        password: 'password123',
        role: 'superadmin'
      }, as: :json
    end

    assert_response :unprocessable_entity
    assert_equal 'Role is not included in the list', json_response['errors'][0]['message']
  end

  test 'should not create user without password' do
    assert_no_difference('User.count') do
      post api_v1_signup_url, params: {
        email: 'valid_signup@example.com',
        role: 'user'
      }, as: :json
    end

    assert_response :unprocessable_entity
    assert json_response['errors'][0]['message'].include?("Password can't be blank")
  end

  test 'should not create user with short password' do
    assert_no_difference('User.count') do
      post api_v1_signup_url, params: {
        email: 'valid_signup@example.com',
        password: '12345',
        role: 'user'
      }, as: :json
    end

    assert_response :unprocessable_entity
    assert_equal 'Password is too short (minimum is 6 characters)', json_response['errors'][0]['message']
  end

  test 'should use default role when role not provided' do
    assert_difference('User.count', 1) do
      post api_v1_signup_url, params: {
        email: 'norole_signup@example.com',
        password: 'password123'
      }, as: :json
    end

    assert_response :created
    assert_equal 'user', json_response['user']['role']
  end
end
