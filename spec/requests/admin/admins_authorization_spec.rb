RSpec.describe 'Admin records authorization' do
  context 'as a manager' do
    let!(:manager) { create(:admin) }

    before { sign_in manager }

    it 'links the header email to the own profile page' do
      get '/admin'

      expect(response.body).to include(%(href="/admin/admins/#{manager.id}">#{manager.email}))
    end

    it 'can view the own profile' do
      get "/admin/admins/#{manager.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(manager.email)
    end

    it 'cannot view another admin' do
      other = create(:admin)

      get "/admin/admins/#{other.id}"

      expect(response).to redirect_to('/admin')
      expect(flash[:error]).to be_present
    end

    it 'cannot list admins' do
      get '/admin/admins'

      expect(response).to redirect_to('/admin')
      expect(flash[:error]).to be_present
    end

    it 'cannot edit the own profile' do
      get "/admin/admins/#{manager.id}/edit"

      expect(response).to redirect_to('/admin')
      expect(flash[:error]).to be_present
    end
  end

  context 'as a super admin' do
    let!(:super_admin) { create(:admin, :super_admin) }

    before { sign_in super_admin }

    it 'can view any admin' do
      other = create(:admin)

      get "/admin/admins/#{other.id}"

      expect(response).to have_http_status(:ok)
    end
  end
end
