Pleiades Plus
=============

Pleiades Plus is an experimental machine alignment between Pleiades place resources and content in the Geonames Gazetteer. Conceived and prototyped by Leif Isaksen (University of Southampton/Pelagios Project), the current version is produced daily by Ryan Baumann (Duke Collaboratory for Classics Computing). Code and data are available from https://github.com/ryanfb/pleiades-plus. The CSV file produced by the code is also distributed via http://pleiades.stoa.org/downloads/.

Short explanation of algorithm
------------------------------

The algorithm for determining matches iterates through an array of names associated with Pleiades places, checking for exact string matches against names and alternate names in GeoNames. A given name match is included in the output if it meets one of the following criteria:

* if the Pleiades place resource is a point, and the GeoNames resource is within a distance threshold
* if the Pleiades place resource is a bounding box, and the GeoNames resource is inside that bounding box
* if the Pleiades place resource is a bounding box, and the GeoNames resource is not inside that bounding box but is within a distance threshold of its representative point (centroid of associated locations in Pleiades)
* if the Pleiades place resource is unlocated, and the GeoNames resource is contained by the bounding box of the Barrington Atlas capgrid associated with that place (http://atlantides.org/capgrids/)

Columns in the CSV
------------------

`pleiades_url`: HTTP URI (string)

URI for the Pleiades place resource that the code thinks corresponds to the GeoNames resource identified in "geonames_url"

`geonames_url`: HTTP URI (string)

URL for the Geonames place record that the code thinks corresponds to the Pleiades place resource identified in "pleiades_url"

`match_type`: string

* "distance": Haversine distance between the Pleiades point or bounding box and the Geonames point was less than 8.0km.
* "bbox": Geonames coordinates are contained by the Pleiades bounding box
* "capgrid": Geonames coordinates within the bounding box of the Barrington Atlas grid square for an unlocated Pleiades place
* "edh": Match manually recorded by the [Epigraphic Database Heidelberg](http://edh-www.adw.uni-heidelberg.de/home)

`distance`: float

Haversine distance in kilometers between the Geonames coordinates and the Pleiades coordinates or bounding box. If match_type="contains" this value will be 0.

`pleiades_locationPrecision`: string

Values copied from the Pleiades location precision field for this place resource: "precise" or "rough".

`pleiades_featureTypes`: string of comma-delimited strings

Values copied from the Pelaides feature type field for the place. Values drawn from the Pleiades "Feature (or Place) Categories" vocabulary: http://pleiades.stoa.org/vocabularies/place-types

`geonames_featurecode`: string

Value copied from the Geonames feature code. Values drawn from the Geonames Features Codes vocabulary: http://www.geonames.org/export/codes.html

Running
-------

    ./create_pleiades_plus

Outputs to `data/pleiades-plus.csv`.

Assumes default Ruby (via e.g. [rbenv](https://github.com/sstephenson/rbenv)) is JRuby in Ruby 1.9 mode (FasterCSV as `require 'csv'`) and [bundler](http://bundler.io/).

If [GNU parallel](http://www.gnu.org/software/parallel/) is installed, it will be used for parallel processing.
