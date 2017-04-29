#!/usr/bin/perl

=pod 

  get_and_extract_nsw_rest_stop_excel_data.pl


=head2 USAGE

    ./get_and_extract_nsw_rest_stop_excel_data.pl 
  
=head2 CHANGE LOG

29th April 2017 - Created initial version  

=head2 DEPENDENCIES

* Perl CPAN Modules - LWP, Spreadsheet::ParseExcel


=head2 ASSUMPTIONS

* Current NSW Rest Stop Data is available from URL http://www.rms.nsw.gov.au/documents/roads/using-roads/nsw-restareas.xls
* Excel describes version in the cell B4 which contains the last updated date in dd/mm/yyyy format
* Column headers in row 6 of the spreadsheet are consistent ( Rest Area Type    Name    Description Location    Accessible From Coordinates Responsible Authority   Facilities
 )
* if excel file does not exist in the current directory it is retrieved


=head2 OUTPUT

Currently dumps perl structure of content followed by a GeoJSON string

=head2 AUTHOR

  peter@pscott.com.au

=cut 

use strict;
use LWP;
use Spreadsheet::ParseExcel;
use Data::Dumper;
use JSON;

my $EXCEL_SOURCE_URL = 'http://www.rms.nsw.gov.au/documents/roads/using-roads/nsw-restareas.xls';

my @COLUMN_HEADERS = qw/Rest_Area_Type Name Description Location Accessible_From Coordinates Responsible_Authority Facilities/;
## GET EXCEL FROM SOURCE IF DOESN'T EXIST IN CURRENT DIRECTOry
`wget $EXCEL_SOURCE_URL` unless -e './nsw-restareas.xls';

my $parser = new Spreadsheet::ParseExcel;
my $workbook = $parser->parse('nsw-restareas.xls');
my $worksheet = $workbook->worksheet(0);


## GET LAST UPDATE
my $cell = $worksheet->get_cell( 3,1 );
print "Last Updated (expect '2015-08-06')       = ", $cell->value(),       "\n";
warn("Untested against this update " . $cell->value() ) unless $cell->value() eq '2015-08-06';

## TODO: consider check that row 5 contains the COLUMN HEADERS ( NB _ used to replace spaces)

my $row = 6; my $record_count = 0; my $finished = 0;
my $stats => { facility_counts => {}, };

my $datum = [];
while ( $finished == 0 )
{
    my $col = 0;
    my $val = $worksheet->get_cell( $row, $col );
    if ( not defined($val) )
    {
        $finished=1;
    }
    else 
    {
        print "$row> $val\n";
        my $raw_record = {
            Rest_Area_Type  => $worksheet->get_cell( $row, 0 )->value(),
            Name            => $worksheet->get_cell( $row, 1 )->value(),
            Description     => $worksheet->get_cell( $row, 2 )->value(),
            Location        => $worksheet->get_cell( $row, 3 )->value(),
            Accessible_From => $worksheet->get_cell( $row, 4 )->value(),
            Coordinates     => $worksheet->get_cell( $row, 5 )->value(),
            Responsible_Authority => $worksheet->get_cell( $row, 6 )->value(),
            Facilities      => $worksheet->get_cell( $row, 7 )->value(),
        };
        print Dumper $raw_record;
        push @$datum, validate_raw_record( $raw_record );

    }

    $record_count++; $row++;
    $finished=1 if ( $record_count > 10000 );
}
print Dumper $datum;
print Dumper $stats;
print to_json( datum_as_geojson( $datum ) );
sub validate_raw_record
{
    my ( $rec ) = @_;
    ## split out lat/lng
    if ( $rec->{Coordinates} =~ /^([\-|\.|\d]+), ([\-|\.|\d]+)$/smg ) 
    {
        $rec->{lat} = $1; $rec->{lng} = $2;
    }


    ## extract facilities
    my @facilities = split(/,/, $rec->{Facilities});
    foreach my $f ( @facilities ) {
        $f =~ s/^\s//smg; $f =~ s/\s$//smg; 
        if ( $f =~ /\w/m ) ## skip empty strings
        {
          $rec->{features}{$f} = '1';
          $stats->{facility_counts}{$f}++;
        } 
    }
    #print  join(  '--', @facilities)  . "\n";
    #exit;
    return $rec;
}


sub datum_as_geojson
{
    my ( $rs ) = @_;
    my $geo_json = {
    "type" => "FeatureCollection",
    "features" => []
    };
    foreach my $site ( @$rs )
    {
      #my $features = {};
      #foreach my $feature ( keys %$site->{features} )
      #{
      #  $features->{$feature} = 'yes';
      #}
        push @{$geo_json->{features}}, {
        "type" => "Feature",
        "geometry" => {
          "type" => "Point",
          "coordinates" => [ $site->{lng}+0,$site->{lat}+0 ]
        },
       "properties" => {
            "title" => $site->{Name},
            "description" => $site->{Description},
            "marker-symbol" => "star",
            "marker-size" => "medium",
            "marker-color" => "#f44",
            "facilities" => $site->{features}
        }
      };

    }
    return $geo_json;
}


exit;

## Following is copied straight from the POD for Spreadsheet::ParseExcel
=pod 
for my $worksheet ( $workbook->worksheets() ) {

            my ( $row_min, $row_max ) = $worksheet->row_range();
            my ( $col_min, $col_max ) = $worksheet->col_range();

            for my $row ( $row_min .. $row_max ) {
                for my $col ( $col_min .. $col_max ) {

                    my $cell = $worksheet->get_cell( $row, $col );
                    next unless $cell;

                    print "Row, Col    = ($row, $col)\n";
                    print "Value       = ", $cell->value(),       "\n";
                    print "Unformatted = ", $cell->unformatted(), "\n";
                    print "\n";
                }
            }
        }


=head3 Example GeoJSON

{
    "type": "FeatureCollection",
    "features": [
  {
    "type": "Feature",
    "geometry": {
      "type": "Point",
      "coordinates": [-77.031952, 38.913184]
    },
   "properties": {
    "has_bin": true
    }
  },
  {
    "type": "Feature",
    "geometry": {
      "type": "Point",
      "coordinates": [-77.011952, 38.513184]
    },
   "properties": {
    "has_bin": true,
    "title": "Virginia earthquake 2011 - mag. 5.8",
    "description": "No deaths, minor injuries. Damage to buildings reported.",
    "marker-symbol": "star",
    "marker-size": "medium",
    "marker-color": "#f44"
    }
  }
    ]
}


=cut 
