re_encrypted_people = 0

total_people_count = CuramUser.where(:encrypted_ssn => {"$ne" => nil}).count
CuramUser.where(:encrypted_ssn => {"$ne" => nil}).each do |pers|
  encrypted_ssn = pers.encrypted_ssn
  begin
    ssn_value = SymmetricEncryption.secondary_ciphers.first.decrypt(encrypted_ssn) rescue nil
    if !ssn_value.blank? && (ssn_value =~ /[0-9]{9}/)
      pers.ssn = ssn_value
      pers.save!
    end
    re_encrypted_people = re_encrypted_people + 1
  rescue
    puts SymmetricEncryption.secondary_ciphers.first.decrypt(encrypted_ssn)
    puts SymmetricEncryption.decrypt(encrypted_ssn)
    puts pers.id
  end
  if (re_encrypted_people % 1000) == 0
    puts "#{re_encrypted_people}/#{total_people_count}"
  end
end
