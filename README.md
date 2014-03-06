pleiades-plus
=============

Script for generating a new Pleiades+ CSV file.

Run:

    ./create_pleiades_plus

Outputs to `data/pleiades-plus.csv`.

Assumes Ruby 1.9+ (FasterCSV as `require 'csv'`).

If [GNU parallel](http://www.gnu.org/software/parallel/) is installed, it will be used for parallel processing.