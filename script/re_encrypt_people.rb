re_encrypted_people = 0

total_people_count = Person.where({
  "$or" => [{:encrypted_ssn => {"$ne" => nil}}, {"versions.encrypted_ssn" => {"$ne" => nil}}]
}).count
Person.where({
  "$or" => [{:encrypted_ssn => {"$ne" => nil}}, {"versions.encrypted_ssn" => {"$ne" => nil}}]
}).each do |pers|
  encrypted_ssn = pers.encrypted_ssn
  begin
    if !pers.encrypted_ssn.blank?
      ssn_value = SymmetricEncryption.secondary_ciphers.first.decrypt(encrypted_ssn) rescue nil
      if !ssn_value.blank? && (ssn_value =~ /[0-9]{9}/)
        pers.ssn = ssn_value
      end
    end
    pers.versions.each do |ver|
      if !ver.encrypted_ssn.blank?
        dec_ver_ssn = SymmetricEncryption.secondary_ciphers.first.decrypt(ver.encrypted_ssn) rescue nil
        if !dec_ver_ssn.blank? && (dec_ver_ssn =~ /[0-9]{9}/)
          ver.encrypted_ssn = SymmetricEncryption.encrypt(dec_ver_ssn)
        end
      end
    end
    pers.save!
    re_encrypted_people = re_encrypted_people + 1
  rescue OpenSSL::Cipher::CipherError
    puts pers.id
    re_encrypted_people = re_encrypted_people + 1
  rescue => e
    puts e.inspect
    puts SymmetricEncryption.secondary_ciphers.first.decrypt(encrypted_ssn)
    puts SymmetricEncryption.decrypt(encrypted_ssn)
    puts pers.id
  end
  if (re_encrypted_people % 1000) == 0
    puts "#{re_encrypted_people}/#{total_people_count}"
  end
end
