RSpec.describe Brand do
  subject(:brand) { build(:brand) }

  it 'has a valid factory' do
    expect(brand).to be_valid
  end

  describe 'associations' do
    it { is_expected.to have_many(:products).dependent(:nullify) }
  end

  describe 'validations' do
    subject(:brand) { create(:brand) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end
end
