#!/usr/bin/perl

use strict;
use warnings;
use Text::CSV;
use Data::Dumper;
use JSON;

=pod


=head2 USAGE

    ./extract_qld_rest_stop_csv.pl
  
=head2 CHANGE LOG

29th April 2017 - Created initial version  

=head2 DEPENDENCIES

* Perl CPAN Modules 
* NB Assumes that the user has downloaded and extracted zip file from https://data.qld.gov.au/dataset/roadside-amenities-queensland before running ( not stored in repo )

=head2 ASSUMPTIONS


=head2 OUTPUT

Currently dumps perl structure of content followed by a GeoJSON string

=head2 AUTHOR

  peter@pscott.com.au

=cut 

die('obtain and extract the data zip file from https://data.qld.gov.au/dataset/roadside-amenities-queensland') unless -e './DP_QLD_ROADSIDE_AMENITIES/RoadsideAmenities.csv';


## LOAD EACH CSV LINE INTO A ROW IN THE @rows array
my @rows;
my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
             or die "Cannot use CSV: ".Text::CSV->error_diag ();
open my $fh, "<:encoding(utf8)", "./DP_QLD_ROADSIDE_AMENITIES/RoadsideAmenities.csv" or die "./DP_QLD_ROADSIDE_AMENITIES/RoadsideAmenities.csv: $!";
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
      push @$datum, $record if ( $record->{STATUS} eq 'O' ); ## filter out 'C'losed and only retain 'O'pen status records
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
            "title" => $site->{NAME},
            "description" => $site->{LOCATION},
            "facilities" => {
                ## TODO: 
            }
        }
      };

    }
    return $geo_json;
}


=pod

Attribute Descriptions taken from "RoadsideAmenities meta Dec2015.docx"

CONTROL and/or MAINTCE authorities
TMR     Transport and Main Roads
L       Local Government
W       SunWater
PSR     Dept of National Parks, Sport and Racing
S       Service Clubs
O       Other
U       Unknown

TYPE
RA      Motorist Rest Area
SS      Scenic Stop
DR      Driver Reviver
RA DR   Motorist Rest Area and Driver Reviver
RA HV   Motorist Rest Area and Heavy Vehicle Rest Area (shared use)
HV      Heavy Vehicle Rest Area
HVSP        Heavy Vehicle Stopping Place
SC      Service Centre
UN      Unknown

Facilities
WCLOSET     Water Closet
ECLOSET     Earth Closet
Enviro_toilet   Environmental toilet (composting or similar)
Disabled_Toilet Disabled toilet
HRToiletID      ID number for National toilet database
WSUPPLY     Water supply
FIREPLACE       Fireplace
TABLE_      Picnic table
SSHED       Shelter shed
BBQ         Gas or electric BBQ
PLAY            Playground
SHOWER      Shower facilities
BOAT            Boat ramp
BUSHWALK        Bush walking tracks
LOOKOUT     Lookout at facility
NO_DOG      No dogs allowed
CAMPING     Overnight camping allowed (or time limit hours)

Other attributes
REMARKS     Any other comments about facility
REG         Date entered on database (where known)
DEREG       Date decommissioned (where known)
STATUS      “O” = open  “C” = closed ** 
LOCATION        Joined attributes DISTFROM and TOWN (for Guide publication)
NUM_CON     Joined attributes NUMBER_ and CONTROL (for Amenity O’lay labels)
GUIDE       Specific attribute select (for Guide publication)
Guide_Maps  Whether symbols should appear in Map 1 of the Guide publication
Signed      Lead up signs (Y(es) N(o) or blank if unknown)
Access_Dir      Either Both (ways), Left, Right in gazettal direction or Null


**(very important to filter for STATUS = “O”) when plotting data to ensure closed facilities are not plotted.


=cut 
