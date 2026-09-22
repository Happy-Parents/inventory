RSpec.describe Admin do
  subject(:admin) { build(:admin) }

  it 'has a valid factory' do
    expect(admin).to be_valid
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:password) }
    it { is_expected.to validate_confirmation_of(:password) }
    it { is_expected.to validate_length_of(:password).is_at_least(6).is_at_most(128) }

    context 'with a persisted admin' do
      subject(:admin) { create(:admin) }

      it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    end
  end

  describe 'enums' do
    it do
      is_expected.to define_enum_for(:role)
        .with_values(manager: 'manager', super_admin: 'super admin')
        .backed_by_column_of_type(:string)
    end
  end
end
