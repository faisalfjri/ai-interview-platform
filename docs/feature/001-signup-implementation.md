# Signup Feature Implementation

## Overview

Implemented the backend signup endpoint to support the existing `SignupPage.tsx` frontend. The web frontend already had a fully functional signup form calling `POST /api/v1/signup`, but the API had no corresponding route or controller action.

## Changes Made

### 1. Route (`config/routes.rb`)

Added signup route alongside the existing login route:

```ruby
# Auth
post 'auth/login', to: 'authentication#authenticate'
post 'signup',     to: 'authentication#signup'
```

### 2. Controller (`app/controllers/api/v1/authentication_controller.rb`)

Added `signup` action to `AuthenticationController`:

```ruby
# POST /api/v1/signup
def signup
  user = User.new(signup_params)

  if user.save
    scheme = resolve_scheme
    token  = JsonWebToken.encode({ user_id: user.id, role: user.role, scheme: })

    json_response({ token:, user: { id: user.id, email: user.email, role: user.role } }, :created)
  else
    json_error(user.errors.full_messages.first, :unprocessable_entity)
  end
end

private

def signup_params
  params.permit(:email, :password, :role)
end
```

## API Contract

### Request

```
POST /api/v1/signup
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "role": "user"
}
```

### Parameters

| Field      | Type     | Required | Validation                                      |
|------------|----------|----------|------------------------------------------------|
| `email`    | string   | yes      | Valid email format, unique (case-insensitive)   |
| `password` | string   | yes      | Minimum 6 characters                            |
| `role`     | string   | yes      | Must be `"admin"`, `"assessor"`, or `"user"`    |

### Success Response (201 Created)

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "role": "user"
  }
}
```

### Error Responses (422 Unprocessable Entity)

All validation errors return the same envelope structure. The `message` field contains the first validation error from `User` model.

#### Missing email

```json
{
  "errors": [
    {
      "status": 422,
      "message": "Email can't be blank"
    }
  ]
}
```

#### Duplicate email (case-insensitive)

```json
{
  "errors": [
    {
      "status": 422,
      "message": "Email has already been taken"
    }
  ]
}
```

#### Invalid email format

```json
{
  "errors": [
    {
      "status": 422,
      "message": "Email is invalid"
    }
  ]
}
```

#### Invalid role (not "admin", "assessor", or "user")

```json
{
  "errors": [
    {
      "status": 422,
      "message": "Role is not included in the list"
    }
  ]
}
```

#### Missing password

```json
{
  "errors": [
    {
      "status": 422,
      "message": "Password can't be blank"
    }
  ]
}
```

#### Password too short (< 6 characters)

```json
{
  "errors": [
    {
      "status": 422,
      "message": "Password is too short (minimum is 6 characters)"
    }
  ]
}
```

> **Note:** Only the first validation error is returned. If multiple fields fail validation, subsequent errors are suppressed. The frontend (`SignupPage.tsx`) displays a generic `"Signup failed. Please try again."` message for all error responses.

## Architecture Notes

- **No tenant requirement**: The `signup` action inherits `skip_before_action :require_tenant!` from the controller, so no `X-Tenant-Scheme` header is needed for registration.
- **Scheme resolution**: Uses the same `resolve_scheme` method as login — reads from `X-Tenant-Scheme` header or falls back to the first organization's scheme.
- **JWT encoding**: Uses the same `JsonWebToken.encode` as login, with claims `{ user_id, role, scheme }` and 3-day expiration.
- **Password hashing**: Relies on `has_secure_password` (bcrypt) in the `User` model — no plain-text storage.
- **Email normalization**: The `User` model has a `before_save :downcase_email` callback.

## Unit Tests

### Test Infrastructure

Created the following test infrastructure following [Rails Testing Guide](https://guides.rubyonrails.org/testing.html):

- `test/test_helper.rb` — Base test configuration
- `test/controllers/api/v1/authentication_signup_test.rb` — Signup endpoint integration tests
- `test/controllers/api/v1/authentication_login_test.rb` — Login endpoint integration tests

### Signup Test Coverage

**11 test cases** covering all signup scenarios:

| Scenario | Test Case | Status |
|----------|-----------|--------|
| Valid params | Creates user with 201 Created | ✅ |
| Valid params | Returns JWT token | ✅ |
| Valid params | Returns user data | ✅ |
| Valid params | Creates new user | ✅ |
| Valid params | Downcases email | ✅ |
| Admin role | Creates admin user | ✅ |
| Missing email | Returns 422 | ✅ |
| Missing email | Returns error message | ✅ |
| Duplicate email | Returns 422 | ✅ |
| Duplicate email | Returns error message | ✅ |
| Duplicate email (case-insensitive) | Returns 422 | ✅ |
| Duplicate email (case-insensitive) | Returns error message | ✅ |
| Invalid email format | Returns 422 | ✅ |
| Invalid email format | Returns error message | ✅ |
| Invalid role | Returns 422 | ✅ |
| Invalid role | Returns error message | ✅ |
| Missing password | Returns 422 | ✅ |
| Missing password | Returns error message | ✅ |
| Short password | Returns 422 | ✅ |
| Short password | Returns error message | ✅ |
| Missing role | Uses default "user" | ✅ |

### Login Test Coverage

**8 test cases** covering all login scenarios:

| Scenario | Test Case | Status |
|----------|-----------|--------|
| Valid admin credentials | Returns 200 OK | ✅ |
| Valid admin credentials | Returns JWT token | ✅ |
| Invalid password | Returns 401 | ✅ |
| Non-existent email | Returns 401 | ✅ |
| Valid user credentials | Returns 200 OK | ✅ |
| Missing email | Returns 401 | ✅ |
| Missing password | Returns 401 | ✅ |
| Case-insensitive email | Returns 200 OK | ✅ |

### Running Tests

```bash
cd api
RAILS_ENV=test bundle exec rails test test/controllers/api/v1/authentication_signup_test.rb
RAILS_ENV=test bundle exec rails test test/controllers/api/v1/authentication_login_test.rb
```

## Assumptions & Trade-offs

1. **Role restriction**: Both signup and login endpoints allow `"admin"`, `"assessor"`, and `"user"` roles. Users can register and log in with any of these roles.

2. **No email verification**: Signup immediately creates the account and returns a JWT. A production system would typically require email verification before granting access.

3. **No rate limiting on signup**: The existing `rack-attack` gem is configured but signup is not explicitly rate-limited beyond any global rules. Consider adding rate limiting for production.

4. **No organization assignment**: New users are not automatically assigned to an organization. The `scheme` in the JWT is resolved from the request header or default organization, but the user record itself has no `organization_id` foreign key.
