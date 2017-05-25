# rest-stops

This data set was initially explored as part of a bid to participate in the Queensland TWIG program. Although our bid was unsuccessful, we intend to continue to refine this data set.

In order to combine the sources of rest-stop data published by state authorities we first need a common structure. 

````


$rest_stops = [
  {
    lat
    lng
    name
    address
    description
    area_poly 
    responsible_authority => '',
    features => {
      light_vehcile => 0,
      heavy_vehicle => 0,
      load_checking => 
     'Shelter' => 0,
     'Wheelchair Accessible' => 0,
     'Playground' => 0,
     'Emergency Phone' => 0,
     'Litter Bins' => 0,
     'Toilets' => 0,
     'BBQ Facilities' => 0,
     'Picnic Tables' => 0
    }
    access_from_north
    access_from_south
    access_
  }
];


````