#!/usr/bin/perl

use strict;
use warnings;
use JSON;
use File::Slurp;
use Data::Dumper;
=pod 

=head1 extract_sa_reststop_geojson_data.pl

This is a quick first attempt to extract the rest-area lat/lng to use in experimentation.

  - SA Rest area data set review
    https://data.sa.gov.au/data/dataset/rest-areas
    http://www.dptiapps.com.au/dataportal/RestAreas_geojson.zip unzipped contains RestAreas.geojson which can be extracted with

extracts the location details from geoojson source file and 

nb - source DATE_DECOMISSIONED not checked

=cut 

my $source = '/Users/peter/Downloads/RestAreas_geojson/RestAreas.geojson';
my $text = read_file( $source ) ;
if ( my $data = from_json( $text ) )
{
    #print Dumper $data;
    my $sites_data = extract_points( $data );
    print Dumper $sites_data ;
    print to_json( $sites_data );
}


sub extract_points
{
    my ( $gj ) = @_;
    my $res = [];
    my $id=1;
    foreach my $f ( @{ $gj->{features}} ) 
    {
        my $c = $f->{geometry}{coordinates};
        # print Dumper $c;
        print qq{ $c->[0], $c->[1]\n };
        push @$res , render_point_as_site( $c->[1], $c->[0], $id );
        $id++;
    }
    return $res;
}

=pod

=head2 render_point_as_site()

This is jsut a quick check - rendering the lat/lng of each site in a format that may typically be consumed with the initial
mobile map rendering service.


=cut
sub render_point_as_site
{
    my ( $lat, $lng, $id, $site_id ) = @_;
    $id = 0 unless defined $id;
    $site_id = "454dfgda-2ce1-486f-0983-7b81fa33$id" unless defined $site_id;
    return {
            'id' => $id,
            'data' => {
                        'features' => [
                                        "Highway Rest Area"
                                      ],
                        'gps' => {
                                   'latitude' => $lat,
                                   'longitude' => $lng
                                 },
                        'phoneNumber' => '',
                        'siteId' => $site_id ,
                        'type' => 'Highway Rest Area',
                        'creatorUserId' => '454df0da-bcf1-186f-4923-7b61fa3348e9',
                        'description' => 'SA Open Data .',
                        'website' => 'https://data.sa.gov.au/data/dataset/rest-areas',
                        'name' => 'SA Official Rest Stop',
                        'address' => ''
                }
    };
}
