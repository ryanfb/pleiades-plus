#!/usr/bin/env ruby

require 'csv'

places_csv, names_csv, locations_csv, geonames_csv = ARGV

places = {}
geonames = {}
geonames_names = {}

def add_geonames_name(geonames_names, name, id)
	if geonames_names[name].nil?
		geonames_names[name] = []
	end

	unless geonames_names[name].include?(id)
		geonames_names[name] << id
	end
end

$stderr.puts "Parsing Pleiades places..."
CSV.foreach(places_csv, :headers => true) do |row|
	places[row["id"]] = row.to_hash
end

$stderr.puts "Parsing Pleiades names..."
CSV.foreach(names_csv, :headers => true) do |row|
	unless places[row["pid"]].nil?
		places[row["pid"]]["names"] ||= []
		places[row["pid"]]["names"] << row.to_hash
	end
end

$stderr.puts "Parsing Pleiades locations..."
CSV.foreach(locations_csv, :headers => true) do |row|
	unless places[row["pid"]].nil?
		places[row["pid"]]["locations"] ||= []
		places[row["pid"]]["locations"] << row.to_hash
	end
end

$stderr.puts "Parsing GeoNames..."
CSV.foreach(geonames_csv, :headers => false, :col_sep => "\t", :quote_char => "\u{FFFF}") do |row|
	id = row[0]
	geonames[id] = {}
	geonames[id]["name"] = row[1]
	geonames[id]["asciiname"] = row[2]
	geonames[id]["alternatenames"] = row[3].nil? ? [] : row[3].split(',')
	geonames[id]["latitude"] = row[4]
	geonames[id]["longitude"] = row[5]
	geonames[id]["featureclass"] = row[6]
	geonames[id]["featurecode"] = row[7]

	([geonames[id]["name"], geonames[id]["asciiname"]] + geonames[id]["alternatenames"]).each do |name|
		add_geonames_name(geonames_names, name, id)
	end
end

names = []
# places.each_key do |id|
	# File.open("geojson/#{id}.geojson","w") do |f|
	# 	f.write(JSON.pretty_generate(place_to_geojson(places[id])))
	# end

	# unless places[id]["names"].nil?
	# 	places[id]["names"].map{|n| n["title"]}.uniq.each do |name|
	# 		names << [name, id]
	# 	end
	# end
# end

puts places.length
puts geonames.length
puts geonames_names.length
