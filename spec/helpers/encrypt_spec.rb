require 'spec_helper'

RSpec.describe Encrypt do
  let(:password) { 'foo' }
  let(:encrypted_password) { Encrypt.encrypt_password(password) }

  describe 'self.valid_password?' do
    it 'returns true when the passwords match' do
      expect(Encrypt.valid_password?(encrypted_password, password)).to be true
    end

    it 'returns false when the passwords do not match' do
      expect(Encrypt.valid_password?(encrypted_password, 'bar')).to be false
    end
  end

  describe 'self.encrypt_password' do
    it 'encrypts a password with BCrypt' do
      expect(BCrypt::Password).to receive(:create).with(password)
      Encrypt.encrypt_password(password)
    end
  end
end
