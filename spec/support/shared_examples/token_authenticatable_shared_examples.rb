# frozen_string_literal: true

RSpec.shared_examples 'token has a valid checksum' do
  it 'includes a correct checksum at the end of the token' do
    token_with_checksum = token
    token_without_checksum = token_with_checksum[0..-9]
    checksum_from_token = token_with_checksum[-8..]
    expect(Zlib.adler32(token_without_checksum).to_s(16).rjust(8, '0')).to eq(checksum_from_token)
  end
end
