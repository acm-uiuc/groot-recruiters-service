require 'spec_helper'

RSpec.describe Encrypt do
  describe 'self.valid_password?' do
    let(:password) { "foo" }
    let(:encrypted_password) { Encrypt.encrypt_password(password) }

    it 'returns true when the passwords match' do
      expect(Encrypt.valid_password?(encrypted_password, password)).to be true
    end

    it 'returns false when the passwords do not match' do
      expect(Encrypt.valid_password?(encrypted_password, "bar")).to be false
    end
  end
end