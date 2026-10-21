# Exercises the authorization plumbing every API endpoint inherits.
RSpec.describe Api::V1::BaseController do
  controller(described_class) do
    def index
      authorize Admin.find(params[:admin_id]), :show?
      head :no_content
    end

    def show = head(:no_content) # forgets to authorize
  end

  let(:manager) { create(:admin) }

  before { request.headers['Authorization'] = bearer(start_api_session(manager)) }

  it 'allows what the Pundit policy allows' do
    get :index, params: { admin_id: manager.id }

    expect(response).to have_http_status(:no_content)
  end

  it 'answers 403 with the JSON error shape when the policy denies' do
    get :index, params: { admin_id: create(:admin).id }

    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body.dig('error', 'code')).to eq('forbidden')
  end

  it 'answers 404 for missing records' do
    get :index, params: { admin_id: SecureRandom.uuid }

    expect(response).to have_http_status(:not_found)
  end

  it 'fails loudly when an action skips authorization' do
    expect { get :show, params: { id: 1 } }.to raise_error(Pundit::AuthorizationNotPerformedError)
  end
end
