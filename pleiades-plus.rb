#!/usr/bin/env ruby

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require 'csv'
require 'lib/icu4j-53_1.jar'

distance_threshold = 8.0

places_csv, names_csv, locations_csv, geonames_csv = ARGV

places = {}
pleiades_names = {}
geonames = {}
geonames_names = {}

def add_resource_name(resource_names_hash, name, id)
	unless name.nil?
		transliterated_name = Java::ComIbmIcuText::Transliterator.getInstance('Any-Latin; Lower; NFD; [:Nonspacing Mark:] Remove; [:Punctuation:] Remove; NFC').transliterate(name)

		if resource_names_hash[transliterated_name].nil?
			resource_names_hash[transliterated_name] = []
		end

		unless resource_names_hash[transliterated_name].include?(id)
			resource_names_hash[transliterated_name] << id
		end
	end
end

def bbox_to_coords(bbox)
	coords = bbox.split(',').map{|p| p.to_f}
end

def is_point?(bbox)
	coords = bbox_to_coords(bbox)
	if (coords[0] == coords[2]) && (coords[1] == coords[3])
		return true
	else
		return false
	end
end

def bbox_contains?(bbox, lat, long)
	# long lat long lat
	# bottom left top right long lat
	coords = bbox_to_coords(bbox)
	if ((lat <= coords[3]) && (lat >= coords[1]) && (long <= coords[2]) && (long >= coords[0]))
		return true
	else
		return false
	end
end

def log_match(pleiades, geonames, match_type, match_distance)
	data = []
	data << "http://pleiades.stoa.org/places/#{pleiades["id"]}"
	data << "http://sws.geonames.org/#{geonames["id"]}/"
	data << match_type
	data << match_distance.to_f.round(3).to_s
	data << pleiades["locationPrecision"]
	data << "\"#{pleiades["featureTypes"].strip}\""
	data << geonames["featurecode"]
	puts data.join(',')
end

def haversine_distance(lat1, lon1, lat2, lon2)
	km_conv = 6371 # km
	dLat = (lat2-lat1) * Math::PI / 180
	dLon = (lon2-lon1) * Math::PI / 180
	lat1 = lat1 * Math::PI / 180
	lat2 = lat2 * Math::PI / 180

	a = Math.sin(dLat/2) * Math.sin(dLat/2) + Math.sin(dLon/2) * Math.sin(dLon/2) * Math.cos(lat1) * Math.cos(lat2)
	c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
	d = km_conv * c
end

puts "pleiades_url,geonames_url,match_type,distance,pleiades_locationPrecision,pleiades_featureTypes,geonames_featurecode"

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

	[row["nameAttested"], row["nameTransliterated"]].each do |name|
		add_resource_name(pleiades_names, name, row["pid"])
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
geonames_csv_string = File.open(geonames_csv, "rb").read.force_encoding('UTF-8').encode('UTF-8', :invalid => :replace)
CSV.parse(geonames_csv_string, :headers => false, :col_sep => "\t", :quote_char => "\u{FFFF}") do |row|
	id = row[0]
	# exclude by featurecode for e.g. airports here, feel free to expand
	unless %w{RSTN AIRP AIRH AIRB AIRF ASTR BUSTN BUSTP MFG}.include?(row[7])
		geonames[id] = {}
		geonames[id]["id"] = id
		geonames[id]["name"] = row[1]
		geonames[id]["asciiname"] = row[2]
		geonames[id]["alternatenames"] = row[3].nil? ? [] : row[3].split(',')
		geonames[id]["latitude"] = row[4].to_f
		geonames[id]["longitude"] = row[5].to_f
		geonames[id]["featureclass"] = row[6]
		geonames[id]["featurecode"] = row[7]

		([geonames[id]["name"], geonames[id]["asciiname"]] + geonames[id]["alternatenames"]).each do |name|
			add_resource_name(geonames_names, name, id)
		end
	end
end

names = []

pleiades_names.each_key do |name|
	if (!name.nil?) && (!geonames_names[name].nil?) && (name.strip.length > 0)
		$stderr.puts name
		$stderr.puts "Pleiades:"
		pleiades_names[name].each do |pid|
			unless places[pid].nil?
				$stderr.puts "#{places[pid]["title"]}:\n\t#{places[pid]["description"]}\n\t#{places[pid]["bbox"]}"
				unless places[pid]["bbox"].nil?
					$stderr.puts is_point?(places[pid]["bbox"]) ? "\tpoint" : "\tbbox"
				end
			end
		end
		$stderr.puts "GeoNames:"
		geonames_names[name].each do |gid|
			$stderr.puts geonames[gid].inspect
		end

		pleiades_names[name].each do |pid|
			unless places[pid].nil?
				geonames_names[name].each do |gid|
					unless places[pid]["bbox"].nil?
						if is_point?(places[pid]["bbox"])
							coords = bbox_to_coords(places[pid]["bbox"])
							distance = haversine_distance(coords[1], coords[0], geonames[gid]["latitude"], geonames[gid]["longitude"])
							$stderr.puts "#{pid} <-> #{gid} distance: #{distance}"
							if distance < distance_threshold
								log_match(places[pid],geonames[gid],"distance",distance)
							end
						else # bbox
							if bbox_contains?(places[pid]["bbox"],geonames[gid]["latitude"], geonames[gid]["longitude"])
								$stderr.puts "#{pid} contains #{gid}"
								log_match(places[pid],geonames[gid],"bbox",0)
							else
								distance = haversine_distance(places[pid]["reprLat"].to_f, places[pid]["reprLong"].to_f, geonames[gid]["latitude"], geonames[gid]["longitude"])
								$stderr.puts "#{pid} does not contain #{gid}"
								$stderr.puts "#{pid} <-> #{gid} distance: #{distance}"
								if distance < distance_threshold
									log_match(places[pid],geonames[gid],"distance",distance)
								end
							end
						end
					end
				end
			end
		end

		$stderr.puts ""
	end
end

$stderr.puts places.length
$stderr.puts pleiades_names.length
$stderr.puts geonames.length
$stderr.puts geonames_names.length
