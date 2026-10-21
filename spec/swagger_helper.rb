RSpec.configure do |config|
  config.openapi_root = Rails.root.join('swagger').to_s

  config.openapi_specs = {
    'v1/openapi.yaml' => {
      openapi: '3.0.3',
      info: {
        title: 'Inventory API',
        version: 'v1',
        description: <<~TEXT
          JSON API for the inventory mobile app.

          Sign in with `POST /session` and send the returned `access_token` as
          `Authorization: Bearer <access_token>` on every other request.

          Access tokens are JWTs valid for 15 minutes. When one expires (401),
          exchange the `refresh_token` at `POST /session/refresh` for a new pair.
          Refresh tokens are single-use: always store the newest one. Presenting
          an already used refresh token revokes the whole session.
        TEXT
      },
      servers: [ { url: '/api/v1' } ],
      security: [ { bearer: [] } ],
      paths: {},
      components: {
        securitySchemes: {
          bearer: { type: :http, scheme: :bearer, bearerFormat: 'JWT',
                    description: 'Access token issued by POST /session or POST /session/refresh' }
        },
        schemas: {
          error: {
            type: :object,
            required: %w[error],
            properties: {
              error: {
                type: :object,
                required: %w[code message],
                properties: {
                  code: { type: :string, example: 'unauthorized' },
                  message: { type: :string }
                }
              }
            }
          },
          token_pair: {
            type: :object,
            required: %w[token_type access_token expires_in refresh_token refresh_token_expires_at],
            properties: {
              token_type: { type: :string, enum: %w[Bearer] },
              access_token: { type: :string, description: 'JWT' },
              expires_in: { type: :integer, description: 'Access token lifetime in seconds', example: 900 },
              refresh_token: { type: :string, description: 'Single-use; replaced on every refresh' },
              refresh_token_expires_at: { type: :string, format: 'date-time' }
            }
          },
          admin: {
            type: :object,
            required: %w[id email role],
            properties: {
              id: { type: :string, format: :uuid },
              email: { type: :string, format: :email },
              role: { type: :string, enum: Admin.roles.keys }
            }
          }
        }
      }
    }
  }

  config.openapi_format = :yaml
  config.openapi_no_additional_properties = true
end
