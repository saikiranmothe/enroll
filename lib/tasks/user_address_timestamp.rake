namespace :user_info do
  desc 'Print Home Address Timestamps For User'
  task print_home_address_timestamps: :environment do
  	residential_address = (person = Person.find('56a7905e50526c410e000091')).addresses
  																																							.detect { |address| address.kind == 'home' }
		if residential_address.id.to_s != '56a790be082e76038e000146'  																																							
			puts "User has created a new address residental address" 
		else
	  	puts "User: #{person.full_name}"
	  	puts "Residental Address CREATED ON: #{residential_address.created_at.strftime('%m/%d/%Y %H:%M:%S %Z')}"
	  	puts "Residental Address LAST UPDATED ON: #{residential_address.updated_at.strftime('%m/%d/%Y %H:%M:%S %Z')}"
	  end
  end
end
