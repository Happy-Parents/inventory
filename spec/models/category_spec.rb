RSpec.describe Category do
  subject(:category) { build(:category) }

  it 'has a valid factory' do
    expect(category).to be_valid
  end

  describe 'associations' do
    it { is_expected.to belong_to(:parent).class_name('Category').optional }

    it do
      is_expected.to have_many(:subcategories)
        .class_name('Category')
        .with_foreign_key(:parent_id)
        .dependent(:nullify)
    end

    it { is_expected.to have_many(:products).dependent(:nullify) }
  end

  describe 'validations' do
    subject(:category) { create(:category) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end
end
