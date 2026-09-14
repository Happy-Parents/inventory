RSpec.describe AdminPolicy do
  subject(:policy) { described_class.new(admin, record) }

  let(:record) { build(:admin) }

  context 'with a super admin' do
    let(:admin) { build(:admin, :super_admin) }

    it { is_expected.to permit_actions(:index, :show, :destroy) }
    it { is_expected.to permit_new_and_create_actions }
    it { is_expected.to permit_edit_and_update_actions }
    it { is_expected.to permit_all_actions }
  end

  context 'with a manager' do
    let(:admin) { build(:admin) }

    it { is_expected.to forbid_actions(:index, :show, :destroy) }
    it { is_expected.to forbid_new_and_create_actions }
    it { is_expected.to forbid_edit_and_update_actions }
    it { is_expected.to forbid_all_actions }
  end
end
