# rest-stops

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
    responsible_authority
    features => {
      light_vehcile => 0,
      heavy_vehicle => 0,
      load_checking => 
      Toilets 
      Shelter
      Picnic Tables 
      BBQ Facilities
      Litter Bins
      Wheelchair Accessible
      Playground
      Emergency Phone


    }
    access_from_north
    access_from_south
    access_
  }
];


````