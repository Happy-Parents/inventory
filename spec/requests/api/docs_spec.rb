RSpec.describe 'API documentation' do
  it 'serves the v1 OpenAPI document' do
    get '/api/v1/openapi.yaml'

    expect(response).to have_http_status(:ok)
    document = YAML.safe_load(response.body)
    expect(document).to include('openapi' => start_with('3.'), 'servers' => [ { 'url' => '/api/v1' } ])
    expect(document['paths'].keys).to include('/session', '/session/refresh', '/me')
  end

  it 'serves Swagger UI at /api/v1/docs' do
    get '/api/v1/docs'
    follow_redirect!

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('swagger-ui', '/api/v1/openapi.yaml')
  end

  it 'answers unknown API paths with 404 rather than another route' do
    get '/api/v1/nope'

    expect(response).to have_http_status(:not_found)
  end
end
