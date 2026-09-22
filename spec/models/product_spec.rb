RSpec.describe Product do
  subject(:product) { build(:product) }

  it 'has a valid factory' do
    expect(product).to be_valid
  end

  describe 'associations' do
    it { is_expected.to belong_to(:brand).optional }
    it { is_expected.to belong_to(:category).optional }
    it { is_expected.to have_many(:stock_items).dependent(:destroy) }
    it { is_expected.to have_many(:warehouses).through(:stock_items) }
    it { is_expected.to accept_nested_attributes_for(:stock_items).allow_destroy(true) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:manufacturer_name) }

    context 'when published' do
      subject(:product) { build(:product, :published) }

      it { is_expected.to validate_presence_of(:hp_url) }
      it { is_expected.to validate_presence_of(:name) }
    end

    context 'when not published' do
      subject(:product) { build(:product, site_status: :not_published) }

      it { is_expected.not_to validate_presence_of(:hp_url) }
      it { is_expected.not_to validate_presence_of(:name) }
    end

    context 'when it needs review' do
      subject(:product) { build(:product, site_status: :needs_review) }

      it { is_expected.not_to validate_presence_of(:hp_url) }
      it { is_expected.not_to validate_presence_of(:name) }
    end
  end

  describe 'enums' do
    it do
      is_expected.to define_enum_for(:language)
        .with_values(
          ukrainian: 'ukrainian',
          russian: 'russian',
          english: 'english',
          unknown: 'unknown',
          not_applicable: 'not applicable'
        )
        .backed_by_column_of_type(:string)
    end

    it do
      is_expected.to define_enum_for(:site_status)
        .with_values(
          published: 'published',
          not_published: 'not_published',
          needs_review: 'needs_review'
        )
        .backed_by_column_of_type(:string)
    end

    it do
      is_expected.to define_enum_for(:packaging_condition)
        .with_values(ok: 'ok', damaged: 'damaged')
        .backed_by_column_of_type(:string)
    end
  end
end
