#!/usr/bin/perl

use strict;
use warnings;
use Text::CSV;
use Data::Dumper;
use JSON;

=pod


=head2 USAGE

    ./extract_vic_rest_stop_csv.pl
  
=head2 CHANGE LOG

29th April 2017 - Created initial version  

=head2 DEPENDENCIES

* Perl CPAN Modules 
* NB Assumes that the user has downloaded and extracted zip file from https://www.vicroads.vic.gov.au/~/media/Media/Business%20and%20Industry/Rest%20Areas/restareadata before running ( not stored in repo )

=head2 ASSUMPTIONS


=head2 OUTPUT

Currently dumps perl structure of content followed by a GeoJSON string

=head2 AUTHOR

  peter@pscott.com.au

=cut 

die('obtain CSV from https://www.vicroads.vic.gov.au/~/media/Media/Business%20and%20Industry/Rest%20Areas/restareadata') unless -e './restareadata.csv';


## LOAD EACH CSV LINE INTO A ROW IN THE @rows array
my @rows;
my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
             or die "Cannot use CSV: ".Text::CSV->error_diag ();
open my $fh, "<:encoding(utf8)", "./restareadata.csv" or die "./restareadata.csv: $!";
my $headers = undef;
my $datum = []; 
while ( my $row = $csv->getline( $fh ) ) 
{
    my $record = {};
    if ( defined($headers ) )
    {
      my $i=0;
      foreach my $colname ( @$headers ) ## NB this is igly and could be done more elgantly with a map - in fact probably a File::Slurp that handles the headers directly
      {
        $record->{$colname} = $row->[$i];
        $i++;
      }
      push @$datum, $record ;
    }
    else
    {
      $headers = $row;  
    }
}
close $fh;
print Dumper $datum;

print to_json( datum_as_geojson($datum) );


sub datum_as_geojson
{
    my ( $rs ) = @_;
    my $geo_json = {
    "type" => "FeatureCollection",
    "features" => []
    };
    foreach my $site ( @$rs )
    {
        push @{$geo_json->{features}}, {
        "type" => "Feature",
        "geometry" => {
          "type" => "Point",
          "coordinates" => [ $site->{'Longitude'}+0,$site->{'Latitude'}+0 ]
        },
       "properties" => {
            "title" => $site->{'RestAreaName'},
            "description" => "$site->{'RestAreaType'} ",
            "facilities" => {
                ## TODO: 
                'Toilets' => $site->{'Toilets'},
                'BBQ'     => $site->{'BBQ'}
            }
        }
      };

    }
    return $geo_json;
}


=pod

          {
            'RestAreaID' => '4000602',
            'RubbishBins' => 'NO',
            'Latitude' => '-37.93383773',
            'RestAreaType' => 'TRUCK PARKING BAY',
            'NearestIntersection' => 'CENTRE ROAD',
            'Carriageway' => 'NORTHBOUND',
            'RoadName' => 'WESTALL ROAD',
            'SRNS' => '',
            'RestAreaName' => 'Westall Road North',
            'DelineatedParking' => 'YES',
            'Water' => 'NO',
            'DisabledToilets' => 'NO',
            'DistanceFromInt' => '200',
            'BBQ' => 'NO',
            'DirectionFromInt' => 'SOUTH',
            'PicnicTables' => 'NO',
            'Toilets' => 'NO',
            'Locality' => 'SPRINGVALE',
            'SurfaceType' => 'ASPHALT',
            'Longitude' => '145.1409693'
          }


=cut 
