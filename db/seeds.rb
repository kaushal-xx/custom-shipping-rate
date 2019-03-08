# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
if WeberShippingRate.where(:min_qty => 1 && :max_qty => 5).empty?
	WeberShippingRate.create(:min_qty => 1, :max_qty => 5, :rate => 18.00)
end
if WeberShippingRate.where(:min_qty => 6 && :max_qty => 11).empty?
	WeberShippingRate.create(:min_qty => 6, :max_qty => 11, :rate => 24.00)
end
if WeberShippingRate.where(:min_qty => 12 && :max_qty => 23).empty?
	WeberShippingRate.create(:min_qty => 12, :max_qty => 23, :rate => 32.00)
end
if WeberShippingRate.where(:min_qty => 24 && :max_qty => 49).empty?
	WeberShippingRate.create(:min_qty => 24, :max_qty => 49, :rate => 42.00)
end
