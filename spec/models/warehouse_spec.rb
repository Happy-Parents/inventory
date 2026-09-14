RSpec.describe Warehouse do
  subject(:warehouse) { build(:warehouse) }

  it 'has a valid factory' do
    expect(warehouse).to be_valid
  end

  describe 'associations' do
    it { is_expected.to have_many(:stock_items).dependent(:destroy) }
    it { is_expected.to have_many(:products).through(:stock_items) }
  end

  describe 'validations' do
    subject(:warehouse) { create(:warehouse) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end
end
