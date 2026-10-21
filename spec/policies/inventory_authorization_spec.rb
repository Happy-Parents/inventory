RSpec.describe InventoryAuthorization do
  subject(:adapter) { described_class.new(nil, user) }

  let(:other_admin) { build_stubbed(:admin) }

  let(:actions) { [ ActiveAdmin::Auth::READ,
                   ActiveAdmin::Auth::CREATE,
                   ActiveAdmin::Auth::UPDATE,
                   ActiveAdmin::Auth::DESTROY
                   ]}

  context 'with a super admin' do
    let(:user) { build_stubbed(:admin, :super_admin) }

    it 'may do anything with Admin records' do
      actions.each do |action|
        expect(adapter.authorized?(action, Admin)).to be(true)
        expect(adapter.authorized?(action, other_admin)).to be(true)
      end
    end
  end

  context 'with a manager' do
    let(:user) { build_stubbed(:admin) }

    it 'may read the own profile only' do
      expect(adapter.authorized?(ActiveAdmin::Auth::READ, user)).to be(true)
      expect(adapter.authorized?(ActiveAdmin::Auth::READ, other_admin)).to be(false)
      expect(adapter.authorized?(ActiveAdmin::Auth::READ, Admin)).to be(false)
    end

    it 'may not change Admin records, including the own one' do
      (actions - [ ActiveAdmin::Auth::READ ]).each do |action|
        expect(adapter.authorized?(action, user)).to be(false)
        expect(adapter.authorized?(action, Admin)).to be(false)
      end
    end

    it 'may do anything with other resources' do
      actions.each do |action|
        expect(adapter.authorized?(action, Product)).to be(true)
        expect(adapter.authorized?(action, build_stubbed(:product))).to be(true)
      end
      expect(adapter.authorized?(ActiveAdmin::Auth::READ)).to be(true)
    end
  end

  describe 'API sessions' do
    let(:api_session) { build_stubbed(:admin).then { ApiSession.new(admin: it) } }

    context 'with a super admin' do
      let(:user) { build_stubbed(:admin, :super_admin) }

      it 'may list and delete them' do
        expect(adapter.authorized?(ActiveAdmin::Auth::READ, ApiSession)).to be(true)
        expect(adapter.authorized?(ActiveAdmin::Auth::DESTROY, api_session)).to be(true)
      end
    end

    context 'with a manager' do
      let(:user) { build_stubbed(:admin) }

      it 'may neither list nor delete them, including the own ones' do
        expect(adapter.authorized?(ActiveAdmin::Auth::READ, ApiSession)).to be(false)
        expect(adapter.authorized?(ActiveAdmin::Auth::DESTROY, api_session)).to be(false)
        expect(adapter.authorized?(ActiveAdmin::Auth::DESTROY, ApiSession.new(admin: user))).to be(false)
      end
    end
  end

  context 'without a user' do
    let(:user) { nil }

    it 'denies Admin records' do
      expect(adapter.authorized?(ActiveAdmin::Auth::READ, Admin)).to be(false)
    end
  end
end
