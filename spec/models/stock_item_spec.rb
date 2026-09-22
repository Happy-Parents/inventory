RSpec.describe StockItem do
  subject(:stock_item) { build(:stock_item) }

  it 'has a valid factory' do
    expect(stock_item).to be_valid
  end

  describe 'associations' do
    it { is_expected.to belong_to(:product) }
    it { is_expected.to belong_to(:warehouse) }
  end

  describe 'validations' do
    subject(:stock_item) { create(:stock_item) }

    it { is_expected.to validate_numericality_of(:quantity).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:damaged_quantity).is_greater_than_or_equal_to(0) }
    it do
      is_expected.to validate_uniqueness_of(:product_id)
        .scoped_to(:warehouse_id)
        .ignoring_case_sensitivity
    end
  end
end
