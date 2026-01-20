/**
 * @name               : biometrySearchWrapper
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 06-12-2024
 * @modification date  : 06-12-2024
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Clase Wrapper para estructura de request y response de búsqueda de biometría
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   04-12-2024   Alvaro Gonzales Lapponi   Initial Version
**/
public class biometrySearchWrapper {

    /** SECCIÓN REQUEST **/
    public class ServiceRequest{
        public ImagePayload image_payload;
        public Boolean get_crops;
        public Boolean get_signature_payload;
        public Decimal min_confidence;
        public Integer max_matches;
        public List<String> watchlists;
    }
    
    public class ImagePayload{
        public string img;
        public Boolean detect;
        public Boolean use_detector_lms;
        public Boolean fail_on_multiple_faces;
    }
    
    /** SECCIÓN RESPONSE **/
    public class ServiceResponse{
        public Metadata metadata;
        public Data data;
    }
    
    public class Metadata{
        public String msg;
    }
    
    public class Data{
        public List<Match> matches;
    }
    
    public class Match{
        public String poi_id;
        public String display_name;
        public Decimal poi_confidence;
        public List<Watchlist> watchlists;
    }
    
    public class Watchlist{
        public String watchlist_type;
        public String display_name;
        public WatchlistNotes watchlist_notes;
    }
    
    public class WatchlistNotes{
        public List<Property> properties;
    }
    
    public class Property{
        
    }
    
}