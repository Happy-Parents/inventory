RSpec.describe AdminTablePreference do
  subject(:preference) { build(:admin_table_preference) }

  it 'has a valid factory' do
    expect(preference).to be_valid
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:resource_key) }

    context 'with a persisted preference' do
      subject(:preference) { create(:admin_table_preference) }

      it { is_expected.to validate_uniqueness_of(:resource_key).scoped_to(:admin_id).case_insensitive }
    end

    it 'rejects a non-array column list' do
      preference.visible_columns = { brand: true }

      expect(preference).not_to be_valid
    end
  end

  describe '.visible_column_keys' do
    let(:admin) { create(:admin) }

    it 'returns nil when the admin never saved anything' do
      expect(described_class.visible_column_keys(admin, 'products')).to be_nil
    end

    it 'returns nil without an admin' do
      expect(described_class.visible_column_keys(nil, 'products')).to be_nil
    end

    it 'returns the stored keys as symbols' do
      create(:admin_table_preference, admin: admin, resource_key: 'products', visible_columns: %w[sku name])

      expect(described_class.visible_column_keys(admin, 'products')).to eq(%i[sku name])
    end

    it 'ignores preferences of other admins and other tables' do
      create(:admin_table_preference, admin: admin, resource_key: 'brands', visible_columns: %w[name])
      create(:admin_table_preference, resource_key: 'products', visible_columns: %w[sku])

      expect(described_class.visible_column_keys(admin, 'products')).to be_nil
    end
  end

  describe '.store' do
    let(:admin) { create(:admin) }

    it 'creates the preference' do
      expect { described_class.store(admin: admin, resource_key: 'products', keys: %i[sku name]) }
        .to change(described_class, :count).by(1)

      expect(described_class.visible_column_keys(admin, 'products')).to eq(%i[sku name])
    end

    it 'updates the existing preference instead of adding another one' do
      described_class.store(admin: admin, resource_key: 'products', keys: %i[sku])

      expect { described_class.store(admin: admin, resource_key: 'products', keys: %i[name]) }
        .not_to change(described_class, :count)

      expect(described_class.visible_column_keys(admin, 'products')).to eq(%i[name])
    end
  end
end
